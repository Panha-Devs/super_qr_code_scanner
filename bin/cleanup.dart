#!/usr/bin/env dart

import 'dart:io';
import 'package:path/path.dart' as path;
import 'utils.dart';

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
