// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:git/git.dart';
import 'package:publish_docs/src/git/commands.dart';

/// A wrapper around [Git](https://git-scm.com/) that uses [GitDir].
///
/// Where a function does not exist on the [GitDir] class, we try to recreate
/// that function with [GitDir.runCommand].
class GitDirCommands extends GitCommands {
  /// Public constructor for [GitDirCommands].
  ///
  /// Use one of these to do git-related stuff to a specific directory - all
  /// sorts of commands are on offer, from [add] and [commit] to [am] and
  /// [revParse].
  GitDirCommands(this.gitDir) : super(gitDir.path);

  /// The underlying [GitDir] - this is what actually executes the commands.
  GitDir gitDir;

  @override
  Future<void> add(String path) {
    return gitDir.runCommand(['add', path]);
  }

  @override
  Future<void> am(String patchFilePath) {
    return gitDir.runCommand(['am', patchFilePath.trim(),]);
  }

  @override
  Future<String> branchName() {
    return gitDir.currentBranch().then((ref) => ref.branchName);
  }

  @override
  Future<String> branchSha({String name = 'HEAD'}) {
    if (name == 'HEAD') {
      return gitDir.currentBranch().then((ref) => ref.sha);
    } else {
      return gitDir.branchReference(name).then((ref) {
        if (ref == null) {
          throw UnsupportedError(
            "The $name branch is missing...that's not good.",
          );
        }
        return ref.sha;
      });
    }
  }

  @override
  Future<void> checkout(String gitRef, {List<String> paths = const []}) {
    // We should upstream the 'checkout' method. Maybe.
    if (paths.isEmpty) {
      return gitDir.runCommand(['checkout', gitRef,]);
    } else {
      return gitDir.runCommand(['checkout', gitRef, '--',] + paths);
    }
  }

  @override
  Future<void> commit(String message) {
    return gitDir.runCommand(['commit', '-m', message,]);
  }

  @override
  Future<Iterable<String>> get commits {
    // GitDir returns commits in a 'CommitSha -> Commit' format
    return gitDir.commits().then((refs) => refs.keys);
  }

  @override
  Future<String> formatPatch(String gitStartRef, String gitEndRef) {
    return gitDir.runCommand(['format-patch', '$gitStartRef..$gitEndRef',])
        .then(_getOutput);
  }

  @override
  Future<void> reset(String gitRef, {bool hard = false}) {
    if (hard) {
      return gitDir.runCommand(['reset', '--hard', gitRef,]);
    } else {
      return gitDir.runCommand(['reset', gitRef,]);
    }
  }

  @override
  Future<String> revParse(Iterable<String> args) {
    return gitDir.runCommand(['rev-parse', ] + args.toList()).then(_getOutput);
  }

  @override
  Future<void> stash() {
    return gitDir.runCommand(['stash', ]);
  }

}

/// Retrieve the standard-output from a [GitDir.runCommand].
///
/// See also [Process.run].
String _getOutput(ProcessResult result) {
  return result.stdout as String;
}
