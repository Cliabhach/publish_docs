// ignore_for_file: prefer_const_constructors, directives_ordering
import 'dart:io';

import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

/// Append a couple of path segments to some [base].
Directory append(
  Directory base,
  String part1, [
  String? part2,
  String? part3,
  String? part4,
  String? part5,
  String? part6,
]) {
  return Directory(path.absolute(
    base.path,
    part1,
    part2,
    part3,
    part4,
    part5,
    part6,
  ));
}

/// The default logic in [PhysicalResourceProvider] is incredibly basic.
///
/// This method lets you write tests that make sense.
String resourcePath(String testName) {
  final context = PhysicalResourceProvider.INSTANCE.pathContext;

  final presentDirectory = Directory(context.current);

  final asUri = Uri.parse(testName);
  expect(asUri.scheme, isEmpty, reason: 'We only support simple directory '
      'paths at this time.');

  final parent = append(presentDirectory, 'test', 'resources');
  expect(parent.existsSync(), isTrue, reason: 'Make sure to add a directory '
      'for test resources!');

  return path.absolute(parent.path, asUri.path);
}