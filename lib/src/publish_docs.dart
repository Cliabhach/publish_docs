// SPDX-License-Identifier: BSD-3-Clause
// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// File modifications for Monstarlab copyright (c) 2022, Philip Cohn-Cort
// Source of `generateDocs` was in dartdoc-5.0.1, at path `/bin/dartdoc.dart`

import 'dart:io';

import 'package:dartdoc/dartdoc.dart';
import 'package:git/git.dart';
import 'package:path/path.dart' as Path;

import 'dart:async';

import '../publish_docs.dart';
import 'util/util.dart';


/// {@template publish_docs}
/// Publish your documentation to GitHub Pages!
/// {@endtemplate}
class PublishDocs {
  /// {@macro publish_docs}
  const PublishDocs();
}


/// Analyzes Dart files and generates a representation of included libraries,
/// classes, and members. Uses the current directory to look for libraries.
Future<void> generateDocs(List<String> arguments) async {
  // A provider of metadata. Among other things, this can tell us where the
  // Flutter SDK is installed.
  var metaProvider = pubPackageMetaProvider;

  // Parse command-line arguments, load config from the dartdoc_options.yaml,
  // and read in some basic pubspec info for the current app.
  Dartdoc? dartdoc = await getDartdocWithAssets(metaProvider, arguments);

  // Generate docs! Unless the config says not to generate them, or the config
  // was extra-malformed (small parsing errors are ignored).
  dartdoc?.executeGuarded();
}


/// Copy the latest documentation into the 'gh-pages' (GitHub Pages) branch.
///
/// This performs some quick checks to make sure this process is running in a
/// well-defined Git Directory, and then starts [updateGitHubPages]
/// asynchronously. Check out the docs on that function for more details on
/// exactly what happens.
Future<void> updateGitHubDocs(List<String> arguments) {
  String currentPath = Path.current;

  return GitDir.isGitDir(currentPath).then((isGitDirectory) {
    if (isGitDirectory) {
      final binDirectory = Directory(Path.absolute('doc', 'bin'));
      sanityCheck(binDirectory);
      GitDir.fromExisting(currentPath)
          .then((gitDir) async => await updateGitHubPages(gitDir, arguments));
    }
  });
}