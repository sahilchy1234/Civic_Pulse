import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:async';
import '../../services/cloudinary_storage_service.dart';
import '../../services/firebase_storage_service.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';

class StorageTestScreen extends StatefulWidget {
  const StorageTestScreen({super.key});

  @override
  State<StorageTestScreen> createState() => _StorageTestScreenState();
}

class _StorageTestScreenState extends State<StorageTestScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  String? _uploadResult;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  int _selectedMethod = 0; // 0: Cloudinary, 1: Firebase

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Test'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Storage Test',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This page tests image upload functionality with Cloudinary and Firebase Storage.',
                    ),
                    const SizedBox(height: 8),
                    const Text('Available Methods:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Text('• Cloudinary (Recommended)'),
                    const Text('• Firebase Storage'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Method Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Storage Method',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Cloudinary')),
                        ButtonSegment(value: 1, label: Text('Firebase')),
                      ],
                      selected: {_selectedMethod},
                      onSelectionChanged: (Set<int> selection) {
                        setState(() {
                          _selectedMethod = selection.first;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Image Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Image',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_selectedImage != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImage!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Retake'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedImage = null;
                                });
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text('Remove'),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Take Photo'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Upload Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Upload Test',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _selectedImage != null && !_isUploading ? _testUpload : null,
                      icon: _isUploading ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ) : const Icon(Icons.cloud_upload),
                      label: Text(_isUploading ? 'Uploading...' : 'Upload Image'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    if (_uploadProgress > 0) ...[
                      const SizedBox(height: 12),
                      LinearProgressIndicator(value: _uploadProgress),
                      const SizedBox(height: 8),
                      Text('Progress: ${(_uploadProgress * 100).toStringAsFixed(1)}%'),
                    ],
                    if (_uploadResult != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upload Successful!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'URL: $_uploadResult',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Connection Test
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connection Test',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _testConnection,
                      icon: const Icon(Icons.wifi),
                      label: const Text('Test Connection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _uploadResult = null;
        });
      }
    } catch (e) {
      AppHelpers.showErrorSnackBar(context, 'Error picking image: ${e.toString()}');
    }
  }

  Future<void> _testUpload() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadResult = null;
    });

    try {
      final methodNames = ['Cloudinary', 'Firebase'];
      print('🧪 Starting ${methodNames[_selectedMethod]} upload test...');
      
      String? downloadUrl;
      
      switch (_selectedMethod) {
        case 0: // Cloudinary
          downloadUrl = await CloudinaryStorageService.uploadFile(
            _selectedImage!,
            userId: 'test_user',
            customPath: 'test_uploads',
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
          break;
        case 1: // Firebase
          downloadUrl = await FirebaseStorageService.uploadFile(
            _selectedImage!,
            userId: 'test_user',
            customPath: 'test_uploads',
            onProgress: (progress) {
              setState(() {
                _uploadProgress = progress;
              });
            },
          );
          break;
      }
      
      setState(() {
        _isUploading = false;
        _uploadProgress = 1.0;
        _uploadResult = downloadUrl;
      });
      
      if (downloadUrl != null) {
        print('✅ ${methodNames[_selectedMethod]} upload successful: $downloadUrl');
        AppHelpers.showSuccessSnackBar(context, '${methodNames[_selectedMethod]} upload successful!');
      } else {
        AppHelpers.showErrorSnackBar(context, '${methodNames[_selectedMethod]} upload failed');
      }
      
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
      
      print('❌ ${['Cloudinary', 'Firebase'][_selectedMethod]} upload error: $e');
      AppHelpers.showErrorSnackBar(context, 'Upload failed: $e');
    }
  }

  Future<void> _testConnection() async {
    final methodNames = ['Cloudinary', 'Firebase'];
    
    try {
      AppHelpers.showSuccessSnackBar(context, 'Testing ${methodNames[_selectedMethod]} connection...');
      
      Map<String, dynamic> result;
      switch (_selectedMethod) {
        case 0: // Cloudinary
          result = await CloudinaryStorageService.testConnection();
          break;
        case 1: // Firebase
          result = await FirebaseStorageService.testConnection();
          break;
        default:
          result = {'success': false, 'error': 'Unknown method'};
      }
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${methodNames[_selectedMethod]} Connection Test ${result['success'] ? '✅' : '❌'}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Connection: ${result['success'] ? '✅ Success' : '❌ Failed'}'),
                if (result['error'] != null) ...[
                  const SizedBox(height: 8),
                  Text('Error: ${result['error']}', style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 8),
                const Text('Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...result['details'].map<Widget>((detail) => Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 2),
                  child: Text('• $detail', style: const TextStyle(fontSize: 12)),
                )).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      
    } catch (e) {
      AppHelpers.showErrorSnackBar(context, 'Connection test failed: $e');
    }
  }
}