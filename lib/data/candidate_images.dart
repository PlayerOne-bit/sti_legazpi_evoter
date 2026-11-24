import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../widgets/square_cropper.dart';
import 'api.dart';

class CandidateImages {
  static const maxBytes = 2 * 1024 * 1024;

  static Future<String?> pickAndUpload(BuildContext context, int candidateId) =>
      pickAndUploadTo(context, '/api/admin/candidates/$candidateId/image');

  static Future<String?> pickAndUploadTo(
      BuildContext context, String path) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (file == null) return null;
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      return 'Could not read that file.';
    }
    if (bytes.length > 15 * 1024 * 1024) return 'Choose an image under 15 MB.';

    if (!context.mounted) return null;
    final cropped = await showSquareCropper(context, bytes);
    if (cropped == null) return null;
    if (cropped.length > maxBytes) return 'The image must be 2 MB or smaller.';

    try {
      final req =
          http.MultipartRequest('POST', Uri.parse('${Api.baseUrl}$path'))
            ..headers['Authorization'] = 'Bearer ${Api.token}'
            ..files.add(http.MultipartFile.fromBytes('file', cropped,
                filename: 'photo.png'));
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
