import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Image optimization utilities to reduce bandwidth usage
class ImageOptimizer {
  /// Compress image before upload to reduce bandwidth
  /// Returns compressed file or null if compression fails
  static Future<File?> compressImage(
    File file, {
    int quality = 70,
    int maxWidth = 1920,
    int maxHeight = 1920,
  }) async {
    try {
      print('🗜️ Compressing image...');
      final originalSize = await file.length();
      print('📏 Original size: ${(originalSize / 1024).toStringAsFixed(1)} KB');

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetPath = path.join(
        tempDir.path,
        'compressed_$timestamp${path.extension(file.path)}',
      );

      // Compress image
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
        format: CompressFormat.jpeg, // JPEG is smaller than PNG
      );

      if (compressedFile != null) {
        final compressedSize = await File(compressedFile.path).length();
        final savings = ((1 - (compressedSize / originalSize)) * 100).toStringAsFixed(1);
        print('✅ Compressed size: ${(compressedSize / 1024).toStringAsFixed(1)} KB');
        print('💾 Saved ${savings}% bandwidth');
        return File(compressedFile.path);
      }

      return null;
    } catch (e) {
      print('❌ Compression error: $e');
      return null; // Return original file if compression fails
    }
  }

  /// Compress avatar/profile image (smaller size needed)
  static Future<File?> compressAvatarImage(File file) async {
    return compressImage(
      file,
      quality: 75,
      maxWidth: 512,
      maxHeight: 512,
    );
  }

  /// Compress issue image (larger but still optimized)
  static Future<File?> compressIssueImage(File file) async {
    return compressImage(
      file,
      quality: 70,
      maxWidth: 1920,
      maxHeight: 1920,
    );
  }

  /// Get optimized Cloudinary URL with transformations
  /// This delivers smaller images from Cloudinary's CDN
  static String getOptimizedCloudinaryUrl(
    String originalUrl, {
    CloudinaryOptimization optimization = CloudinaryOptimization.balanced,
  }) {
    // Check if it's a Cloudinary URL
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl;
    }

    // Parse URL to inject transformations
    final uri = Uri.parse(originalUrl);
    final pathSegments = uri.pathSegments.toList();

    // Find 'upload' segment to inject transformations after it
    final uploadIndex = pathSegments.indexOf('upload');
    if (uploadIndex == -1) return originalUrl;

    // Build transformation string based on optimization level
    String transformation;
    switch (optimization) {
      case CloudinaryOptimization.thumbnail:
        transformation = 'w_300,h_300,c_fill,f_auto,q_auto:low';
        break;
      case CloudinaryOptimization.avatar:
        transformation = 'w_200,h_200,c_fill,f_auto,q_auto:good,g_face';
        break;
      case CloudinaryOptimization.preview:
        transformation = 'w_800,h_600,c_fit,f_auto,q_auto:good';
        break;
      case CloudinaryOptimization.balanced:
        transformation = 'w_1200,h_1200,c_limit,f_auto,q_auto:good';
        break;
      case CloudinaryOptimization.highQuality:
        transformation = 'w_1920,h_1920,c_limit,f_auto,q_auto:best';
        break;
    }

    // Insert transformation after 'upload'
    pathSegments.insert(uploadIndex + 1, transformation);

    // Rebuild URL
    return uri.replace(pathSegments: pathSegments).toString();
  }

  /// Get responsive image URLs for different screen sizes
  static Map<String, String> getResponsiveUrls(String originalUrl) {
    return {
      'thumbnail': getOptimizedCloudinaryUrl(
        originalUrl,
        optimization: CloudinaryOptimization.thumbnail,
      ),
      'mobile': getOptimizedCloudinaryUrl(
        originalUrl,
        optimization: CloudinaryOptimization.preview,
      ),
      'tablet': getOptimizedCloudinaryUrl(
        originalUrl,
        optimization: CloudinaryOptimization.balanced,
      ),
      'desktop': getOptimizedCloudinaryUrl(
        originalUrl,
        optimization: CloudinaryOptimization.highQuality,
      ),
    };
  }
}

/// Cloudinary optimization presets
enum CloudinaryOptimization {
  thumbnail, // 300x300, low quality - for list views
  avatar, // 200x200, good quality - for profile pictures
  preview, // 800x600, good quality - for previews
  balanced, // 1200x1200, good quality - default
  highQuality, // 1920x1920, best quality - for detail views
}

