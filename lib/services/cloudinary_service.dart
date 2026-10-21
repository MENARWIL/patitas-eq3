import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CloudinaryService {
  static const _cloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  static const _uploadPreset = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );

  static bool get isConfigured =>
      _cloudName.isNotEmpty && _uploadPreset.isNotEmpty;

  Future<String> uploadImage(XFile image) async {
    if (!isConfigured) {
      throw StateError(
        'Configura CLOUDINARY_CLOUD_NAME y CLOUDINARY_UPLOAD_PRESET.',
      );
    }

    final endpoint = Uri.https(
      'api.cloudinary.com',
      '/v1_1/$_cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', endpoint)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = 'mascotas'
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          await image.readAsBytes(),
          filename: image.name,
        ),
      );

    final response = await http.Response.fromStream(await request.send());
    final data = jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorData = data is Map<String, dynamic> ? data['error'] : null;
      final message = errorData is Map<String, dynamic>
          ? errorData['message']
          : null;
      throw CloudinaryUploadException(
        message is String ? message : 'Error HTTP ${response.statusCode}.',
      );
    }
    if (data is! Map<String, dynamic> || data['secure_url'] is! String) {
      throw const CloudinaryUploadException(
        'Cloudinary no devolvió una URL segura.',
      );
    }
    return data['secure_url'] as String;
  }
}

class CloudinaryUploadException implements Exception {
  const CloudinaryUploadException(this.message);

  final String message;

  @override
  String toString() => 'No se pudo subir la imagen: $message';
}
