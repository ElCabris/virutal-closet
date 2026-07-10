import 'dart:io';

/// Deletes [file] if it exists, swallowing any error. Used for best-effort
/// cleanup of local temp files where a failed delete should never surface
/// as a user-facing error or abort a larger operation — worst case, one
/// extra file lingers until the OS reclaims the cache directory.
Future<void> deleteFileQuietly(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } catch (_) {
    // Best-effort only.
  }
}
