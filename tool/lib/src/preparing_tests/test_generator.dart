import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:fast_flutter_driver_tool/src/preparing_tests/file_system.dart';
import 'package:path/path.dart' as p;

const aggregatedTestFile = 'generic_test.dart';
const setupMainFile = 'generic.dart';

Future<String> aggregatedTest(String directoryPath, Logger logger) async {
  final setupFile = Directory.current.findOrNull(
    setupMainFile,
    recursive: true,
  );
  if (setupFile == null) {
    return null;
  }

  final genericTestFile =
      File(platformPath(p.join(p.dirname(setupFile), aggregatedTestFile)));
  if (!genericTestFile.existsSync()) {
    genericTestFile.createSync();
  }
  logger?.trace('Generating test file');
  await _generateTestFile(genericTestFile, Directory(directoryPath));
  logger?.trace('Done generating test file');

  return genericTestFile.path;
}

Future<void> _generateTestFile(File genericTestFile, Directory testDir) {
  final testFiles = testDir
      .listSync(recursive: true)
      .where((file) => file.path.endsWith('_test.dart'))
      .where((file) => !file.path.endsWith(aggregatedTestFile))
      .map((file) => file.path)
      .toList(growable: false);
  return _writeGeneratedTest(testFiles, genericTestFile);
}

Future<void> _writeGeneratedTest(List<String> testFiles, File test) async {
  final file = test.openWrite()
    ..writeln('// ignore_for_file: directives_ordering')
    ..writeln(
      '/// This file is autogenerated and should not be committed to source control',
    )
    ..writeln('');
  for (final test in testFiles) {
    file.writeln(
        "import '../../${test.replaceAll(r'\', '/')}' as ${_importName(test)};");
  }
  file..writeln('')..writeln('void main(List<String> args) {');
  for (final test in testFiles) {
    file.writeln('  ${_importName(test)}.main(args);');
  }
  file.writeln('}');
  await file.close();
}

String _importName(String path) => path
    .replaceAll('/', '_')
    .replaceAll(r'\', '_')
    .replaceAll('_test.dart', '');
