import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Same Cloudinary account/preset as the Seller app (Stage 3/17) —
/// both apps upload into the same cloud, just different folders
/// implicitly via the preset's configured folder.
class CloudinaryService {
  // TODO: Replace with your actual Cloudinary cloud name (same as Seller app)
  static const String cloudName = 'YOUR_CLOUD_NAME';

  // TODO: Replace with your actual unsigned preset name (same as Seller app)
  static const String uploadPreset = 'buildmart_unsigned';

  static Uri get _uploadUrl =>
      Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

  Future<String> uploadImage(File imageFile) async {
    final request = http.MultipartRequest('POST', _uploadUrl)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('Image upload failed (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = data['secure_url'] as String?;
    if (secureUrl == null) {
      throw Exception('Upload succeeded but no URL was returned.');
    }
    return secureUrl;
  }
}
