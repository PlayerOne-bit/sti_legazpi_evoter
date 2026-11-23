import 'dart:convert';
import 'dart:io' show File;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme.dart';
import 'api.dart';

class ImportResult {
  final int studentsAdded;
  final int candidatesAdded;
  final List<String> errors;
  const ImportResult(this.studentsAdded, this.candidatesAdded, this.errors);
}

class ExcelIo {
  static Map<String, String> get _auth =>
      {if (Api.token != null) 'Authorization': 'Bearer ${Api.token}'};

  static String _message(http.Response res) {
    try {
      final j = jsonDecode(res.body);
      return (j['detail'] ??
              j['title'] ??
              'Something went wrong (${res.statusCode}).')
          .toString();
    } catch (_) {
      return 'Something went wrong (${res.statusCode}).';
    }
  }

  static Future<Uint8List> _download(String path) async {
    late http.Response res;
    try {
      res = await http
          .get(Uri.parse('${Api.baseUrl}$path'), headers: _auth)
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      throw ApiException(
          0, 'Cannot reach the server. Check your connection and try again.');
    }
    if (res.statusCode != 200)
      throw ApiException(res.statusCode, _message(res));
    return res.bodyBytes;
  }

  static Future<String> save(String path, String fileName) async {
    try {
      final bytes = await _download(path);
      final target = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel file',
        fileName: fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );
      if (kIsWeb) return 'Download started.';
      if (target == null) return 'Save cancelled.';
      final desktop = {
        TargetPlatform.windows,
        TargetPlatform.linux,
        TargetPlatform.macOS,
      }.contains(defaultTargetPlatform);
      if (desktop) await File(target).writeAsBytes(bytes);
      return 'Saved $fileName.';
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'The file could not be saved.';
    }
  }

  static Future<String> saveTemplate() =>
      save('/api/admin/excel/template', 'sti-evoter-template.xlsx');

  static Future<String> saveStudents() =>
      save('/api/admin/students/export', 'sti-evoter-students.xlsx');

  static Future<String> saveVoters(int electionId, String fileName) =>
      save('/api/admin/students/export?electionId=$electionId', fileName);

  static Future<String> saveHistory(int historyId) =>
      save('/api/admin/history/$historyId/export', 'sti-evoter-results.xlsx');

  static Future<String> saveResults(int electionId, String fileName) =>
      save('/api/admin/elections/$electionId/export', fileName);

  static Future<ImportResult?> pickAndImport({int? electionId}) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['xls', 'xlsx'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      return const ImportResult(0, 0, ['The file could not be read.']);
    }

    final uri = Uri.parse(
        '${Api.baseUrl}/api/admin/excel/import${electionId == null ? '' : '?electionId=$electionId'}');
    final req = http.MultipartRequest('POST', uri)
      ..headers.addAll(_auth)
      ..files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: file.name));

    late http.Response res;
    try {
      res = await http.Response.fromStream(
          await req.send().timeout(const Duration(seconds: 120)));
    } catch (_) {
      throw ApiException(
          0, 'Cannot reach the server. Check your connection and try again.');
    }
    if (res.statusCode != 200)
      throw ApiException(res.statusCode, _message(res));

    final j = jsonDecode(res.body);
    return ImportResult(
      j['studentsAdded'] as int,
      j['candidatesAdded'] as int,
      [
        for (final e in j['errors'] as List)
          e['row'] == 0
              ? '${e['sheet']}: ${e['message']}'
              : '${e['sheet']} row ${e['row']}: ${e['message']}',
      ],
    );
  }
}

Future<void> showImportResult(BuildContext context, ImportResult r) {
  const shown = 25;
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Import finished'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${r.studentsAdded} students added'
                  '${r.candidatesAdded > 0 ? ', ${r.candidatesAdded} candidates added' : ''}.'),
              if (r.errors.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('${r.errors.length} rows were skipped:',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                for (final e in r.errors.take(shown))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child:
                        Text(e, style: TextStyle(color: C.muted, fontSize: 12)),
                  ),
                if (r.errors.length > shown)
                  Text('...and ${r.errors.length - shown} more.',
                      style: TextStyle(color: C.muted, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        FilledButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Done')),
      ],
    ),
  );
}
