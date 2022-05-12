// ignore_for_file: prefer_const_constructors, directives_ordering
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
      provider = obtainAssetsOverlayProvider();
      testResourcePath = resourcePath('overlay');
    });
    test('can find basic file', () {
      final test1Path = path.absolute(testResourcePath, 'test1');
      final testFolder = provider.getFolder(test1Path);
      // Make sure that our preparation is all right.
      expect(testFolder.exists, isTrue);

      // ...now look for 'child.txt' and 'not-here.txt'
      final parentPath = path.absolute(test1Path, 'parent');
      final parentFolder = provider.getFolder(parentPath);
      final childResource = parentFolder.getChild('child.txt');
      final notHereResource = parentFolder.getChild('not-here.txt');
      expect(childResource.exists, isTrue);
      expect(notHereResource.exists, isFalse);
    });
  });
}
