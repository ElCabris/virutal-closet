import 'dart:io';
import 'package:flutter/services.dart';

/// Drives the native ModelInstallPlugin (Android) to force-download the ML
/// Kit Subject Segmentation model via Play Services' ModuleInstallClient.
/// See background_removal_service.dart for why this is needed: the
/// manifest's `com.google.mlkit.vision.DEPENDENCIES` trigger only fires on
/// Play Store installs, so sideloaded/dev builds never auto-download the
/// model and the first segmentation call throws instead of working.
class ModelInstallService {
  static const _methodChannel = MethodChannel('com.virtualcloset/model_install');
  static const _progressChannel =
      EventChannel('com.virtualcloset/model_install/progress');

  bool get isSupported => Platform.isAndroid;

  /// 0-100 download progress, jumping straight to 100 if the model was
  /// already installed.
  Stream<int> get downloadProgress =>
      _progressChannel.receiveBroadcastStream().map((e) => e as int);

  /// Resolves once the model is confirmed available, or false if the
  /// install request failed (e.g. no network, Play Services unavailable).
  Future<bool> ensureSubjectSegmentationModel() async {
    if (!isSupported) return false;
    try {
      final result = await _methodChannel
          .invokeMethod<bool>('ensureSubjectSegmentationModel');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
