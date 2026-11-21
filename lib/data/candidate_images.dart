import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

class CandidateImages {
  static const maxBytes = 2 * 1024 * 1024;

  static Future<String?> pickAndUpload(int candidateId) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return null;
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null) return 'Could not read that file.';
    if (bytes.length > maxBytes) return 'The image must be 2 MB or smaller.';

    try {
      final req = http.MultipartRequest('POST',
          Uri.parse('${Api.baseUrl}/api/admin/candidates/$candidateId/image'))
        ..headers['Authorization'] = 'Bearer ${Api.token}'
        ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: file.name));
      final res = await http.Response.fromStream(
          await req.send().timeout(const Duration(seconds: 30)));
      if (res.statusCode >= 200 && res.statusCode < 300) return null;
      if (res.statusCode == 401)
        return 'Your session expired. Please sign in again.';
      final m = RegExp(r'"detail"\s*:\s*"([^"]*)"').firstMatch(res.body);
      return m?.group(1) ?? 'Upload failed (${res.statusCode}).';
    } catch (_) {
      return 'Cannot reach the server. Check your connection and try again.';
    }
  }

  static Future<String?> remove(int candidateId) async {
    try {
      await Api.delete('/api/admin/candidates/$candidateId/image');
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
