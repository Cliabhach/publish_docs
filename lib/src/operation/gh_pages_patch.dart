// SPDX-License-Identifier: BSD-3-Clause
/// Utility file for working with GitHub Pages.
import 'dart:io';

import 'package:publish_docs/src/git/commands.dart';
import 'package:publish_docs/src/operation/branch_update.dart';
import 'package:publish_docs/src/operation/docs_bridge.dart';
import 'package:publish_docs/src/util/doc_util.dart';
import 'package:publish_docs/src/util/git_util.dart';

/// Create a patch-file with updates to published documentation.
///
/// Make sure [outputDirectory] points to the directory where only generated
/// documentation files are located - the [generateAndWaitForDocs] call is
/// allowed to overwrite anything in there.
Future<String> generateDocsPatch(GitCommands git, Directory outputDirectory,
    List<String> arguments, String startingBranchRef) async {
  // Task 1: Pull version number
  final versionString = await obtainDocsVersion(git).then((s) => s.trim());
  logStatus('(updating GitHub Pages for version $versionString)');
  // Task 2: Prime the git index with files from the gh-pages branch
  await checkoutGitHubBranch(git, paths: [outputDirectory.path]);
  logStatus('Checked out files from gh-pages into ${outputDirectory.path}.');
  // Task 3: Generate docs into [outputDirectory]
  final modifiedArguments = changeOutputDir(arguments, outputDirectory);
  final generateFuture = generateAndWaitForDocs(modifiedArguments);
  logStatus('Started generating documentation...');
  // Task 4: Wait for existing work to complete
  await generateFuture;
  logStatus('...there, documentation generated!');
  // Task 5: Save our changes into a patch (this creates 2 temp commits)
  final patch = await patchOutOfGitDiff(
    git,
    outputDirectory.path,
    'docs: Regenerate to reflect $versionString',
  );
  // Task 6: Reset branch back to original state
  if (patch.isEmpty) {
    throw UnsupportedError("Patch wasn't generated correctly. Stopping now.");
  }
  await git.hardReset(startingBranchRef);
  return patch;
}

/// Switch some paths to match the 'gh-pages' branch.
///
/// Basically just a wrapper around [GitCommandsExtension.checkoutBranch]. If
/// [paths] is empty (as it is by default), we'll just checkout all files.
Future<void> checkoutGitHubBranch(GitCommands git,
    {List<String> paths = const []}) async {

  return git.checkoutBranch('gh-pages', paths: paths);
}
