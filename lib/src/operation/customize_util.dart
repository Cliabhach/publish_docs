// SPDX-License-Identifier: BSD-3-Clause
/// Utility file for defining project-specific requirements and config.

import 'dart:async';

import 'package:dartdoc/dartdoc.dart';
import 'package:dartdoc/options.dart';
import 'package:git/git.dart';

import 'package:publish_docs/src/private/assets_layers.dart';
import 'package:publish_docs/src/operation/analyzer_util.dart';
import 'package:publish_docs/src/util/doc_util.dart';
import 'package:publish_docs/src/util/git_util.dart';

/// Figure out what version of documentation we have here.
///
/// Will always return a valid https://semver.org/ String. The short git commit
/// hash will be in the 'metadata' part of that version.
Future<String> obtainDocsVersion(GitDir forGit) async {
  // Part 1: Git
  // Short Git-Hash for the currently-checked-out commit
  final currentHash = await obtainGitVersion(forGit);

  // Part 2: Dart
  final pubspecVersion = obtainAppVersion(forGit.path);

  // We combine these two into a semver-compatible version string
  return '$pubspecVersion+$currentHash';
}

/// (Re-)Generate documentation using [Dartdoc].
///
/// All of the actual work is handled by [getDartdocWithAssets] and
/// [Dartdoc.generateDocs]. All we really do here is
///
/// 1. retrieve a [PackageMetaProvider], and
/// 2. throw a custom error if the [Dartdoc] object comes back as null.
///
/// See also [obtainDartdoc] and [addAssets].
Future<DartdocOptionContext> generateAndWaitForDocs(
    List<String> arguments) async {
  final metaProvider = await obtainPackageMetaProvider();
  final dartdoc = await getDartdocWithAssets(metaProvider, arguments);
  if (dartdoc != null) {
    final docCompleter = Completer<DartdocOptionContext>();
    dartdoc.executeGuarded((context) async {
      return docCompleter.complete(context);
    });
    return docCompleter.future;
  } else {
    throw UnsupportedError(
      'Could not generate documentation; run the '
      'gen_docs.dart task directly to see detailed error messages.',
    );
  }
}

/// Create a [Dartdoc] object that uses project-specific assets.
///
/// We currently replace the font, the color schemes, and the default favicon.
/// Note that dartdoc will always find and use our `dartdoc_options.yaml`, so
/// there's no need to specify anything here that's in that YAML file.
///
/// Delegates to [addAssets] and [obtainDartdoc].
Future<Dartdoc?> getDartdocWithAssets(
    PackageMetaProvider metaProvider, List<String> arguments) async {
  Dartdoc? dartdoc;

  // Request usage of our 'assets' instead of dartdoc's bundled resources.
  final modifiedArguments = addAssets(arguments);

  final config = parseOptions(metaProvider, modifiedArguments);
  if (config == null) {
    // There was an error while parsing options.
    dartdoc = null;
  } else {
    dartdoc = await obtainDartdoc(config, metaProvider);
  }

  return dartdoc;
}

/// We can't define the 'resourcesDir' property in `dartdoc_options.yaml`, so we
/// add it to the arguments list here.
///
/// Use the returned list for a call to [parseOptions].
List<String> addAssets(List<String> arguments,) {
  final assetsAbsolutePath = absolutePath('doc', 'assets');
  final modifiedArguments = arguments + ['--resources-dir', assetsAbsolutePath];
  return modifiedArguments;
}
