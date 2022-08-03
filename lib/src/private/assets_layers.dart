// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'dart:isolate';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';

/// Create a list of directories where we might find assets.
///
/// We currently only return two items in that list - a directory with our
/// custom asset fixes and upgrades, and a 'base' directory with a copy of the
/// assets bundled with a specific dartdoc release. In future we'd like to
/// support themes and that would mean returning a list with a 'theme'
/// directory too.
///
/// Delegates some of the work to [_uriAsPath].
Future<List<String>> publishDocsResourceLayers() async {
  final provider = PhysicalResourceProvider.INSTANCE;
  const ourPackage = 'package:publish_docs';
  final fixes = _uriAsPath('$ourPackage/resources/standard-fixes', provider);
  final base = _uriAsPath('$ourPackage/resources/dartdoc-6.0.1', provider);
  return [ await fixes, await base ];
}

/// Find the [Folder] on disk that represents a given `package:` [uri].
///
/// Method inspired by some of the private 'ResourceLoader' code in `dartdoc`
/// [here](https://github.com/dart-lang/dartdoc/blob/26d38618cc245d49/lib/src/generator/resource_loader.dart#L42).
Future<String> _uriAsPath(String uri, ResourceProvider provider) async {
  final resourcesUri = Uri.parse(uri);
  final resolvedUri = await Isolate.resolvePackageUri(resourcesUri);

  if (resolvedUri == null) {
    throw UnsupportedError('The publish_docs package must be present in your '
        "pub-cache in order for it to work properly. We can't load default "
        'resources or assets otherwise.');
  } else {
    return provider.getFolder(resolvedUri.toFilePath()).path;
  }
}
