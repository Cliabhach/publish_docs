// SPDX-License-Identifier: BSD-3-Clause
/// Utility file for working with GitHub Pages.

import 'package:publish_docs/src/git/commands.dart';
import 'package:publish_docs/src/util/git_util.dart';

/// Switch some paths to match the 'gh-pages' branch.
///
/// Basically just a wrapper around [GitCommandsExtension.checkoutBranch]. If
/// [paths] is empty (as it is by default), we'll just checkout all files.
Future<void> checkoutGitHubBranch(GitCommands git,
    {List<String> paths = const []}) async {

  return git.checkoutBranch('gh-pages', paths: paths);
}
