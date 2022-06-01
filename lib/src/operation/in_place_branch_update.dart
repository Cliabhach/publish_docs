// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:path/path.dart' as path;

import 'package:publish_docs/src/git/commands.dart';
import 'package:publish_docs/src/operation/branch_update.dart';

/// A class for adding a Git commit to a branch.
///
/// This uses custom logic extended upon the [GitCommands] class.
class InPlaceBranchUpdate extends BranchUpdate {
  /// A new [BranchUpdate] that doesn't use a temporary directory.
  InPlaceBranchUpdate(GitCommands git) : super(git);

  /// The directory where generated docs will be placed.
  ///
  /// Points to 'docs/api/' by default.
  final Directory outputDirectory = Directory(path.absolute('docs', 'api'));

  @override
  Future<void> showOnCompleted(Directory output) async {
    await super.showOnCompleted(output);
    // TODO(Cliabhach): Add extra logging for the patch file, mention git push
    return Future.value();
  }

  @override
  Future<void> run(String branchName, List<String> arguments) async {
    logStatus('Found the git directory.');
    // Task 1: Save current state, in case something goes wrong.
    await _captureInitialState();
    // TODO(Cliabhach): Everything else
  }

  Future<void> _captureInitialState() async {
    await git.stash();
    // TODO(Cliabhach): What do we do with the starting branch SHA & name?
    return Future.value();
  }

  /// Create a patch-file with updates to published documentation.
  ///
  /// Make sure [outputDirectory] points to the directory where only generated
  /// documentation files are located - the [generateAndWaitForDocs] call is
  /// allowed to overwrite anything in there.
  Future<String> generateDocsPatch(GitCommands git, Directory outputDirectory,
      List<String> arguments) async {
    // TODO(Cliabhach): Migrate code from gh_pages_patch.dart
  }
}
