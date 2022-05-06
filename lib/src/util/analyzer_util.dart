// SPDX-License-Identifier: BSD-3-Clause
/// Utility file for working with analyzer and some filesystem concepts.

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:dartdoc/dartdoc.dart';

/// A modified copy of [pubPackageMetaProvider].
final PackageMetaProvider overlayPackageMetaProvider = PackageMetaProvider(
    PubPackageMeta.fromElement,
    PubPackageMeta.fromFilename,
    PubPackageMeta.fromDir,
    obtainAssetsOverlayProvider(),
    PhysicalResourceProvider.INSTANCE
        .getFile(PhysicalResourceProvider.INSTANCE.pathContext
            .absolute(Platform.resolvedExecutable))
        .parent
        .parent,
    messageForMissingPackageMeta: messageForMissingMeta);

/// A custom [ResourceProvider] that provides assets with a sort of 'fallback'.
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
ResourceProvider obtainAssetsOverlayProvider(
    {String pathForLayers = '', List<String> layers = const []}) {
  // TODO(Cliabhach): figure out how to future-proof for varying themes
  final base = PhysicalResourceProvider.INSTANCE;
  final overlay = OverlayResourceProvider(base);

  return overlay;
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