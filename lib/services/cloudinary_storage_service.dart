import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../config/cloudinary_config.dart';

class CloudinaryStorageService {
  /// Upload file to Cloudinary
  static Future<String?> uploadFile(
    File file, {
    required String userId,
    String? customPath,
    String? fileName,
    Function(double progress)? onProgress,
  }) async {
    try {
      print('🚀 Starting Cloudinary upload...');
      
      // Validate file size (Cloudinary free tier: 10MB limit)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB limit
        print('❌ File too large: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB');
        throw Exception('File size exceeds 10MB limit');
      }
      
      // Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = file.path.split('.').last.toLowerCase();
      final finalFileName = fileName ?? '${userId}_${timestamp}.$extension';
      
      // Create folder path
      final folderPath = customPath ?? 'issue_images';
      final publicId = '$folderPath/$finalFileName';
      
      print('📁 Uploading to: $publicId');
      print('📏 File size: ${(fileSize / 1024).toStringAsFixed(1)} KB');
      
      // Prepare multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(CloudinaryConfig.uploadUrl),
      );
      
      // Try unsigned upload first, fallback to signed if preset doesn't exist
      if (CloudinaryConfig.uploadPreset.isNotEmpty) {
        request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      } else {
        // Use signed upload as fallback
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final signature = _generateSignature(publicId, timestamp);
        request.fields['timestamp'] = timestamp;
        request.fields['signature'] = signature;
        request.fields['api_key'] = CloudinaryConfig.apiKey;
      }
      request.fields['public_id'] = publicId;
      
      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
        ),
      );
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final secureUrl = responseData['secure_url'] as String;
        
        print('✅ Cloudinary upload successful: $secureUrl');
        return secureUrl;
      } else {
        print('❌ Cloudinary upload failed: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        return null;
      }
      
    } catch (e) {
      print('❌ Cloudinary upload error: $e');
      return null;
    }
  }
  
  /// Test Cloudinary connection
  static Future<Map<String, dynamic>> testConnection() async {
    final result = <String, dynamic>{
      'success': false,
      'error': null,
      'details': <String>[],
    };
    
    try {
      result['details'].add('Testing Cloudinary connection...');
      
      // Test by making a simple API call
      final response = await http.get(
        Uri.parse('https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/resources/image/upload'),
        headers: {
          'Authorization': 'Basic ${base64Encode(utf8.encode('${CloudinaryConfig.apiKey}:${CloudinaryConfig.apiSecret}'))}',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Connection timeout');
        },
      );
      
      if (response.statusCode == 200) {
        result['details'].add('✅ Cloudinary connection successful');
        result['success'] = true;
      } else {
        result['details'].add('❌ Cloudinary API returned: ${response.statusCode}');
        result['error'] = 'API Error: ${response.statusCode}';
      }
      
    } catch (e) {
      result['error'] = e.toString();
      result['details'].add('❌ Cloudinary connection failed: $e');
    }
    
    return result;
  }
  
  /// Delete file from Cloudinary
  static Future<bool> deleteFile(String publicId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateSignature(publicId, timestamp);
      
      final response = await http.post(
        Uri.parse(CloudinaryConfig.uploadUrl),
        body: {
          'public_id': publicId,
          'timestamp': timestamp,
          'signature': signature,
          'api_key': CloudinaryConfig.apiKey,
        },
      );
      
      if (response.statusCode == 200) {
        print('✅ Cloudinary file deleted: $publicId');
        return true;
      } else {
        print('❌ Failed to delete Cloudinary file: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Failed to delete Cloudinary file: $e');
      return false;
    }
  }
  
  /// Generate signature for authenticated requests
  static String _generateSignature(String publicId, String timestamp) {
    // Create the string to sign - parameters must be sorted alphabetically
    // Only include public_id and timestamp in signature calculation (not api_key)
    final params = [
      'public_id=$publicId',
      'timestamp=$timestamp',
    ];
    params.sort(); // Sort alphabetically as required by Cloudinary
    final stringToSign = params.join('&');
    
    print('🔐 String to sign: $stringToSign');
    
    // Create HMAC-SHA1 signature using different method
    final key = utf8.encode(CloudinaryConfig.apiSecret);
    final bytes = utf8.encode(stringToSign);
    final hmac = Hmac(sha1, key);
    final digest = hmac.convert(bytes);
    
    final signature = digest.toString();
    print('🔐 Generated signature: $signature');
    print('🔐 API Secret length: ${CloudinaryConfig.apiSecret.length}');
    print('🔐 API Secret: ${CloudinaryConfig.apiSecret.substring(0, 8)}...');
    
    return signature;
  }
}
