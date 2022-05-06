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
/// If a resource exists at a 'doc/assets/' path in your project, then we
/// return that. Else, we look in the following places, in order:
/// 1. the 'lib/resources/' directory of this package
ResourceProvider obtainAssetsOverlayProvider() {
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