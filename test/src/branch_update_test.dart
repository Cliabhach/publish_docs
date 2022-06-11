// ignore_for_file: prefer_const_constructors, directives_ordering, avoid_print

import 'package:mocktail/mocktail.dart';
import 'package:publish_docs/src/git/commands.dart';
import 'package:publish_docs/src/operation/branch_update.dart';
import 'package:test/test.dart';


class MockGitCommands extends Mock implements GitCommands {
}

/// Custom version of [BranchUpdate] designed for use only in tests.
///
/// Instead of printing to the console, calls to [logStatus] will add
/// entries to the new [messages] property.
class SimpleBranchUpdate extends BranchUpdate {
  SimpleBranchUpdate(super.git, this.messages);

  final List<String> messages;

  void logStatus(String message) {
    messages.add('$logTag: $message');
  }

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
    setUp(() {
      git = MockGitCommands();
      logMessages = [];
    });
    // Ideally we could use the superclass implementation of logStatus? And then
    // this would be a test of how that prepends the logTag.
    test('basic check of SimpleBranchUpdate', () async {
      // Given
      final update = SimpleBranchUpdate(git, logMessages);
      const target = 'some-branch';

      // When
      await update.run(target, []);

      // Then
      expect(logMessages, isNotEmpty);
      expect(logMessages.first, 'Update: Running for some-branch');
    });
  });
}