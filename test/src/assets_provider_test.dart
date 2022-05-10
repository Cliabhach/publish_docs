// ignore_for_file: prefer_const_constructors, directives_ordering
import 'dart:io';

import 'package:analyzer/file_system/file_system.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:publish_docs/src/private/assets_resource_provider.dart';

import 'test_util.dart';

void main() {
  group('overlay', () {
    late ResourceProvider provider;
    late String testResourcePath;

    setUp(() {
      testResourcePath = resourcePath('overlay');
    });
    test('can retrieve physical files', () async {
      provider = await obtainAssetsProvider();

      final test1Path = path.absolute(testResourcePath, 'test1');
      final testFolder = provider.getFolder(test1Path);
      // Make sure that our preparation is all right.
      expect(testFolder.exists, isTrue);
    });
    test('can find basic file', () async {
      final test1Path = path.absolute(testResourcePath, 'test1');
      final parentPath = path.absolute(test1Path, 'parent');

      provider = await obtainAssetsProvider(pathForLayers: parentPath);

      // ...now look for 'child.txt' and 'not-here.txt'
      final parentFolder = provider.getFolder(parentPath);
      final childResource = parentFolder.getChild('child.txt');
      final notHereResource = parentFolder.getChild('not-here.txt');
      expect(childResource.exists, isTrue);
      expect(notHereResource.exists, isFalse);
    });
    test('can find basic file via path alias', () async {
      final test1Path = path.absolute(testResourcePath, 'test1');
      final parentPath = path.absolute(test1Path, 'parent');
      final fakeParentPath = path.absolute(test1Path, 'not-present-on-disk');

      expect(Directory(fakeParentPath).existsSync(), isFalse);

      provider = await obtainAssetsProvider(
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
    test('can find overlay file', () async {
      final test2Path = path.absolute(testResourcePath, 'test2');

      final noFilesPath = path.absolute(test2Path, 'no-files');
      final oneFilePath = path.absolute(test2Path, 'one-file');
      final otherFilesPath = path.absolute(test2Path, 'other-files');

      final parentPath = path.absolute(test2Path, 'parent');

      provider = await obtainAssetsProvider(
        pathForLayers: parentPath,
        layers: [
          noFilesPath,
          oneFilePath,
          otherFilesPath,
      ],);

      final notHereResource = relative(provider, parentPath, 'not-here.txt');
      final sampleResourceA = relative(provider, parentPath, 'sampleA');
      final sampleResourceB = relative(provider, parentPath, 'sampleB');

      expect(sampleResourceA.exists, isTrue);
      expect(notHereResource.exists, isFalse);
      expect(sampleResourceB.exists, isTrue);

      // check the contents of sampleA - the version from 'one-file' should be
      // returned here
      expect(sampleResourceA, isA<File>());
      final sampleContents = (sampleResourceA as File).readAsStringSync();
      expect(sampleContents, 'A');
    });
  });
}
