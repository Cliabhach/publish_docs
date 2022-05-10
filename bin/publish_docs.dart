// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:publish_docs/publish_docs.dart';

/// Entrypoint to the 'publish_docs' library.
///
/// This is what command-line callers like `dart pub run publish_docs` call.
Future<void> main(List<String> arguments) async {
  final assetsAbsolutePath = absolutePath('doc', 'assets');

  _checkForAssetsDirectory(assetsAbsolutePath);

  await generateDocs(arguments);
}

/// We only run if the host project has created a 'doc/assets/' directory.
void _checkForAssetsDirectory(String assetsAbsolutePath) {
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
