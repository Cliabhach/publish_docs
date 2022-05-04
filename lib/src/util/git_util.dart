// SPDX-License-Identifier: BSD-3-Clause
/// Utility file for working with Git, mainly via the [GitDir] class.

import 'dart:io';

import 'package:git/git.dart';

/// Retrieve the git short hash for the currently-checked-out commit.
///
/// See also [this rev-parse overview](https://git-scm.com/docs/git-rev-parse).
Future<String> obtainGitVersion(GitDir forGit) async {
  var args = ['rev-parse', '--short', '--verify', 'HEAD'];
  return await forGit.runCommand(args).then((process) {
    return process.stdout as String;
  });
}

/// Format local changes (from 'git format-patch') into a Git Patch.
///
/// The patch can then be used for a call to [GitDirExtension.applyPatch].
Future<String> patchOutOfGitDiff(GitDir forGit, String path, String message) {
  // Q: How do you run format-patch on the working diff that hasn't been commited yet?
  // A: Well, create a commit first.

  return Future(() {
    // Create temporary commit (1) with existing docs. These were added to the
    // index by the 'checkout' command.
    return forGit.runCommand(['commit', '-m', '$message (files in index)']);
  }).then((commitResult) async {
    // Add new docs to the index
    return forGit.runCommand(['add', path]);
  }).then((addResult) async {
    // Create temporary commit (2) with new docs
    return forGit.runCommand(['commit', '-m', message]);
  }).then((commitResult) async {
    return await doFormatPatch(forGit);
  }).then((formatPatchResult) {
    // Return the patch's filename
    return formatPatchResult.stdout as String;
  });
}

Future<ProcessResult> doFormatPatch(GitDir forGit) async {
  var commitList = await forGit.commits('HEAD');
  MapEntry<String, Commit> newDocsCommit = commitList.entries.first;
  MapEntry<String, Commit> oldDocsCommit = commitList.entries.skip(1).first;
  // Format the difference between these two commits into a patch
  final sha1 = oldDocsCommit.key;
  final sha2 = newDocsCommit.key;
  return forGit.runCommand(['format-patch', '$sha1..$sha2']);
}

/// A basic extension for [GitDir] with branch and reset capabilities.
extension GitDirExtension on GitDir {
  /// Run `git checkout` to make the files in this [GitDir] match a commit.
  ///
  /// Please use the convenience method [checkoutBranch] if the commit you want
  /// to use is actually the HEAD of a branch.
  Future<ProcessResult> checkout(String commit,
      {List<String> paths = const []}) {
    final List<String> commandAndFlags;
    if (paths.isEmpty) {
      commandAndFlags = ['checkout', commit];
    } else {
      commandAndFlags = ['checkout', commit, '--'] + paths;
    }
    return runCommand(commandAndFlags);
  }

  /// Force the Git directory to look exactly like the specified commit.
  ///
  /// WARNING: This will overwrite unsaved/uncommitted changes. Be careful when
  /// and how you use this.
  ///
  /// If you accidentally run this with the wrong ref, promptly use `git reflog`
  /// to find the prior commit. You can `git reset --hard` to that in order to
  /// minimise the damage.
  Future<ProcessResult> hardReset(CommitReference ref) {
    return runCommand(['reset', '--hard', ref.sha]);
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
  Future<ProcessResult> applyPatch(String patchFile) {
    return runCommand(['am', patchFile.trim()]);
  }

  /// Switch all of [paths] to branch [name], using [target].
  ///
  /// If that [BranchReference] turns out to be null we'll throw an error.
  Future<ProcessResult> checkoutBranch(
      String name, Future<BranchReference?> target,
      {List<String> paths = const []}) {
    return target.then((branchRef) {
      // We should upstream the 'checkout' method. Maybe.
      if (branchRef == null) {
        throw UnsupportedError(
            "The $name branch is missing...that's not good.");
      } else {
        return checkout(branchRef.branchName, paths: paths);
      }
    });
  }
}
