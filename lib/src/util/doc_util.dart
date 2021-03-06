// SPDX-License-Identifier: BSD-3-Clause
/// Utility file for working with Dartdoc (and documentation in general).

import 'dart:io';

import 'package:dartdoc/dartdoc.dart';
import 'package:dartdoc/options.dart';


/// Create a new [Dartdoc] object from the given config.
///
/// These lines of code were originally written as part of the file
/// `package:dartdoc/bin/dartdoc.dart`, whose BSD-style license can be found in
/// the dartdoc-5.0.1 package sources.
Future<Dartdoc> obtainDartdoc(DartdocProgramOptionContext config,
    PackageMetaProvider metaProvider) async {
  final packageConfigProvider = PhysicalPackageConfigProvider();
  final packageBuilder =
      PubPackageBuilder(config, metaProvider, packageConfigProvider);
  final dartdoc = config.generateDocs
      ? await Dartdoc.fromContext(config, packageBuilder)
      : Dartdoc.withEmptyGenerator(config, packageBuilder);
  return dartdoc;
}

/// The default output directory is 'doc/api/', but GitHub Pages uses the path
/// 'docs/api/' instead.
///
/// Use the returned list for a call to [generateAndWaitForDocs].
///
/// See also [addAssets].
List<String> changeOutputDir(List<String> arguments, Directory output) {
  return arguments + ['--output', output.path];
}

/// Read in the 'version' property of the app's pubspec.yaml.
///
/// Strictly speaking, this reads metadata of whatever directory is given.
String obtainAppVersion(String gitDirectory) {
  // There is no benefit to using 'overlayPackageMetaProvider' here instead.
  final metaProvider = pubPackageMetaProvider;
  final appFolder = metaProvider.resourceProvider.getFolder(gitDirectory);
  // Assert non-null value. If the metadata is null, pubspec might be damaged.
  // That's not a thing we can fix here.
  final pubspecVersion = metaProvider.fromDir(appFolder)!.version;
  return pubspecVersion;
}
