// SPDX-License-Identifier: BSD-3-Clause

import 'package:publish_docs/publish_docs.dart';

/// Entrypoint to the 'publish_docs' library.
///
/// This is what command-line callers like `dart pub run publish_docs` call.
Future<void> main(List<String> arguments) async {
  await generateDocs(arguments);
}