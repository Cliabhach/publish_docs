// SPDX-License-Identifier: BSD-3-Clause
/// Utility file for working with Git, mainly via the [GitCommands] class.

import 'package:meta/meta.dart';

import 'package:publish_docs/src/git/commands.dart';

/// Retrieve the git short hash for the currently-checked-out commit.
///
/// See also [this rev-parse overview](https://git-scm.com/docs/git-rev-parse).
Future<String> obtainGitVersion(GitCommands git) async {
  return git.revParse(['--short', '--verify', 'HEAD']);
}

/// Format local changes (from 'git format-patch') into a Git Patch.
///
/// The patch can then be used for a call to [GitCommandsExtension.applyPatch].
Future<String> patchOutOfGitDiff(GitCommands git, String path, String message) {
  // Q: How do you run format-patch on the working diff that is not committed?
  // A: Well, create a commit first.

  return Future(() {
    // Create temporary commit (1) with existing docs. These were added to the
    // index by the 'checkout' command.
    return git.commit('$message (files in index)');
  }).then((commitResult) async {
    // Add new docs to the index
    return git.add(path);
  }).then((addResult) async {
    // Create temporary commit (2) with new docs
    return git.commit(message);
  }).then((commitResult) async {
    // Return the patch's filename
    return doFormatPatch(git);
  });
}

/// Create a new patch file to represent the contents of the **HEAD** commit.
///
/// In order to do that, we have to pass the first two [GitCommands.commits]
/// to [GitCommands.formatPatch].
@visibleForTesting
Future<String> doFormatPatch(GitCommands git) async {
  final commitList = await git.commits;
  final newDocsCommit = commitList.first;
  final oldDocsCommit = commitList.skip(1).first;
  // Format the difference between these two commits into a patch
  return git.formatPatch(oldDocsCommit, newDocsCommit);
}

/// A basic extension for [GitCommands] with branch and reset capabilities.
extension GitCommandsExtension on GitCommands {

  /// Force the Git directory to look exactly like the specified commit.
  ///
  /// WARNING: This will overwrite unsaved/uncommitted changes. Be careful when
  /// and how you use this.
  ///
  /// If you accidentally run this with the wrong ref, promptly use `git reflog`
  /// to find the prior commit. You can `git reset --hard` to that in order to
  /// minimise the damage.
  Future<void> hardReset(String ref) {
    return reset(ref, hard: true);
  }

  /// Apply and commit a git patch to the Git directory.
  ///
  /// While most of the time [`git apply`](https://git-scm.com/docs/git-apply)
  /// is good enough, here we use [`git am`](https://git-scm.com/docs/git-am).
  /// The `git am` command is not something you see frequently in use outside
  /// of rebase operations.
  ///
  /// We will helpfully strip any trailing newlines from the given [patchFile]
  /// before passing it to `am`.
  Future<void> applyPatch(String patchFile) {
    return am(patchFile.trim());
  }

  /// Switch all of [paths] to the branch whose name is [name].
  ///
  /// Make sure to provide the name of the branch itself, and not a SHA-1 hash.
  Future<void> checkoutBranch(String name, {List<String> paths = const []}) {
    return checkout(name, paths: paths);
  }
}
