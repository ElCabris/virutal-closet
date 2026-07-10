import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';

/// Removes the background from garment photos using ML Kit's on-device
/// Subject Segmentation. Android only — the Flutter plugin's iOS side has
/// no real native implementation behind it yet (its podspec ships with the
/// actual ML Kit dependency commented out), so [isSupported] must be
/// checked before calling [removeBackground].
class BackgroundRemovalService {
  bool get isSupported => Platform.isAndroid;

  /// Returns a new PNG file with the background removed, or [image]
  /// unchanged if segmentation fails or finds no subject to isolate. Never
  /// throws — background removal is a best-effort enhancement, not a
  /// requirement for adding a garment.
  Future<File> removeBackground(File image) async {
    if (!isSupported) return image;

    final segmenter = SubjectSegmenter(
      options: SubjectSegmenterOptions(
        enableForegroundBitmap: true,
        enableForegroundConfidenceMask: false,
        enableMultipleSubjects: SubjectResultOptions(
          enableConfidenceMask: false,
          enableSubjectBitmap: false,
        ),
      ),
    );

    try {
      final result =
          await segmenter.processImage(InputImage.fromFilePath(image.path));
      final bitmap = result.foregroundBitmap;
      if (bitmap == null || bitmap.isEmpty) return image;

      final dir = await getTemporaryDirectory();
      final outPath = p.join(
        dir.path,
        '${p.basenameWithoutExtension(image.path)}_nobg.png',
      );
      return File(outPath)..writeAsBytesSync(bitmap);
    } catch (_) {
      return image;
    } finally {
      await segmenter.close();
    }
  }
}
