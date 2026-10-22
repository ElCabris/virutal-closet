package com.example.virtual_closet

import android.content.Context
import android.util.Log
import com.google.android.gms.common.moduleinstall.InstallStatusListener
import com.google.android.gms.common.moduleinstall.ModuleInstall
import com.google.android.gms.common.moduleinstall.ModuleInstallRequest
import com.google.android.gms.common.moduleinstall.ModuleInstallStatusUpdate
import com.google.mlkit.vision.segmentation.subject.SubjectSegmentation
import com.google.mlkit.vision.segmentation.subject.SubjectSegmenterOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/// Forces the on-device Subject Segmentation model to download via
/// Play Services' ModuleInstallClient, instead of relying on the
/// `com.google.mlkit.vision.DEPENDENCIES` manifest trigger, which only
/// fires on Play Store installs — never for sideloaded/dev builds. Without
/// this, the first call to SubjectSegmenter.processImage() on a device that
/// never downloaded the model throws a NullPointerException deep in the
/// obfuscated Play Services client instead of a clear "not ready" signal.
class ModelInstallPlugin : FlutterPlugin {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var progressSink: EventChannel.EventSink? = null
    private lateinit var appContext: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, "com.virtualcloset/model_install")
        methodChannel.setMethodCallHandler { call, result ->
            if (call.method == "ensureSubjectSegmentationModel") {
                ensureModel(result)
            } else {
                result.notImplemented()
            }
        }

        eventChannel = EventChannel(binding.binaryMessenger, "com.virtualcloset/model_install/progress")
        eventChannel.setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    progressSink = events
                }

                override fun onCancel(arguments: Any?) {
                    progressSink = null
                }
            },
        )
    }

    private fun ensureModel(result: MethodChannel.Result) {
        val segmenterClient =
            SubjectSegmentation.getClient(
                SubjectSegmenterOptions.Builder().enableForegroundBitmap().build(),
            )
        val moduleInstallClient = ModuleInstall.getClient(appContext)

        moduleInstallClient
            .areModulesAvailable(segmenterClient)
            .addOnSuccessListener { response ->
                Log.i(TAG, "areModulesAvailable = ${response.areModulesAvailable()}")
                if (response.areModulesAvailable()) {
                    progressSink?.success(100)
                    result.success(true)
                    segmenterClient.close()
                    return@addOnSuccessListener
                }

                val request =
                    ModuleInstallRequest.newBuilder()
                        .addApi(segmenterClient)
                        .setListener(
                            InstallStatusListener { update: ModuleInstallStatusUpdate ->
                                val progress = update.progressInfo
                                if (progress != null && progress.totalBytesToDownload > 0) {
                                    val pct =
                                        (progress.bytesDownloaded * 100 / progress.totalBytesToDownload).toInt()
                                    progressSink?.success(pct)
                                }
                            },
                        )
                        .build()

                moduleInstallClient
                    .installModules(request)
                    .addOnSuccessListener {
                        Log.i(TAG, "installModules succeeded")
                        progressSink?.success(100)
                        result.success(true)
                        segmenterClient.close()
                    }
                    .addOnFailureListener { e ->
                        Log.e(TAG, "installModules failed", e)
                        result.error("MODEL_INSTALL_FAILED", e.message, null)
                        segmenterClient.close()
                    }
            }
            .addOnFailureListener { e ->
                Log.e(TAG, "areModulesAvailable failed", e)
                result.error("MODEL_CHECK_FAILED", e.message, null)
                segmenterClient.close()
            }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    companion object {
        private const val TAG = "ModelInstallPlugin"
    }
}
