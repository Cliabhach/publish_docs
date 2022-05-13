// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:publish_docs/src/git/commands.dart';

/// Update a git branch with new project docs.
///
/// Implementations have a lot of flexibility in what they do with [run], but
/// the end result should always have involved a call to [generate].
abstract class BranchUpdate {
  /// One of these can be used to generate docs in specific place.
  ///
  /// The [git] given here defines the source directory, and we may use the
  /// [GitCommands.path] property to access that.
  BranchUpdate(this.git);

  /// Project-specific git context.
  ///
  /// We use this to execute git commands
  final GitCommands git;

  /// Figure out what version string best reflects this project.
  ///
  /// This should generally be used as part of new commit messages.
  Future<void> defineVersion();

  /// Generate the docs!
  ///
  /// Documentation will be placed in the given directory.
  Future<void> generate(Directory outputDirectory, List<String> arguments);

  /// Or show index.html in a browser?
  ///
  /// With a little web frontend, that could be pretty....
  Future<void> showOutputDirectory();

  /// Make the update using this function!
  Future<void> run(String branchName, List<String> arguments);
}






