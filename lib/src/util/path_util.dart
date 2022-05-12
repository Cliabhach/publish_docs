// SPDX-License-Identifier: BSD-3-Clause

import 'dart:io';

/// Check for a couple of important things, and return false iff they're wrong.
///
/// Right now, all we care about is whether we still have the 'bin' directory
/// where we store programs like this one. If it's missing, we're probably in
/// the wrong project or on the wrong branch.
Future<void> sanityCheck(Directory binDirectory) {
  // Make sure this is the right repository
  return binDirectory.exists().then((doesExist) async {
    if (!doesExist || binDirectory.listSync().isEmpty) {
      throw UnsupportedError(
        'You have to run this from the root directory of'
        " our project - otherwise the file operations won't work correctly.",
      );
    }
  });
}
