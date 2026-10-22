import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_closet/core/utils/file_utils.dart';

void main() {
  group('deleteFileQuietly', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('delete_quietly_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) await tempDir.delete(recursive: true);
    });

    test('deletes an existing file', () async {
      final file = File('${tempDir.path}/photo.png');
      await file.writeAsString('data');
      expect(await file.exists(), isTrue);

      await deleteFileQuietly(file);

      expect(await file.exists(), isFalse);
    });

    test('does not throw for a file that does not exist', () async {
      final file = File('${tempDir.path}/missing.png');
      expect(await file.exists(), isFalse);

      await expectLater(deleteFileQuietly(file), completes);
    });

    test('does not throw when the parent directory does not exist', () async {
      final file = File('${tempDir.path}/nested/missing.png');

      await expectLater(deleteFileQuietly(file), completes);
    });
  });
}
