// ignore_for_file: prefer_const_constructors, directives_ordering
import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart' as fs;
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:mocktail/mocktail.dart';
import 'package:publish_docs/src/private/mime_type.dart';
import 'package:test/test.dart';

import 'test_util.dart';

class MockFile extends Mock implements fs.File {
}

void main() {
  group('mime_type', () {
    late io.Directory testResourceDirectory;

    setUp(() {
      testResourceDirectory = io.Directory(resourcePath('mime_type'));
    });

    test('checks may understand LICENSE files', () async {
      // Given
      final testFile = PhysicalResourceProvider.INSTANCE.getFile(
        append(testResourceDirectory, 'test1', 'LICENSE').path
      );

      // When
      final libraryType = await checkWithLibrary(testFile);
      final hostType = checkWithHost(testFile);

      // Then
      expect(libraryType, isNull, reason: 'The mime library cannot identify '
          'files without extensions as text/plain, application/octet-stream, '
          'or any other valid format.');

      expect(hostType, isNotNull);
      expect(hostType, matches(RegExp('text/plain')));
    });

    test('checks may understand binary files', () async {
      // Given
      final testFile = PhysicalResourceProvider.INSTANCE.getFile(
        append(testResourceDirectory, 'test2', 'favicon.png').path
      );

      // When
      final libraryType = await checkWithLibrary(testFile);
      final hostType = checkWithHost(testFile);

      // Then
      expect(libraryType, 'image/png');
      expect(hostType, isNotNull);
      expect(hostType!.trim(), 'image/png');
    });

    late fs.File file;
    setUp(() {
      file = MockFile();
    });

    test('DocsMimeType understands binary files', () async {
      // Given
      const imageType = 'image/jpeg';
      const binaryType = 'application/octet-stream';
      final testImageFile = PhysicalResourceProvider.INSTANCE.getFile(
        append(testResourceDirectory, 'test3', 'favicon.png').path
      );
      final testTextFile = PhysicalResourceProvider.INSTANCE.getFile(
        append(testResourceDirectory, 'test3', 'test_file.txt').path
      );

      // When
      when(() => file.path).thenReturn(testImageFile.path);
      final imageModel = DocsMimeType(imageType);
      final imageString = imageModel.readAsStringSync(file);

      when(() => file.path).thenReturn(testTextFile.path);
      final binaryModel = DocsMimeType(binaryType);
      final binaryString = imageModel.readAsStringSync(file);

      // Then
      expect(imageModel.type, imageType);
      expect(binaryModel.type, binaryType);

      expect(imageString, isNotEmpty);
      expect(binaryString, isNotEmpty);
    });
  });
}
