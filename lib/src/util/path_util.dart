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

/// Check for a couple of important things, and return false iff they're wrong.
///
/// Right now, all we care about is whether we still have the 'bin' directory
/// where we store programs like this one. If it's missing, we're probably in
/// the wrong project or on the wrong branch.
Future<void> sanityCheck(Directory binDirectory) {
  // Make sure this is the right repository
  return binDirectory.exists().then((doesExist) async {
    if (!doesExist || binDirectory.listSync().isEmpty) {
      throw UnsupportedError(
        'You have to run this from the root directory of'
        " our project - otherwise the file operations won't work correctly.",
      );
    }
  });
}
