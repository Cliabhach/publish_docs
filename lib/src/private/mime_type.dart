// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart' as fs;
import 'package:mime/mime.dart';
import 'package:publish_docs/src/util/binary_code_page.dart';

/// Representation of a mime type/MIME-type/mimetype.
///
/// Beyond the expected 'type' property, this also contains a quick method
/// to load the content of [fs.File]s of the given type into a [String].
class DocsMimeType {
  /// Create a new [DocsMimeType] with the specified value.
  DocsMimeType(this.type);

  /// A standard mime type in the 'type/
  String type;

  /// Load the contents of [element] into a [String].
  ///
  /// We will automatically detect binary files and use [binaryEncoding] for
  /// those. The name of this method is inspired by [fs.File.readAsStringSync]
  /// and [io.File.readAsStringSync].
  ///
  /// May throw an exception if something goes wrong during I/O.
  String readAsStringSync(fs.File element) {
    String contents;
    if (type.startsWith('image') && !type.contains('xml')) {
      // It's a binary file. We need to use a custom encoding here.
      final normalFile = io.File(element.path);
      contents = normalFile.readAsStringSync(encoding: binaryEncoding);
    } else {
      contents = element.readAsStringSync();
    }
    return contents;
  }
}

/// Figure out what mime type best reflects the given file.
///
/// Note that the standard library's [lookupMimeType] is woefully incomplete,
/// so we try to request a type from the host machine via `xdg-mime` first. If
/// the host does not have `xdg-mime` configured, then we fall back to the
/// library.
Future<DocsMimeType?> queryMimeType(fs.File file) async {
  final typeAsString = await _queryMimeType(file);

  if (typeAsString != null) {
    return DocsMimeType(typeAsString);
  } else {
    return null;
  }
}

/// Implementation of [queryMimeType]
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