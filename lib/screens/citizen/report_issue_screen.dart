import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../models/issue_model.dart';
import '../../utils/theme.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../services/cloudinary_storage_service.dart';
import '../../utils/image_optimizer.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _imagePicker = ImagePicker();
  
  String _selectedIssueType = AppConstants.issueTypes.first;
  File? _selectedImage;
  Map<String, double>? _location;
  bool _isLoading = false;
  // Using Cloudinary method only - no need for selection

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Getting your location...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait while we determine your current position',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Use the detailed location method for better debugging
      final result = await LocationService.getLocationWithDetails();
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      if (result['success'] == true && result['position'] != null) {
        final position = result['position'];
        setState(() {
          _location = {
            'lat': position.latitude,
            'lng': position.longitude,
          };
        });
        
        // Show detailed success message
        String message = 'Location obtained successfully';
        if (result['steps'].isNotEmpty) {
          message += '\nMethod: ${result['steps'].last}';
        }
        AppHelpers.showSuccessSnackBar(context, message);
        
        // Print debug info
        print('Location success - Steps: ${result['steps']}');
      } else {
        // Show detailed error message
        String errorMsg = result['error'] ?? 'Unable to get location';
        if (result['steps'].isNotEmpty) {
          errorMsg += '\nLast step: ${result['steps'].last}';
        }
        AppHelpers.showErrorSnackBar(context, errorMsg);
        
        // Print debug info
        print('Location failed - Error: ${result['error']}');
        print('Steps: ${result['steps']}');
        
        // Show detailed error dialog for debugging
        _showLocationErrorDialog(result);
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      AppHelpers.showErrorSnackBar(context, 'Location error: ${e.toString()}');
      print('Location exception: $e');
    }
  }

  void _showLocationErrorDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Location Error',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Error: ${result['error'] ?? 'Unknown error'}',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
                                      const SizedBox(height: 12),
            const Text(
              'Debug Steps:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: result['steps'].map<Widget>((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $step',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _getCurrentLocation(); // Retry
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF667eea),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _debugLocation() async {
    try {
      final status = await LocationService.getLocationStatus();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Debug Info'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Service Enabled: ${status['serviceEnabled']}'),
                Text('Permission: ${status['permission']}'),
                if (status['lastKnownPosition'] != null) ...[
                  const SizedBox(height: 8),
                  const Text('Last Known Position:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Lat: ${status['lastKnownPosition']['lat']}'),
                  Text('Lng: ${status['lastKnownPosition']['lng']}'),
                  Text('Time: ${status['lastKnownPosition']['timestamp']}'),
                ] else if (status['lastKnownError'] != null) ...[
                  const SizedBox(height: 8),
                  Text('Last Known Error: ${status['lastKnownError']}'),
                ],
                if (status['currentPosition'] != null) ...[
                  const SizedBox(height: 8),
                  const Text('Current Position:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Lat: ${status['currentPosition']['lat']}'),
                  Text('Lng: ${status['currentPosition']['lng']}'),
                  Text('Accuracy: ${status['currentPosition']['accuracy']}'),
                ] else if (status['currentPositionError'] != null) ...[
                  const SizedBox(height: 8),
                  Text('Current Position Error: ${status['currentPositionError']}'),
                ],
                if (status['generalError'] != null) ...[
                  const SizedBox(height: 8),
                  Text('General Error: ${status['generalError']}'),
                ],
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
      AppHelpers.showErrorSnackBar(context, 'Debug failed: $e');
    }
  }

  Future<void> _debugFirebaseStorage() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Testing Cloudinary...'),
            ],
          ),
        ),
      );

      // Test Cloudinary storage connection
      final result = await CloudinaryStorageService.testConnection();
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Cloudinary Storage Debug ${result['success'] ? '✅' : '❌'}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bucket: ${result['bucket'] ?? 'Unknown'}'),
                Text('Connection: ${result['success'] ? '✅' : '❌'}'),
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
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      AppHelpers.showErrorSnackBar(context, 'Cloudinary storage debug failed: $e');
    }
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
        });
      }
    } catch (e) {
      AppHelpers.showErrorSnackBar(context, 'Error picking image: ${e.toString()}');
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;

    try {
      print('📸 Starting image upload using Cloudinary method...');
      
      // Get user ID
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      final userId = user?.id ?? 'anonymous';
      
      print('👤 User ID: $userId');
      print('📁 Image path: ${_selectedImage!.path}');
      
      // Compress image before upload to save bandwidth
      print('🗜️ Compressing issue image...');
      final compressedImage = await ImageOptimizer.compressIssueImage(_selectedImage!);
      final fileToUpload = compressedImage ?? _selectedImage!;
      
      // Upload using Cloudinary method only
      final downloadUrl = await CloudinaryStorageService.uploadFile(
        fileToUpload,
        userId: userId,
        customPath: 'issue_images',
      );
      
      if (downloadUrl != null) {
        print('✅ Cloudinary upload successful: $downloadUrl');
        return downloadUrl;
      } else {
        print('❌ Upload failed: No URL returned');
        return null;
      }
      
    } catch (e) {
      print('❌ Cloudinary upload error: $e');
      print('❌ Error type: ${e.runtimeType}');
      
      // Provide more specific error information
      if (e.toString().contains('storage')) {
        print('❌ Storage error: Check your storage configuration');
      } else if (e.toString().contains('network')) {
        print('❌ Network error during upload. Check internet connection.');
      } else if (e.toString().contains('permission')) {
        print('❌ Permission denied. Check storage policies.');
      } else if (e.toString().contains('signature')) {
        print('❌ Authentication error. Check your S3 credentials.');
      }
      
      return null;
    }
  }

  Future<void> _submitIssue() async {
    print('🚀 Starting issue submission...');
    
    if (!_formKey.currentState!.validate()) {
      print('❌ Form validation failed');
      return;
    }
    
    if (_location == null) {
      print('❌ Location not provided');
      AppHelpers.showErrorSnackBar(context, 'Please get your location first');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('🔐 Getting auth service...');
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      
      if (user == null) {
        print('❌ User not authenticated');
        AppHelpers.showErrorSnackBar(context, 'User not authenticated');
        return;
      }
      
      print('✅ User authenticated: ${user.email}');

      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        print('📸 Uploading image...');
        
        // Show upload progress dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667eea).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Uploading Image...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while your image is being uploaded to Cloudinary',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
        
        try {
          imageUrl = await _uploadImage();
          
          // Close upload dialog
          Navigator.of(context).pop();
          
          if (imageUrl == null) {
            print('❌ Image upload failed, continuing without image');
            // Show dialog asking if user wants to continue without image
            final shouldContinue = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Image Upload Failed'),
                content: const Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Failed to upload image. This could be due to:'),
                    SizedBox(height: 8),
                    Text('• Network connectivity issues'),
                    Text('• Firebase Storage configuration'),
                    Text('• File size limitations'),
                    SizedBox(height: 8),
                    Text('Do you want to continue without the image?'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            );
            
            if (shouldContinue != true) {
              return;
            }
          } else {
            print('✅ Image uploaded: $imageUrl');
            AppHelpers.showSuccessSnackBar(context, 'Image uploaded successfully!');
          }
        } catch (e) {
          // Close upload dialog if still open
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          
          print('❌ Image upload exception: $e');
          AppHelpers.showErrorSnackBar(context, 'Image upload failed: ${e.toString()}');
          
          // Ask if user wants to continue
          final shouldContinue = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Upload Error'),
              content: Text('Image upload failed: ${e.toString()}\n\nDo you want to continue without the image?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          );
          
          if (shouldContinue != true) {
            return;
          }
        }
      }

      // Create issue
      print('📝 Creating issue model...');
      final issue = IssueModel(
        id: '', // Will be set by Firestore
        userId: user.id,
        userName: user.name,
        userProfileImageUrl: user.profileImageUrl,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        issueType: _selectedIssueType,
        location: _location!,
        imageUrl: imageUrl,
        status: AppConstants.pendingStatus,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      print('💾 Saving issue to Firestore...');
      await _firestoreService.createIssue(issue);
      print('✅ Issue saved successfully');
      
      // Update user points
      print('🎯 Updating user points...');
      await authService.updateUserPoints(AppConstants.pointsForReport);
      print('✅ Points updated');

      AppHelpers.showSuccessSnackBar(context, 'Issue reported successfully!');
      Navigator.pop(context);
    } catch (e) {
      print('❌ Error submitting issue: $e');
      AppHelpers.showErrorSnackBar(context, 'Failed to report issue: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('🏁 Issue submission completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea),
              const Color(0xFF764ba2),
              const Color(0xFFf093fb),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Clean Modern Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Report Issue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Help make your community better',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: _isLoading ? null : _submitIssue,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.send, color: Colors.white, size: 20),
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Fill out the form below to report an issue in your area',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Form Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Issue type selection
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF667eea).withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _selectedIssueType,
                              isExpanded: true,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF667eea)),
                              iconSize: 24,
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2D3748),
                              ),
                              decoration: InputDecoration(
                                labelText: 'Issue Type',
                                labelStyle: const TextStyle(
                                  color: Color(0xFF667eea),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                hintText: 'Select the type of issue',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF667eea).withOpacity(0.2),
                                        const Color(0xFFf093fb).withOpacity(0.2),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF667eea).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(Icons.category_rounded, color: Color(0xFF667eea), size: 18),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              items: AppConstants.issueTypes.map((type) {
                                return DropdownMenuItem<String>(
                                  value: type,
                                  child: Row(
                                    children: [
                                      Text(
                                        AppHelpers.getIssueTypeEmoji(type),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        type,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF2D3748),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedIssueType = value;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title field
                          Container(
                decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                                  color: const Color(0xFF667eea).withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                                labelText: 'Issue Title',
                                labelStyle: const TextStyle(
                                  color: Color(0xFF667eea),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                    hintText: 'Brief description of the issue',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF667eea).withOpacity(0.2),
                                        const Color(0xFFf093fb).withOpacity(0.2),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF667eea).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(Icons.title_rounded, color: Color(0xFF667eea), size: 18),
                    ),
                    border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(color: Color(0xFF667eea), width: 2.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    if (value.trim().length < 5) {
                      return 'Title must be at least 5 characters';
                    }
                    return null;
                  },
                ),
              ),
                                      const SizedBox(height: 12),

              // Description field
              Container(
                decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                                  color: const Color(0xFF667eea).withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                                labelText: 'Detailed Description',
                                labelStyle: const TextStyle(
                                  color: Color(0xFF667eea),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                hintText: 'Provide detailed information about the issue',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                    alignLabelWithHint: true,
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF667eea).withOpacity(0.2),
                                        const Color(0xFFf093fb).withOpacity(0.2),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFF667eea).withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(Icons.description_rounded, color: Color(0xFF667eea), size: 18),
                    ),
                    border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(color: Color(0xFF667eea), width: 2.5),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    if (value.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),
              ),
                                      const SizedBox(height: 12),

              // Location section
              Container(
                decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                                  color: const Color(0xFF667eea).withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                                  color: const Color(0xFF667eea).withOpacity(0.1),
                                  width: 1.5,
                    ),
                  ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                                          padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF667eea).withOpacity(0.2),
                                                const Color(0xFFf093fb).withOpacity(0.2),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFF667eea).withOpacity(0.3),
                                              width: 1,
                                            ),
                              ),
                                          child: const Icon(
                                            Icons.location_on_rounded,
                                            color: Color(0xFF667eea),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                              'Location',
                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                                              Text(
                                                'Get your current position',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF718096),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                        Container(
                                      padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _location != null 
                                              ? [
                                                  Colors.green.withOpacity(0.1),
                                                  Colors.green.withOpacity(0.05),
                                                ]
                                              : [
                                                  Colors.red.withOpacity(0.1),
                                                  Colors.red.withOpacity(0.05),
                                                ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _location != null 
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                                          width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                color: _location != null ? Colors.green : Colors.red,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: (_location != null ? Colors.green : Colors.red).withOpacity(0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              _location != null ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                                              color: Colors.white,
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                              Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _location != null ? 'Location Captured' : 'Location Required',
                                                  style: TextStyle(
                                                    color: _location != null ? Colors.green[700] : Colors.red[700],
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                  _location != null
                                      ? 'Lat: ${_location!['lat']?.toStringAsFixed(4)}, Lng: ${_location!['lng']?.toStringAsFixed(4)}'
                                                      : 'Please get your current location to proceed',
                                  style: TextStyle(
                                                    color: _location != null ? Colors.green[600] : Colors.red[600],
                                    fontWeight: FontWeight.w500,
                                                    fontSize: 12,
                                  ),
                                                ),
                                              ],
                                ),
                              ),
                            ],
                          ),
                        ),
                                    const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                              borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                                  color: const Color(0xFF667eea).withOpacity(0.4),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _getCurrentLocation,
                                              icon: const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                                  label: const Text(
                                    'Get Current Location',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                                padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                                        const SizedBox(width: 16),
                            Container(
                              decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.grey[100]!,
                                                Colors.grey[200]!,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                              ),
                              child: IconButton(
                                onPressed: _debugLocation,
                                            icon: const Icon(Icons.bug_report_rounded, color: Colors.grey, size: 20),
                                tooltip: 'Debug Location',
                                style: IconButton.styleFrom(
                                              padding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
                                      const SizedBox(height: 12),

              // Image section
              Container(
                decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                                  color: const Color(0xFF667eea).withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                                  color: const Color(0xFF667eea).withOpacity(0.1),
                                  width: 1.5,
                    ),
                  ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                                          padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF667eea).withOpacity(0.2),
                                                const Color(0xFFf093fb).withOpacity(0.2),
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFF667eea).withOpacity(0.3),
                                              width: 1,
                                            ),
                              ),
                                          child: const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Color(0xFF667eea),
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                              'Photo (Optional)',
                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                                              Text(
                                                'Add a visual reference',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF718096),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                            Container(
                              decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.grey[100]!,
                                                Colors.grey[200]!,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey.withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                              ),
                              child: IconButton(
                                onPressed: _debugFirebaseStorage,
                                            icon: const Icon(Icons.storage_rounded, size: 18, color: Colors.grey),
                                tooltip: 'Debug Storage',
                                visualDensity: VisualDensity.compact,
                                style: IconButton.styleFrom(
                                              padding: const EdgeInsets.all(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                                    const SizedBox(height: 12),
                        if (_selectedImage != null) ...[
                          Container(
                            decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                              color: const Color(0xFF667eea).withOpacity(0.2),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                            height: 220,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                                      const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.green.withOpacity(0.1),
                                                    Colors.green.withOpacity(0.05),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                                  width: 1.5,
                                    ),
                                  ),
                                  child: OutlinedButton.icon(
                                    onPressed: _pickImage,
                                                icon: const Icon(Icons.camera_alt_rounded, color: Colors.green, size: 20),
                                    label: const Text(
                                      'Retake Photo',
                                                  style: TextStyle(
                                                    color: Colors.green, 
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                                          const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.red.withOpacity(0.1),
                                                    Colors.red.withOpacity(0.05),
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.3),
                                                  width: 1.5,
                                    ),
                                  ),
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedImage = null;
                                      });
                                    },
                                                icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                                    label: const Text(
                                      'Remove',
                                                  style: TextStyle(
                                                    color: Colors.red, 
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14,
                                                  ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      side: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF667eea).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _pickImage,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.camera_alt_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Take Photo',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
                          const SizedBox(height: 20),

              // Submit button
              Container(
                decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                                  color: const Color(0xFF667eea).withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isLoading 
                          ? [Colors.grey[400]!, Colors.grey[500]!]
                                      : [const Color(0xFF667eea), const Color(0xFF764ba2), const Color(0xFFf093fb)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                                borderRadius: BorderRadius.circular(20),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitIssue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isLoading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                            width: 24,
                                            height: 24,
                                child: CircularProgressIndicator(
                                              strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                                          SizedBox(width: 16),
                              Text(
                                'Reporting Issue...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                            Icons.send_rounded,
                                color: Colors.white,
                                            size: 24,
                              ),
                                          SizedBox(width: 16),
                              Text(
                                'Report Issue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
                                      const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
