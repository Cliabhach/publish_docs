// ignore_for_file: prefer_const_constructors, directives_ordering, avoid_print

import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:publish_docs/src/git/commands.dart';
import 'package:publish_docs/src/operation/branch_update.dart';
import 'package:publish_docs/src/util/path_util.dart';
import 'package:publish_docs/src/util/yaml_util.dart';
import 'package:test/test.dart';

import 'test_util.dart';


class MockGitCommands extends Mock implements GitCommands {
}

/// Custom version of [BranchUpdate] designed for use only in tests.
///
/// Instead of printing to the console, calls to [logStatus] will add
/// entries to the constructor's `messages` property.
class SimpleBranchUpdate extends BranchUpdate {
  SimpleBranchUpdate(super.git, List<String> messages):
        super(logger: messages.add);

  @override
  Future<void> run(String branchName, List<String> arguments) {
    logStatus('Running for $branchName');
    return Future.value();
  }
}

void main() {
  group('branch_update', () {
    late GitCommands git;
    late List<String> logMessages;
    late String testResourcePath;
    setUp(() {
      git = MockGitCommands();
      logMessages = [];
      testResourcePath = resourcePath('branch_update');
    });
    test('basic check of logStatus', () async {
      // Given
      final update = SimpleBranchUpdate(git, logMessages);
      const target = 'some-branch';

      // When
      await update.run(target, []);

      // Then
      expect(logMessages, isNotEmpty);
      expect(logMessages.first, 'Update: Running for some-branch');
    });
    test('version is based on git data', () async {
      // Given
      final update = SimpleBranchUpdate(git, logMessages);
      // (use a pubspec that we've prepared for this test)
      final testProjectPath = path.absolute(testResourcePath, 'test1');
      when(() => git.path).thenReturn(testProjectPath);
      // (don't actually check the git revision; use this hash instead)
      when(() => git.revParse(any())).thenAnswer((_) => Future.value('test1'));

      // When
      final versionString = await update.defineVersion();

      // Then
      verify(() => git.revParse(any())).called(1);
      expect(logMessages, isNotEmpty);
      // (we use parentheses to indicate lower-priority messages)
      // (the actual contents aren't so important; we just expect one message)
      expect(logMessages.first, stringContainsInOrder(['Update:', '(', ')']));
      expect(versionString, '1.2.3+test1');
    });
    test('generate uses given output dir', skip: 'see inline TODO', () async {
      // Given
      final update = SimpleBranchUpdate(git, logMessages);
      // (use dartdoc_options that we've prepared for this test)
      final testProjectPath = path.absolute(testResourcePath, 'test2');
      when(() => git.path).thenReturn(testProjectPath);
      // (prefetch the options..)
      YamlUtil.prefetchPublishDocsOptions(
          absoluteOptionsFilePath(optionsFileDir: testProjectPath)
      );
      // (this output directory will not actually be used if the test passes)
      final outputDir = await makeTempDir('branch_update.test2');
      final arguments = ['--generate-docs'];

      // When
      // TODO(Cliabhach): avoid actually generating docs for this project
      final generated = await update.generate(outputDir, arguments);

      // Then
      expect(logMessages, isEmpty);
      expect(generated.output, outputDir.path);
      expect(outputDir.listSync(), isEmpty);
    });
    test('assets path can be set', () async {
      // Given
      // (use dartdoc_options that we've prepared for this test)
      final testProjectPath = path.absolute(testResourcePath, 'test3');

      // When
      final first = assetsPath();
      // (prefetch the options..)
      YamlUtil.prefetchPublishDocsOptions(
          absoluteOptionsFilePath(optionsFileDir: testProjectPath)
      );
      // (..load the path)
      final found = assetsPath();

      // Then
      // (Substring match is good enough, ending '/' should have been removed)
      expect(first, endsWith('doc/assets'));
      expect(found, endsWith('doc3/assets1'));
    });
  });
}
