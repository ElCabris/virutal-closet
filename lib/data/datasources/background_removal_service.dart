import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import '../../core/utils/bounded_concurrency.dart';
import '../../core/utils/file_utils.dart';

/// Removes the background from garment photos using ML Kit's on-device
/// Subject Segmentation. Android only — the Flutter plugin's iOS side has
/// no real native implementation behind it yet (its podspec ships with the
/// actual ML Kit dependency commented out), so [isSupported] must be
/// checked before calling [removeBackground] or [removeBackgroundBatch].
class BackgroundRemovalService {
  bool get isSupported => Platform.isAndroid;

  /// Each in-flight segmentation holds a decoded input bitmap, a confidence
  /// mask buffer and the output bitmap in native memory simultaneously —
  /// roughly 15-20MB for a 1200x1200 photo (the max size the picker
  /// produces). 3 concurrent operations caps that around 45-60MB, which
  /// leaves headroom under even a conservative ~192MB heap budget once the
  /// rest of the app (Flutter engine, Supabase client, cached images) is
  /// accounted for, while still getting real parallelism instead of
  /// serializing to one image at a time.
  static const int _maxConcurrentSegmentations = 3;

  /// Processes [images] with the concurrency bounded by
  /// [_maxConcurrentSegmentations] instead of starting all of them via a
  /// single `Future.wait`, which would let the user's photo count alone
  /// dictate peak memory use — risky when someone selects a large batch
  /// from the gallery. Order is preserved; a failed or skipped image keeps
  /// its original file exactly as [removeBackground] already guarantees.
  Future<List<File>> removeBackgroundBatch(List<File> images) {
    return mapWithConcurrency(
      images,
      removeBackground,
      maxConcurrent: _maxConcurrentSegmentations,
    );
  }

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
      final processed = File(outPath)..writeAsBytesSync(bitmap);

      // `image` is now redundant — its content lives on, transformed, in
      // `processed`, which is what the rest of the app uses from here on.
      // Deleting it only after the write succeeds means a failed write
      // never loses the only copy of the photo.
      await deleteFileQuietly(image);

      return processed;
    } catch (_) {
      return image;
    } finally {
      await segmenter.close();
    }
  }
}
