#!/usr/bin/env dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';

const String repoOwner = 'Panha-Devs';
const String repoName = 'super_qr_code_scanner_artifacts';
const String releaseTag = 'v1.0.0';
const String packageName = 'super_qr_code_scanner';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'platforms',
      abbr: 'p',
      help:
          'Comma-separated list of platforms: android,ios,macos,linux,windows',
      defaultsTo: 'android,ios',
    );

  final results = parser.parse(args);
  final platforms =
      results['platforms'].split(',').map((p) => p.trim()).toList();

  print('Setting up Super QR Code Scanner for platforms: $platforms');

  final pluginDir = findPackageRoot(packageName);
  final openCvLibsDir =
      Directory(path.join(pluginDir.path, 'src', 'opencv', 'libs'));
  final zXingLibsDir =
      Directory(path.join(pluginDir.path, 'src', 'zxing', 'libs'));

  await openCvLibsDir.create(recursive: true);
  await zXingLibsDir.create(recursive: true);

  for (final platform in platforms) {
    final abis = getABIs(platform);
    for (final abi in abis) {
      await downloadAndExtract('opencv', platform, abi, openCvLibsDir);
      await downloadAndExtract('zxing', platform, abi, zXingLibsDir);
    }
  }

  print('Setup complete!');
}

List<String> getABIs(String platform) {
  switch (platform) {
    case 'android':
      return ['arm64-v8a', 'armeabi-v7a'];
    case 'ios':
      return ['arm64', 'x86_64'];
    case 'macos':
      return ['arm64', 'x86_64'];
    case 'linux':
      return ['x64'];
    case 'windows':
      return ['x64'];
    default:
      throw ArgumentError('Unknown platform: $platform');
  }
}

Future<void> downloadAndExtract(
  String lib,
  String platform,
  String abi,
  Directory libsDir,
) async {
  final assetName = '$lib-$platform-$abi.zip';
  final extractDir = Directory(path.join(libsDir.path, '$platform-$abi'));

  // Remove existing directory to ensure fresh download
  if (await extractDir.exists()) {
    await extractDir.delete(recursive: true);
    print('Removed existing $lib libs for $platform-$abi');
  }

  final url =
      'https://github.com/$repoOwner/$repoName/releases/download/$releaseTag/$assetName';

  print('Downloading $assetName...');

  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception('Failed to download $assetName from $url\n'
        'Status: ${response.statusCode}\n'
        'Make sure the release exists and the repo is public.');
  }

  final archive = ZipDecoder().decodeBytes(response.bodyBytes);
  await extractDir.create(recursive: true);

  for (final file in archive) {
    final filename = file.name;
    if (file.isFile) {
      final data = file.content as List<int>;
      String relativePath = filename;
      // Strip top-level folder if it matches the platform-abi
      final topLevelFolder = '$platform-$abi/';
      if (filename.startsWith(topLevelFolder)) {
        relativePath = filename.substring(topLevelFolder.length);
      }
      final filePath = path.join(extractDir.path, relativePath);
      await Directory(path.dirname(filePath)).create(recursive: true);
      await File(filePath).writeAsBytes(data);
    }
  }

  print('✅ Extracted $assetName to ${extractDir.path}');
}

Directory findPackageRoot(String packageName) {
  // When running from a published package, use the script's location
  final scriptUri = Platform.script;
  final scriptPath = scriptUri.toFilePath();

  // Check if we're running from pub cache (published package)
  if (scriptPath.contains('.pub-cache')) {
    // Navigate up from bin/setup.dart to the package root
    final binDir = Directory(path.dirname(scriptPath));
    final packageRoot = binDir.parent;

    if (!packageRoot.existsSync()) {
      throw Exception('Package root does not exist: ${packageRoot.path}');
    }

    return packageRoot;
  } else if (scriptPath.contains('.dart_tool/pub')) {
    final binDir = Directory(path.dirname(scriptPath));
    final superQrDir = binDir.parent;
    final pubDir = superQrDir.parent;
    final dartToolDir = pubDir.parent;
    final packageRoot = dartToolDir.parent;

    // Verify this is the correct package root
    final pubspec = File(path.join(packageRoot.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      throw Exception('pubspec.yaml not found. Invalid package structure.');
    }

    final content = pubspec.readAsStringSync();
    if (!content.contains('name: $packageName')) {
      throw Exception('Package $packageName not found in resolved directory');
    }

    return packageRoot;
  } else {
    // Running from development directory directly
    final cwd = Directory.current;

    // Look for pubspec.yaml to confirm we're in the right place
    final pubspec = File(path.join(cwd.path, 'pubspec.yaml'));
    if (!pubspec.existsSync()) {
      throw Exception(
          'pubspec.yaml not found in current directory. Please run from the package root.');
    }

    // Verify this is the correct package
    final content = pubspec.readAsStringSync();
    if (!content.contains('name: $packageName')) {
      throw Exception(
          'Current directory does not contain package $packageName');
    }

    return cwd;
  }
}
