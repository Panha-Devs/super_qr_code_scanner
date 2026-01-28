#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';

const String repoOwner = 'Panha-Devs';
const String repoName = 'super_qr_code_scanner_artifacts';
const String packageName = 'super_qr_code_scanner';

void main(List<String> args) async {
  final parser = ArgParser()
    ..addOption(
      'platforms',
      abbr: 'p',
      help:
          'Comma-separated list of platforms: android,ios,macos,linux,windows',
      defaultsTo: 'android,ios',
    )
    ..addOption(
      'version',
      abbr: 'v',
      help: 'Release version tag to download artifacts from',
      defaultsTo: 'v1.0.3',
    );

  final results = parser.parse(args);
  final platforms =
      results['platforms'].split(',').map((p) => p.trim()).toList();
  final releaseTag = results['version'] as String;

  print(
    '🚀 Setting up Super QR Code Scanner $releaseTag for platforms: $platforms',
  );

  final pluginDir = findPackageRoot(packageName);
  final openCvLibsDir = Directory(
    path.join(
      pluginDir.path,
      'src',
      'opencv',
      'libs',
    ),
  );
  final zXingLibsDir = Directory(
    path.join(
      pluginDir.path,
      'src',
      'zxing',
      'libs',
    ),
  );

  await openCvLibsDir.create(recursive: true);
  await zXingLibsDir.create(recursive: true);

  for (final platform in platforms) {
    final abis = getABIs(platform);
    for (final abi in abis) {
      await downloadAndExtract(
        'opencv',
        platform,
        abi,
        openCvLibsDir,
        releaseTag,
      );
      await downloadAndExtract(
        'zxing',
        platform,
        abi,
        zXingLibsDir,
        releaseTag,
      );
    }
  }

  print('🎉 Setup abis native libs complete!');
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
  String releaseTag,
) async {
  final assetName = '$lib-$platform-$abi.zip';
  final extractDir = Directory(path.join(libsDir.path, '$platform-$abi'));

  // Remove existing directory to ensure fresh download
  if (await extractDir.exists()) {
    await extractDir.delete(recursive: true);
    print('🗑️ Removed existing $lib libs for $platform-$abi');
  }

  final url =
      'https://github.com/$repoOwner/$repoName/releases/download/$releaseTag/$assetName';

  print('⬇️ Downloading $assetName...');

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

  print('📦 Extracted $assetName to ${extractDir.absolute.path}');
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
