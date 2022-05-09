// ignore_for_file: prefer_const_constructors, directives_ordering
import 'dart:io';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as path;
import 'package:publish_docs/src/private/mime_type.dart';
import 'package:test/test.dart';

import 'package:mocktail/mocktail.dart';

import 'package:publish_docs/src/util/analyzer_util.dart';

import 'test_util.dart';

void main() {
  group('mime_type', () {
    late Directory testResourceDirectory;

    setUp(() {
      testResourceDirectory = Directory(resourcePath('mime_type'));
    });

    test('library check does not understand LICENSE files', () async {
      // Given
      final testFile = PhysicalResourceProvider.INSTANCE.getFile(
        append(testResourceDirectory, 'test1', 'LICENSE').path
      );

      // When
      final type = await checkWithLibrary(testFile);

      // Then
      expect(type, isNull, reason: 'The mime library cannot identify files '
          'without extensions as text/plain, application/octet-stream, or any '
          'other valid format.');
    });

    test('host check does understand LICENSE files', () async {
      // Given
      final testFile = PhysicalResourceProvider.INSTANCE.getFile(
        append(testResourceDirectory, 'test1', 'LICENSE').path
      );

      // When
      final type = checkWithHost(testFile);

      // Then
      expect(type, isNotNull);
      expect(type, matches(RegExp('text/plain')));
    });
  });
}
