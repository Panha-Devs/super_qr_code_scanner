#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

const String packageName = 'super_qr_code_scanner';

void main() async {
  print('🔧 Cleaning Android .cxx folder...');

  final pluginDir = findPackageRoot(packageName);
  print('📁 Plugin directory: ${pluginDir.path}');
  final cxxDir = Directory(path.join(pluginDir.path, 'android', '.cxx'));
  print('🔍 Looking for .cxx folder at: ${cxxDir.path}');

  if (await cxxDir.exists()) {
    await cxxDir.delete(recursive: true);
    print('✅ .cxx folder deleted successfully.');
  } else {
    print('ℹ️ .cxx folder not found or already clean.');
  }

  print('🎉 Clean complete. You can now rebuild your Flutter app.');
}

Directory findPackageRoot(String packageName) {
  final configFile = File('.dart_tool/package_config.json');
  if (!configFile.existsSync()) {
    throw Exception('package_config.json not found. Run dart pub get first.');
  }
  final json = jsonDecode(configFile.readAsStringSync());
  final packages = json['packages'] as List;
  final pkg = packages.firstWhere(
    (p) => p['name'] == packageName,
    orElse: () => throw Exception('Package $packageName not found'),
  );
  final rootUri = pkg['rootUri'] as String;
  final packageConfigDir = configFile.parent; // .dart_tool
  Directory dir;

  if (rootUri.startsWith('file://')) {
    print('📦 Detected absolute rootUri: $rootUri for published package.');
    // Absolute URI - convert to file path
    final uri = Uri.parse(rootUri);
    dir = Directory(uri.toFilePath());
  } else {
    print('🏠 Detected relative rootUri: $rootUri for development path.');
    // Relative URI - resolve relative to .dart_tool
    dir = Directory(path.normalize(path.join(packageConfigDir.path, rootUri)));
  }

  if (!dir.existsSync()) {
    throw Exception('Resolved package root does not exist: ${dir.path}');
  }
  return dir;
}
