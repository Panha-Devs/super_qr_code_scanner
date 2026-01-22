#!/usr/bin/env dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:args/args.dart';

const String repoOwner = 'Panha-Devs';
const String repoName = 'super_qr_code_scanner_artifacts';
const String releaseTag = 'v1.0.0';

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

  final pluginDir = Directory.current;
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

  // Check if already extracted
  if (await extractDir.exists() &&
      (await extractDir.list().toList()).isNotEmpty) {
    print('$lib libs for $platform-$abi already exist, skipping...');
    return;
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
      final filePath = path.join(extractDir.path, filename);
      await File(filePath).writeAsBytes(data);
    }
  }

  print('✅ Extracted $assetName to ${extractDir.path}');
}
