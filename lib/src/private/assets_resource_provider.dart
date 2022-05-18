// SPDX-License-Identifier: BSD-3-Clause

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as path;

import 'package:publish_docs/src/private/assets_file_system.dart';
import 'package:publish_docs/src/private/mime_type.dart';
import 'package:publish_docs/src/util/path_util.dart';

/// An [AssetsResourceProvider] that can proxy multiple directories as one path.
///
/// ## How to use this
///
/// If [pathForLayers] is an empty string, then this will act like a normal
/// [PhysicalResourceProvider].
///
/// If it _isn't_ an empty string, then this will make sure that every file in
/// [layers] appears to also be within [pathForLayers]. This way we can make
/// sure that APIs like
/// [dartdoc's _copyResources()](https://github.com/dart-lang/dartdoc/blob/26d38618cc245d49/lib/src/generator/html_generator.dart#L62)
/// don't crash if an important file is missing from your assets directory.
///
/// ## How it works
///
/// _In this doc comment, '$YOUR-PACKAGE' means the full absolute path to the
/// directory where your `lib/` and `pubspec.yaml` are located._
///
/// We read files into memory as lists of bytes - that means a couple calls to
/// [File.readAsBytesSync]. Every file in the first layer gets recorded as an
/// overlay. Then, when we look at the second layer, we skip files whose names
/// we've already seen. We do record files with new filenames, and then go onto
/// the next layer.
///
/// ## Example
///
/// Let's say `dartdoc` asks for 'styles.css' and this provider was constructed
/// with
///
/// - [pathForLayers] = '$YOUR-PACKAGE/doc/assets/'
/// - [layers] = '$YOUR-PACKAGE/doc/assets/', '$YOUR-PACKAGE/my/resources/'
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
Future<ResourceProvider> obtainAssetsProvider(
    {String pathForLayers = '', List<String> layers = const []}) async {
  final base = PhysicalResourceProvider.INSTANCE;
  final overlay = AssetsResourceProvider(base);
  // NB: we cannot use a 'List.forEach' call here, as that makes dart run the
  // body of the loop for as many elements as it can in parallel. And that
  // breaks the 'overlay.hasOverlay' check seen inside _registerElement.
  await Future.forEach(layers, (String layer) async {
    await _registerElementsInLayer(base, pathForLayers, overlay, layer,);
  });

  return overlay;
}

/// Either register or ignore every file in the [layer] directory.
Future<void> _registerElementsInLayer(ResourceProvider base,
    String pathForLayers, AssetsResourceProvider overlay,
    String layer,) async {
  base.getFolder(layer).getChildren().forEach((element) async {
    await _registerElement(element, pathForLayers, overlay, layer);
  });
}

/// Either [register][AssetsResourceProvider.setOverlay] or ignore [element].
///
/// If there is a resource with the same basename as 'element' in [overlay],
/// this method does nothing. Otherwise, we'll try to figure out what kind of
/// file it is and (if it _is_ a file and we have a valid [DocsMimeType]) add
/// an entry for it into [overlay].
///
/// This method does _not_ replace existing overlays. Be careful about execution
/// order, especially when calling this from an async method.
Future<void> _registerElement(Resource element, String pathForLayers,
    AssetsResourceProvider overlay, String layer,) async {
  final filename = path.basename(element.path);
  final pathForCaller = absolutePath(pathForLayers, filename);

  if (overlay.hasOverlay(pathForCaller)) {
    // Already found in a prior layer; we can go on to the next element.
  } else if (element is File) {

    final mimeType = await queryMimeType(element);

    if (mimeType == null) {
      // Can't figure out what kind of file $filename is. Skip it.
    } else {
      overlay.setOverlay(
        pathForCaller,
        bytes: mimeType.readAsBytesSync(element),
        modificationStamp: element.modificationStamp,
      );
    }
  } else {
    print('Ignoring detected Resource "$filename" in $layer.');
  }
}
