// ignore_for_file: prefer_const_constructors, directives_ordering
import 'dart:io';

import 'package:analyzer/file_system/file_system.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:publish_docs/src/util/analyzer_util.dart';

import 'test_util.dart';

void main() {
  group('overlay', () {
    late ResourceProvider provider;
    late String testResourcePath;

    setUp(() {
      testResourcePath = resourcePath('overlay');
    });
    test('can retrieve physical files', () {
      provider = obtainAssetsOverlayProvider();

      final test1Path = path.absolute(testResourcePath, 'test1');
      final testFolder = provider.getFolder(test1Path);
      // Make sure that our preparation is all right.
      expect(testFolder.exists, isTrue);
    });
    test('can find basic file', () {
      final test1Path = path.absolute(testResourcePath, 'test1');
      final parentPath = path.absolute(test1Path, 'parent');

      provider = obtainAssetsOverlayProvider(pathForLayers: parentPath);

      // ...now look for 'child.txt' and 'not-here.txt'
      final parentFolder = provider.getFolder(parentPath);
      final childResource = parentFolder.getChild('child.txt');
      final notHereResource = parentFolder.getChild('not-here.txt');
      expect(childResource.exists, isTrue);
      expect(notHereResource.exists, isFalse);
    });
    test('can find basic file via path alias', () {
      final test1Path = path.absolute(testResourcePath, 'test1');
      final parentPath = path.absolute(test1Path, 'parent');
      final fakeParentPath = path.absolute(test1Path, 'not-present-on-disk');

      expect(Directory(fakeParentPath).existsSync(), isFalse);

      provider = obtainAssetsOverlayProvider(
        pathForLayers: fakeParentPath,
        layers: [
          parentPath
        ],
      );

      final parentFolder = provider.getFolder(fakeParentPath);
      final childResource = parentFolder.getChild('child.txt');
      final notHereResource = parentFolder.getChild('not-here.txt');
      expect(childResource.exists, isTrue);
      expect(notHereResource.exists, isFalse);
    });
    test('can find overlay file', () {
      final test2Path = path.absolute(testResourcePath, 'test2');

      final parentPath = path.absolute(test2Path, 'parent');

      // TODO(Cliabhach): Create a provider with built-in directory overlays

      final childResource = relative(provider, parentPath, 'child.txt');
      final notHereResource = relative(provider, parentPath, 'not-here.txt');
      final sampleResource = relative(provider, parentPath, 'sampleB');

      expect(childResource.exists, isTrue);
      expect(notHereResource.exists, isFalse);
      expect(sampleResource.exists, isTrue);
    });
  });
}
