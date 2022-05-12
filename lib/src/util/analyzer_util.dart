// SPDX-License-Identifier: BSD-3-Clause
/// Utility file for working with analyzer and some filesystem concepts.

import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:dartdoc/dartdoc.dart';

/// A modified copy of [pubPackageMetaProvider].
final PackageMetaProvider overlayPackageMetaProvider = PackageMetaProvider(
    PubPackageMeta.fromElement,
    PubPackageMeta.fromFilename,
    PubPackageMeta.fromDir,
    PhysicalResourceProvider.INSTANCE,
    PhysicalResourceProvider.INSTANCE
        .getFile(PhysicalResourceProvider.INSTANCE.pathContext
            .absolute(Platform.resolvedExecutable))
        .parent
        .parent,
    messageForMissingPackageMeta: messageForMissingMeta);

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