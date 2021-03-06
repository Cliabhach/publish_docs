// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// File modifications for Monstarlab copyright (c) 2022, Philip Cohn-Cort
// Source of `generateDocs` was in dartdoc-5.0.1, at path `/bin/dartdoc.dart`

import 'dart:async';

import 'package:git/git.dart';
import 'package:path/path.dart' as path;

import 'package:publish_docs/src/git/dir_commands.dart';
import 'package:publish_docs/src/operation/operation.dart';

/// Analyzes Dart files and generates a representation of included libraries,
/// classes, and members. Uses the current directory to look for libraries.
Future<void> generateDocs(List<String> arguments) async {
  // A provider of metadata. Among other things, this can tell us where the
  // Flutter SDK is installed.
  final metaProvider = await obtainPackageMetaProvider();

  // Parse command-line arguments, load config from the dartdoc_options.yaml,
  // and read in some basic pubspec info for the current app.
  final dartdoc = await getDartdocWithAssets(metaProvider, arguments);

  // Generate docs! Unless the config says not to generate them, or the config
  // was extra-malformed (small parsing errors are ignored).
  dartdoc?.executeGuarded();
}

/// Copy the latest documentation into the 'gh-pages' (GitHub Pages) branch.
///
/// This performs some quick checks to make sure this process is running in a
/// well-defined Git Directory, and then starts [InPlaceBranchUpdate]
/// asynchronously. Check out the docs on that function for more details on
/// exactly what happens.
///
/// We currently use a [GitDir]-backed [GitDirCommands] object to perform those
/// operations.
Future<void> updateGitHubDocs(List<String> arguments) {
  final currentPath = path.current;

  return GitDir.isGitDir(currentPath).then((isGitDirectory) {
    if (isGitDirectory) {
      GitDir.fromExisting(currentPath).then((gitDir) async {
        final git = GitDirCommands(gitDir);
        if (!await git.branchExists('gh-pages')) {
          throw UnsupportedError(
              'Please ensure that your repository has a branch '
                  'called `gh-pages` before continuing.'
          );
        }
        return InPlaceBranchUpdate(git).run('gh-pages', arguments);
      });
    }
  });
}
