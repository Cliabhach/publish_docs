// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';
import 'dart:isolate';

import 'package:analyzer/file_system/file_system.dart';
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

/// Create a list of directories where we might find assets.
///
/// We currently only return one item in that list, but in future we'd like to
/// support themes and that would mean returning a list with both a 'common'
/// directory and a 'theme' directory.
///
/// Delegates some of the work to [_uriAsPath].
Future<List<String>> publishDocsResourceLayers() async {
  final provider = PhysicalResourceProvider.INSTANCE;
  const ourPackage = 'package:publish_docs';
  final base = _uriAsPath('$ourPackage/resources/dartdoc-5.1.0', provider);
  return [ await base ];
}

/// Find the [Folder] on disk that represents a given `package:` [uri].
///
/// Method inspired by some of the private 'ResourceLoader' code in `dartdoc`.
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
