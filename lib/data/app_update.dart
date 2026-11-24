import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'api.dart';

class AppUpdateInfo {
  final String version;
  final int build;
  final String url;
  final String sha256;
  final int size;
  final String notes;
  final bool mandatory;
  const AppUpdateInfo(this.version, this.build, this.url, this.sha256,
      this.size, this.notes, this.mandatory);
}

class InstallPermissionNeeded implements Exception {
  const InstallPermissionNeeded();
}

class AppUpdater {
  static const _channel = MethodChannel('evoter/update');

  static String? get platform {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    return null;
  }

  static Future<PackageInfo> current() => PackageInfo.fromPlatform();

  static Future<AppUpdateInfo?> check() async {
    final p = platform;
    if (p == null) return null;
    try {
      final info = await current();
      final build = int.tryParse(info.buildNumber) ?? 0;
      final j = await Api.get('/api/app/update?platform=$p&build=$build');
      if (j == null || j['available'] != true) return null;
      return AppUpdateInfo(
        j['version'] ?? '',
        j['build'] ?? 0,
        j['url'],
        (j['sha256'] ?? '').toString().toLowerCase(),
        j['size'] ?? 0,
        j['notes'] ?? '',
        j['mandatory'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<File> download(AppUpdateInfo info,
      void Function(int received, int total) onProgress) async {
    final dir = Platform.isAndroid
        ? Directory(await _channel.invokeMethod<String>('updateDir') ?? '')
        : Directory(
            '${Directory.systemTemp.path}${Platform.pathSeparator}sti_evoter_update');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final name = Uri.parse(info.url).pathSegments.last;
    final file = File('${dir.path}${Platform.pathSeparator}$name');

    final client = http.Client();
    try {
      final res = await client.send(http.Request('GET', Uri.parse(info.url)));
      if (res.statusCode != 200) {
        throw ApiException(res.statusCode,
            'The update could not be downloaded (${res.statusCode}).');
      }
      final total = res.contentLength ?? info.size;
      final digest = _DigestSink();
      final hasher = sha256.startChunkedConversion(digest);
      final sink = file.openWrite();
      var received = 0;
      await for (final chunk in res.stream) {
        sink.add(chunk);
        hasher.add(chunk);
        received += chunk.length;
        onProgress(received, total);
      }
      await sink.close();
      hasher.close();
      if (info.sha256.isNotEmpty && digest.value.toString() != info.sha256) {
        file.deleteSync();
        throw ApiException(
            0, 'The downloaded update was damaged. Please try again.');
      }
      return file;
    } on SocketException {
      throw ApiException(
          0, 'Cannot reach the server. Check your connection and try again.');
    } finally {
      client.close();
    }
  }

  static Future<void> install(File file) async {
    if (Platform.isAndroid) {
      final ok = await _channel.invokeMethod<bool>('canInstall') ?? false;
      if (!ok) {
        await _channel.invokeMethod('openInstallSettings');
        throw const InstallPermissionNeeded();
      }
      await _channel.invokeMethod('installApk', {'path': file.path});
      return;
    }
    if (Platform.isWindows) {
      await _installWindows(file);
    }
  }

  static Future<void> _installWindows(File zip) async {
    String q(String s) => "'${s.replaceAll("'", "''")}'";
    final exe = Platform.resolvedExecutable;
    final appDir = File(exe).parent.path;
    final staging = '${zip.parent.path}\\staging';
    final script = File('${zip.parent.path}\\apply_update.ps1');
    script.writeAsStringSync('''
\$ErrorActionPreference = 'Stop'
Wait-Process -Id $pid -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500
if (Test-Path ${q(staging)}) { Remove-Item ${q(staging)} -Recurse -Force }
Expand-Archive -Path ${q(zip.path)} -DestinationPath ${q(staging)} -Force
for (\$i = 0; \$i -lt 10; \$i++) {
  try { Copy-Item -Path (Join-Path ${q(staging)} '*') -Destination ${q(appDir)} -Recurse -Force; break }
  catch { Start-Sleep -Seconds 1 }
}
Start-Process -FilePath ${q(exe)}
''');
    await Process.start(
      'powershell',
      [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-WindowStyle',
        'Hidden',
        '-File',
        script.path,
      ],
      mode: ProcessStartMode.detached,
    );
    exit(0);
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest value;
  @override
  void add(Digest data) => value = data;
  @override
  void close() {}
}
