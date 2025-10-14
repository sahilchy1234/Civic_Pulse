# 🚀 Quick Start: Adding AI to Your App

## Step 1: Get Google Cloud Vision API Key (5 minutes)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Enable **Cloud Vision API**
4. Go to **Credentials** → Create **API Key**
5. Copy the API key

**Free Tier:** 1,000 image analyses per month FREE!

---

## Step 2: Add the AI Service (Already Created! ✅)

The file `lib/services/ai_image_classifier_service.dart` is ready.

Just add your API key:
```dart
static const String _apiKey = 'YOUR_API_KEY_HERE'; // Replace this
```

---

## Step 3: Update Report Issue Screen

Add AI classification when image is selected:

### Option A: Show AI Suggestion (Recommended)

```dart
// In lib/screens/citizen/report_issue_screen.dart

import '../../services/ai_image_classifier_service.dart';

// Add to state:
String? _aiSuggestedType;
bool _isAnalyzingImage = false;

// Update _pickImage method:
Future<void> _pickImage(ImageSource source) async {
  try {
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _isAnalyzingImage = true; // Show loading
        _aiSuggestedType = null;
      });

      // 🤖 AI CLASSIFICATION HERE
      if (AIConfig.enableAIClassification) {
        final suggestedType = await AIImageClassifierService.predictIssueType(
          File(image.path),
        );
        
        if (suggestedType != null && suggestedType != 'Other') {
          setState(() {
            _aiSuggestedType = suggestedType;
          });
          
          // Show suggestion dialog
          _showAISuggestionDialog(suggestedType);
        }
      }
      
      setState(() {
        _isAnalyzingImage = false;
      });
    }
  } catch (e) {
    AppHelpers.showErrorSnackBar(context, 'Error: ${e.toString()}');
  }
}

// Add suggestion dialog:
void _showAISuggestionDialog(String suggestedType) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF667eea).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              color: Color(0xFF667eea),
              size: 24,
            ),
          ),
          SizedBox(width: 12),
          Text('AI Detected'),
        ],
      ),
      content: Text(
        'Our AI detected this might be a "$suggestedType" issue. '
        'Would you like to use this category?',
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('No, I\'ll choose'),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              _selecte
