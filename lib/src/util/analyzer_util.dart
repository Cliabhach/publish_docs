// SPDX-License-Identifier: BSD-3-Clause
/// Utility file for working with analyzer and some filesystem concepts.

import 'dart:io' as io;
import 'dart:isolate';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart' as fs;
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:dartdoc/dartdoc.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

import 'package:publish_docs/src/util/binary_code_page.dart';

/// A modified copy of [pubPackageMetaProvider].
Future<PackageMetaProvider> overlayPackageMetaProvider() async {

  final provider = obtainAssetsOverlayProvider(
      pathForLayers: path.absolute('doc', 'assets'),
      layers: await _publishDocsResourceLayers() + [
      ]
    );

  final sdkDir = PhysicalResourceProvider.INSTANCE
        .getFile(PhysicalResourceProvider.INSTANCE.pathContext
            .absolute(io.Platform.resolvedExecutable))
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

/// Method inspired by some of the private 'ResourceLoader' code in `dartdoc`.
///
/// Delegates some of the work to [_uriAsPath].
Future<List<String>> _publishDocsResourceLayers() async {
  final provider = PhysicalResourceProvider.INSTANCE;
  const ourPackage = 'package:publish_docs';
  final base = _uriAsPath('$ourPackage/resources/dartdoc-5.1.0', provider);
  return [ await base ];
}

/// Find the [fs.Folder] on disk that represents a given `package:` [uri].
Future<String> _uriAsPath(String uri, fs.ResourceProvider provider) async {
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
fs.ResourceProvider obtainAssetsOverlayProvider(
    {String pathForLayers = '', List<String> layers = const []}) {
  // TODO(Cliabhach): figure out how to future-proof for varying themes
  final base = PhysicalResourceProvider.INSTANCE;
  final overlay = OverlayResourceProvider(base);
  for (final layer in layers) {
    base.getFolder(layer).getChildren().forEach(
        (element) => _registerElement(element, pathForLayers, overlay, layer),
    );
  }

  return overlay;
}

Future<void> _registerElement(fs.Resource element, String pathForLayers,
    OverlayResourceProvider overlay, String layer,) async {
  final filename = path.basename(element.path);
  final pathForCaller = path.absolute(pathForLayers, filename);

  if (overlay.hasOverlay(pathForCaller)) {
    // Already found in a prior layer; we can go on to the next element.
  } else if (element is fs.File) {

    final mimeType = await _queryMimeType(element);

    if (mimeType == null) {
      // Can't figure out what kind of file $filename is. Skip it.
    } else {
      if (mimeType.startsWith('image') && !mimeType.contains('xml')) {
        // It's a binary file. We need to use a custom encoding here.
        final normalFile = io.File(element.path);
        final contents = normalFile.readAsStringSync(encoding: binaryEncoding);
        overlay.setOverlay(
          pathForCaller,
          content: contents,
          modificationStamp: element.modificationStamp
        );
      } else {
        overlay.setOverlay(
          pathForCaller,
          content: element.readAsStringSync(),
          modificationStamp: element.modificationStamp,
        );
      }
    }
  } else {
    print('Ignoring detected Resource "$filename" in $layer.');
  }
}

/// Figure out what mime type best reflects the given file.
///
/// Note that the standard library's [lookupMimeType] is woefully incomplete,
/// so we try to request a type from the host machine via `xdg-mime` first. If
/// the host does not have `xdg-mime` configured, then we fall back to the
/// library.
Future<String?> _queryMimeType(fs.File file) async {
  String? xdgMimeType;

  if (io.Platform.isLinux || io.Platform.isMacOS || io.Platform.isAndroid) {
    // Try to use the host's 'xdg-mime' tool
    final result = io.Process.runSync('xdg-mime', [
      'query',
      'filetype',
      file.path
    ]);

    if (result.exitCode == 0) {
      xdgMimeType = result.stdout as String;
    }
  }

  if (xdgMimeType != null) {
    return xdgMimeType;
  } else {
    // 'xdg-mime' was unavailable or could not identify the file
    final normalFile = io.File(file.path);
    final firstFewBytes = await normalFile
        .openRead(0, 12) // No need to read more bytes. Library only checks 12.
        .reduce((previous, element) => previous + element);

    final type = lookupMimeType(file.path, headerBytes: firstFewBytes);

    if (type == null) {
      print('> Got bytes $firstFewBytes.');
    }

    return type;
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
