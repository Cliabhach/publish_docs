// SPDX-License-Identifier: BSD-3-Clause

import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';

/// This is an unusual [CodePage].
///
/// You can use this for 1:1 conversion between bytes and [Runes]. Strings made
/// under this encoding might not be readable, and there is no guarantee that
/// dart debuggers will be able to work with them correctly. Be careful.
Encoding binaryEncoding = CodePage('binary', _concatenate128Digits());

String _concatenate128Digits() {
  final basis = List.generate(256, (index) => index);
  final as8 = Uint8List.fromList(basis);

  return String.fromCharCodes(as8);
}
