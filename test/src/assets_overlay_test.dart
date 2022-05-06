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
      expect(testFolder.exists, isTrue);
    });
  });
}
