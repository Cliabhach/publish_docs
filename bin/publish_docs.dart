// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

import 'package:publish_docs/publish_docs.dart';
import 'package:publish_docs/src/util/util.dart';

/// Entrypoint to the 'publish_docs' library.
///
/// This is what command-line callers like `dart pub run publish_docs` call.
Future<void> main(List<String> arguments) async {
  final assetsAbsolutePath = absolutePath('doc', 'assets');

  checkForAssetsDirectory(assetsAbsolutePath);

  await generateDocs(arguments);
}
