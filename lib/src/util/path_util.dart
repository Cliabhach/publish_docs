// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

/// Find an options file on disk, if possible.
///
/// We only care about the options for this library.
File absoluteOptionsFilePath({String optionsFileDir = '/'}) {
  final provider = PhysicalResourceProvider.INSTANCE;
  const name = 'publish_docs_options.yaml';

  final String optionsFilePath;
  if (optionsFileDir == '/') {
    optionsFilePath = provider.pathContext.absolute(name);
  } else {
    optionsFilePath = provider.pathContext.absolute(optionsFileDir, name);
  }

  // Do we want this for diagnostic reasons?
  //print("Found file $optionsFilePath");

  return provider.getFile(optionsFilePath);
}

/// Return the absolute path to the current project's 'assets' directory.
///
/// That directory is where project-specific favicons and styles and so forth
/// should be defined.
///
/// Note that this function is typically called _very_ early on, as part of the
/// startup checks ([checkForAssetsDirectory] in particular). The default return
/// value is '/path/to/project/doc/assets/'.
///
/// See also [absolutePath].
String assetsPath() {
  return absolutePath('doc', 'assets');
}

/// Retrieve the absolute, root-anchored, filesystem path to a file/directory.
///
/// This is a simplified alias to
/// [path's Context.absolute](https://pub.dev/documentation/path/1.8.2/path/Context/absolute.html),
/// which has more detailed docs.
///
/// See also [PhysicalResourceProvider.pathContext].
String absolutePath(String part1, [String? part2]) {
  return PhysicalResourceProvider.INSTANCE.pathContext.absolute(part1, part2);
}

/// We only run if the host project has created an assets directory.
///
/// There are about 8 files defined in 'resourceNames' in dartdoc's
/// [html_resources.g.dart](https://github.com/dart-lang/dartdoc/blob/26d38618/lib/src/generator/html_resources.g.dart).
///
/// We will try to load each of those files from the [assetsAbsolutePath]
/// directory. Any that are _not_ present in that directory will instead be
/// loaded from one of our fallback directories.
///
/// Callers are asked to only use [assetsPath] as the parameter to this
/// function. It is possible that the explicit parameter will be removed in a
/// future release of this library.
///
/// See `lib/src/private/assets_layers.dart` for the exact paths to our
/// fallback directories.
void checkForAssetsDirectory(String assetsAbsolutePath) {
  final assetsDirectory = Directory(assetsAbsolutePath);

  final assetsDirectoryUri = assetsDirectory.uri;

  if (assetsDirectory.existsSync()) {
    print('Using assets from $assetsDirectoryUri.');
  } else {
    throw UnsupportedError("""
Please make sure to create a 'doc/assets/' directory within your project source.
We expected to see one at $assetsDirectoryUri
""");
  }
}
