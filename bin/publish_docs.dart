// SPDX-License-Identifier: BSD-3-Clause

import 'package:publish_docs/publish_docs.dart';

/// Entrypoint to the 'publish_docs' library.
///
/// This is what command-line callers like `dart pub run publish_docs` call.
Future<void> main(List<String> arguments) async {
  final assetsAbsolutePath = absolutePath('doc', 'assets');

  checkForAssetsDirectory(assetsAbsolutePath);

  print(r'''
Publish docs that match your project's theme and style.

To just generate the dartdoc output, run
$ dart pub run publish_docs:generate
or
$ flutter pub run publish_docs:generate

To generate new docs and then apply them to your gh-pages branch, run
$ dart pub run publish_docs:commit
or
$ flutter pub run publish_docs:commit
''');

  await generateDocs(arguments);
}
