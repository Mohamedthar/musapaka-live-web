import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class CloudinaryService {
  String _buildUploadUrl(String cloudName) {
    return 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  }

  String _extractErrorFromBody(String body) {
    try {
      final data = json.decode(body);
      if (data is Map && data.containsKey('error')) {
        final error = data['error'];
        if (error is Map && error.containsKey('message')) {
          return error['message'].toString();
        }
      }
    } catch (_) {}
    return 'خطأ غير معروف';
  }

  Future<String> uploadImage(Uint8List fileBytes, String fileName) async {
    if (fileBytes.isEmpty) {
      throw Exception('لا يمكن رفع صورة فارغة');
    }
    if (fileName.trim().isEmpty) {
      throw Exception('اسم الملف غير صالح');
    }
    final url = Uri.parse(_buildUploadUrl(AppConstants.cloudinaryCloudName));

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = AppConstants.cloudinaryUploadPreset
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      ));

    final response = await request.send().timeout(const Duration(seconds: 30));
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      return data['secure_url'] as String;
    } else {
      final errorMsg = _extractErrorFromBody(responseBody);
      throw Exception('فشل في رفع الصورة: ${response.statusCode} - $errorMsg');
    }
  }

  // Simplified version for easier batch handling
  Future<List<String>> uploadMultiple(List<({Uint8List bytes, String name})> images) async {
    final urls = <String>[];
    for (final img in images) {
      final url = await uploadImage(img.bytes, img.name);
      urls.add(url);
    }
    return urls;
  }
}
