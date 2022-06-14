// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:dartdoc/dartdoc.dart';
import 'package:publish_docs/src/git/commands.dart';
import 'package:publish_docs/src/operation/docs_bridge.dart';
import 'package:publish_docs/src/util/doc_util.dart';
import 'package:publish_docs/src/util/path_util.dart';

/// Update a git branch with new project docs.
///
/// Implementations have a lot of flexibility in what they do with [run], but
/// the end result should always have involved a call to [generate].
abstract class BranchUpdate {
  /// One of these can be used to generate docs in specific place.
  ///
  /// The [git] given here defines the source directory, and we may use the
  /// [GitCommands.path] property to access that.
  BranchUpdate(this.git, {
    this.logTag = 'Update',
    void Function(String message) logger = print
  }) : _logger = logger;

  /// Project-specific git context.
  ///
  /// We use this to execute git commands
  final GitCommands git;

  /// A distinctive prefix for use in log messages.
  ///
  /// See also [logStatus].
  final String logTag;

  /// The [_logger] property is here primarily for testing. By default we print
  /// [logStatus] messages to the console, but we will pass them to the function
  /// given here if desired.
  final Function(String message) _logger;

  /// Add a message to the log.
  ///
  /// This way methods like [run] and [showOnCompleted] can provide realtime
  /// updates on what they are doing.
  void logStatus(String message) {
    _logger('$logTag: $message');
  }

  /// Figure out what version string best reflects this project.
  ///
  /// This should generally be used as part of new commit messages.
  Future<String> defineVersion() async {
    final versionString = await obtainDocsVersion(git).then((s) => s.trim());
    logStatus('(updating GitHub Pages for version $versionString)');
    return versionString;
  }

  /// Generate the docs!
  ///
  /// Documentation will be placed in the given directory.
  Future<DartdocOptionContext> generate(Directory outputDirectory,
      List<String> arguments) {
    final modified = changeOutputDir(arguments, outputDirectory);
    return generateAndWaitForDocs(modified);
  }

  /// Or show index.html in a browser?
  ///
  /// With a little web frontend, that could be pretty....
  Future<void> showOnCompleted(Directory output) {
    final indexDocFile = File(absolutePath(output.path, 'index.html'));
    logStatus(
      '''
The gh-pages branch has been updated. Please review the files in docs/api/ to
make sure there aren't any surprises there. We recommend opening the index.html
(located at ${indexDocFile.uri} )
in the browser, at the very least. If it all looks good and there are no
conflicts with the remote, you can push the new pages to GitHub with a simple

`git push`

If there's a conflict, or there are other issues with the changes, you can
remove the new commit by calling

`git reset --hard HEAD~`
''');
    return Future.value();
  }

  /// Make the update using this function!
  Future<void> run(String branchName, List<String> arguments);
}
