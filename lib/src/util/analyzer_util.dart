// SPDX-License-Identifier: BSD-3-Clause
/// Utility file for working with analyzer and some filesystem concepts.

import 'dart:async';
import 'dart:io' as io;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart' as fs;
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:dartdoc/dartdoc.dart';
import 'package:path/path.dart' as path;

import 'package:publish_docs/src/private/assets_layers.dart';
import 'package:publish_docs/src/private/mime_type.dart';

/// A modified copy of [pubPackageMetaProvider].
Future<PackageMetaProvider> obtainPackageMetaProvider() async {

  final assetsAbsolutePath = absolutePath('doc', 'assets');

  final provider = await obtainOverlayProvider(
      pathForLayers: assetsAbsolutePath,
      layers: [
        assetsAbsolutePath // First entry in this array should always be this
      ] + await publishDocsResourceLayers() // Order by decreasing importance
    );

  final sdkDir = PhysicalResourceProvider.INSTANCE
        .getFile(absolutePath(io.Platform.resolvedExecutable))
        .parent
        .parent;

  return PackageMetaProvider(
    PubPackageMeta.fromElement,
    PubPackageMeta.fromFilename,
    PubPackageMeta.fromDir,
    provider,
    sdkDir,
    messageForMissingPackageMeta: messageForMissingMeta);
}

/// Retrieve the absolute, root-anchored, filesystem path to a file/directory.
///
/// This is a simplified alias to [path.absolute], which has more detailed
/// docs.
///
/// See also [PhysicalResourceProvider.pathContext].
String absolutePath(String part1, [String? part2]) {
  return PhysicalResourceProvider.INSTANCE.pathContext.absolute(part1, part2);
}

/// A custom [fs.ResourceProvider] that provides assets with a 'fallback'.
///
/// _This provider will operate relative to the paths you pass in. To make it
/// easier to describe how it works, we use '$YOUR-PACKAGE' to mean
/// the full absolute path to the directory where your `pubspec.yaml` is
/// located._
///
/// If [pathForLayers] is left as the default value of an empty string, then
/// this will act like a normal [PhysicalResourceProvider].
///
/// When `dartdoc` looks for resources whose path starts with
/// '$YOUR-PACKAGE/doc/assets/', we do not want to error out if there's
/// nothing there. Instead we want to look for the same resources within
/// [pathForLayers], using a relative-path conversion.
///
/// ## Example
///
/// Let's say `dartdoc` asks for 'styles.css' and this provider was constructed
/// with
///
/// - [pathForLayers] = '$YOUR-PACKAGE/doc/assets/'
/// - [layers] = '$YOUR-PACKAGE/my/resources/'
///
/// Here's what will happen:
///
/// 1. `dartdoc`'s asks the provider for '$YOUR-PACKAGE/doc/assets/styles.css'.
/// 2. We check for and return that file if it exists.
/// 3. If it doesn't exist, we convert the request into one for
/// '$YOUR-PACKAGE/my/resources/styles.css'
/// 4. We check for and return that file if it exists.
/// 5. If _that_ doesn't exist, then we error out.
///
Future<fs.ResourceProvider> obtainOverlayProvider(
    {String pathForLayers = '', List<String> layers = const []}) async {
  final base = PhysicalResourceProvider.INSTANCE;
  final overlay = OverlayResourceProvider(base);
  // NB: we cannot use a 'List.forEach' call here, as that makes dart run the
  // body of the loop for as many elements as it can in parallel. And that
  // breaks the 'overlay.hasOverlay' check seen inside _registerElement.
  await Future.forEach(layers, (String layer) async {
    await _registerElementsInLayer(base, pathForLayers, overlay, layer,);
  });

  return overlay;
}

/// Either register or ignore every file in the [layer] directory.
Future<void> _registerElementsInLayer(fs.ResourceProvider base,
    String pathForLayers, OverlayResourceProvider overlay,
    String layer,) async {
  base.getFolder(layer).getChildren().forEach((element) async {
    await _registerElement(element, pathForLayers, overlay, layer);
  });
}

/// Either [register][OverlayResourceProvider.setOverlay] or ignore [element].
///
/// If there is a resource with the same basename as 'element' in [overlay],
/// this method does nothing. Otherwise, we'll try to figure out what kind of
/// file it is and (if it _is_ a file and we have a valid [DocsMimeType]) add
/// an entry for it into [overlay].
///
/// This method does _not_ replace existing overlays. Be careful about execution
/// order, especially when calling this from an async method.
Future<void> _registerElement(fs.Resource element, String pathForLayers,
    OverlayResourceProvider overlay, String layer,) async {
  final filename = path.basename(element.path);
  final pathForCaller = absolutePath(pathForLayers, filename);

  if (overlay.hasOverlay(pathForCaller)) {
    // Already found in a prior layer; we can go on to the next element.
  } else if (element is fs.File) {

    final mimeType = await queryMimeType(element);

    if (mimeType == null) {
      // Can't figure out what kind of file $filename is. Skip it.
    } else {
      overlay.setOverlay(
        pathForCaller,
        content: mimeType.readAsStringSync(element),
        modificationStamp: element.modificationStamp,
      );
    }
  } else {
    print('Ignoring detected Resource "$filename" in $layer.');
  }
}



/// A modified copy of [PubPackageMeta.messageForMissingPackageMeta].
///
/// This message returned here has more line breaks, and refers to our package
/// by name.
String messageForMissingMeta(LibraryElement library, DartdocOptionContext context) {
  final libraryString = library.librarySource.fullName;
  const ourName = 'publish_docs';
  final dartOrFlutter = context.flutterRoot == null ? 'dart' : 'flutter';
  return '''
Unknown package for library: $libraryString.  Consider running

`$dartOrFlutter pub get`

to fix that. If you are using `$ourName` as a global package, try running

`$dartOrFlutter pub global deactivate $ourName`
and then
`$dartOrFlutter pub global activate $ourName`

to forcibly rebuild the pub cache.

Also, be sure that `$dartOrFlutter analyze` completes without errors.''';
}
