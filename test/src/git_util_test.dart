// ignore_for_file: prefer_const_constructors, directives_ordering

import 'package:mocktail/mocktail.dart';
import 'package:publish_docs/src/git/commands.dart';
import 'package:publish_docs/src/util/git_util.dart';
import 'package:test/test.dart';

import 'test_util.dart';

class MockGitCommands extends Mock implements GitCommands {
}

void main() {
  group('git_util', () {
    late GitCommands git;

    setUp(() {
      git = MockGitCommands();
    });

    test('only rev-parses HEAD', () async {
      // Given
      when(() => git.revParse(any())).thenAnswer(futureAnswer(() => ''));

      // When
      await obtainGitVersion(git);

      // Then
      final res = verify(() => git.revParse(captureAny()));

      final capturedIterable = res.captured.first as Iterable<String>;
      final capturedList = capturedIterable.toList();

      // (rev-parse should only have been called once)
      res.called(1);

      // (args should include the 'HEAD' ref)
      expect(capturedList.remove('HEAD'), true);
      // (everything else should be an option)
      expect(capturedList.every((element) => element.startsWith('--')), true);
    });
  });
}
