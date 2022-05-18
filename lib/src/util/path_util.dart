// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';

/// Retrieve the absolute, root-anchored, filesystem path to a file/directory.
///
/// This is a simplified alias to [path.absolute], which has more detailed
/// docs.
///
/// See also [PhysicalResourceProvider.pathContext].
String absolutePath(String part1, [String? part2]) {
  return PhysicalResourceProvider.INSTANCE.pathContext.absolute(part1, part2);
}

/// We only run if the host project has created a 'doc/assets/' directory.
///
/// There are about 8 files defined in 'resourceNames' in dartdoc's
/// [html_resources.g.dart](https://github.com/dart-lang/dartdoc/blob/26d38618/lib/src/generator/html_resources.g.dart).
///
/// We will try to load each of those files from the 'docs/assets/' directory.
/// Any that are _not_ present in that directory will instead be loaded from
/// one of our fallback directories.
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
