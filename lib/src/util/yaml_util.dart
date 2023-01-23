// SPDX-License-Identifier: BSD-3-Clause

import 'package:analyzer/file_system/file_system.dart';
import 'package:yaml/yaml.dart';

/// Helper class for dealing with YAML/.yml files.
///
/// Use this for YAML files which other libraries have not parsed - the
/// `dartdoc` library parses `dartdoc_options.yaml` for us, for example.
class YamlUtil {
  // May be worth preventing multiple prefetches. For now the tests are easier
  // if we don't enforce that.
  static YamlMap _foundOptions = YamlMap();

  /// Parse and load the options for `publish_docs`.
  ///
  /// Callers should use the `path_util` function called
  /// `absoluteOptionsFilePath` to find the optionsFile.
  static void prefetchPublishDocsOptions(File optionsFile) {
    final utility = YamlUtil();

    if (optionsFile.exists && optionsFile.lengthSync > 0) {
      utility._parseOptions(optionsFile);
      // Do we want to interpret paths in the options as relative to
      // optionsFile.parent?
    }
  }

  /// Retrieve the options for `publish_docs`
  static YamlMap publishDocsOptions() {
    return _foundOptions;
  }

  void _parseOptions(File optionsFile) {
    final optionsText = optionsFile.readAsStringSync();
    final parsed = loadYaml(optionsText) as YamlMap;
    final dynamic found = parsed['publish'];
    if (found is! YamlMap) {
      throw Exception(
          'Publish block of the options file $optionsFile was not a map,'
          ' but a ${found.runtimeType}');
    }
    _foundOptions = found;
  }
}
