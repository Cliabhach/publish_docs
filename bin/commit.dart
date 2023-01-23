// SPDX-License-Identifier: BSD-3-Clause

import 'package:publish_docs/publish_docs.dart';
import 'package:publish_docs/src/private/assets_resource_provider.dart';

/// Entrypoint to the 'publish_docs' library.
///
/// Invocation: `dart pub run publish_docs:commit`
///
/// Further details: [updateGitHubDocs], [InPlaceBranchUpdate],
/// [obtainAssetsProvider].
Future<void> main(List<String> arguments) async {
  final assetsAbsolutePath = assetsPath();

  checkForAssetsDirectory(assetsAbsolutePath);

  await updateGitHubDocs(arguments);
}
