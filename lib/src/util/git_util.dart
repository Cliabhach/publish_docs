// SPDX-License-Identifier: BSD-3-Clause
/// Utility file for working with Git, mainly via [GitDir] and [GitCommands].

import 'package:git/git.dart';
import 'package:publish_docs/src/git/commands.dart';

/// Retrieve the git short hash for the currently-checked-out commit.
///
/// See also [this rev-parse overview](https://git-scm.com/docs/git-rev-parse).
Future<String> obtainGitVersion(GitCommands forGit) async {
  return forGit.revParse(['--short', '--verify', 'HEAD']);
}

/// Format local changes (from 'git format-patch') into a Git Patch.
///
/// The patch can then be used for a call to [GitDirExtension.applyPatch].
Future<String> patchOutOfGitDiff(
    GitCommands forGit, String path, String message) {
  // Q: How do you run format-patch on the working diff that hasn't been commited yet?
  // A: Well, create a commit first.

  return Future(() {
    // Create temporary commit (1) with existing docs. These were added to the
    // index by the 'checkout' command.
    return forGit.commit('$message (files in index)');
  }).then((commitResult) async {
    // Add new docs to the index
    return forGit.add(path);
  }).then((addResult) async {
    // Create temporary commit (2) with new docs
    return forGit.commit(message);
  }).then((commitResult) async {
    // Return the patch's filename
    return doFormatPatch(forGit);
  });
}

/// Create a new patch file to represent the contents of the **HEAD** commit.
///
/// In order to do that, we have to pass the first two [GitCommands.commits]
/// to [GitCommands.formatPatch].
Future<String> doFormatPatch(GitCommands git) async {
  final commitList = await git.commits;
  final newDocsCommit = commitList.first;
  final oldDocsCommit = commitList.skip(1).first;
  // Format the difference between these two commits into a patch
  return git.formatPatch(oldDocsCommit, newDocsCommit);
}

/// A basic extension for [GitDir] with branch and reset capabilities.
extension GitDirExtension on GitCommands {

  /// Force the Git directory to look exactly like the specified commit.
  ///
  /// WARNING: This will overwrite unsaved/uncommitted changes. Be careful when
  /// and how you use this.
  ///
  /// If you accidentally run this with the wrong ref, promptly use `git reflog`
  /// to find the prior commit. You can `git reset --hard` to that in order to
  /// minimise the damage.
  Future<void> hardReset(CommitReference ref) {
    return reset(ref.sha, hard: true);
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

  /// Switch all of [paths] to branch [name], using [target].
  ///
  /// If that [BranchReference] turns out to be null we'll throw an error.
  Future<void> checkoutBranch(
      String name, Future<BranchReference?> target,
      {List<String> paths = const []}) {
    return target.then((branchRef) {
      // We should upstream the 'checkout' method. Maybe.
      if (branchRef == null) {
        throw UnsupportedError(
          "The $name branch is missing...that's not good.",
        );
      } else {
        return checkout(branchRef.branchName, paths: paths);
      }
    });
  }
}
