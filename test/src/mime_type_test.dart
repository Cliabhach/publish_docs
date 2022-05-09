// ignore_for_file: prefer_const_constructors, directives_ordering
import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:publish_docs/src/private/mime_type.dart';
import 'package:test/test.dart';



import 'test_util.dart';

void main() {
  group('mime_type', () {
    late Directory testResourceDirectory;

    setUp(() {
      testResourceDirectory = Directory(resourcePath('mime_type'));
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

    test('host check does understand LICENSE files', () async {
      // Given
      final testFile = PhysicalResourceProvider.INSTANCE.getFile(
        append(testResourceDirectory, 'test1', 'LICENSE').path
      );

      // When

      // Then
    });
  });
}
