import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// AI Image Classification Service
/// Automatically detects issue type from uploaded images
/// 
/// Current Implementation: Google Cloud Vision API
/// Alternative: Can switch to TensorFlow Lite for offline support
class AIImageClassifierService {
  // TODO: Replace with your Google Cloud Vision API Key
  // Get it from: https://console.cloud.google.com/apis/credentials
  static const String _apiKey = 'YOUR_GOOGLE_VISION_API_KEY';
  static const String _visionApiUrl = 'https://vision.googleapis.com/v1/images:annotate';

  /// Predicts issue type from image
  /// Returns detected category or null if can't determine
  static Future<String?> predictIssueType(File imageFile) async {
    try {
      print('🤖 AI: Starting image classification...');

      // 1. Convert image to base64
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // 2. Call Google Vision API
      final labels = await _detectLabels(base64Image);
      print('🏷️ AI detected labels: $labels');

      // 3. Map labels to issue categories
      final issueType = _mapLabelsToIssueType(labels);
      print('✅ AI predicted issue type: $issueType');

      return issueType;
    } catch (e) {
      print('❌ AI classification error: $e');
      return null; // Graceful fallback - user selects manually
    }
  }

  /// Calls Google Cloud Vision API to detect labels
  static Future<List<String>> _detectLabels(String base64Image) async {
    final response = await http.post(
      Uri.parse('$_visionApiUrl?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'requests': [
          {
            'image': {'content': base64Image},
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 10},
              {'type': 'OBJECT_LOCALIZATION', 'maxResults': 10},
            ],
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<String> labels = [];

      // Extract label annotations
      if (data['responses'] != null && data['responses'].isNotEmpty) {
        final annotations = data['responses'][0]['labelAnnotations'];
        if (annotations != null) {
          for (var annotation in annotations) {
            labels.add(annotation['description'].toString().toLowerCase());
          }
        }

        // Extract object localizations
        final objects = data['responses'][0]['localizedObjectAnnotations'];
        if (objects != null) {
          for (var obj in objects) {
            labels.add(obj['name'].toString().toLowerCase());
          }
        }
      }

      return labels;
    } else {
      throw Exception('Vision API error: ${response.statusCode}');
    }
  }

  /// Maps detected labels to app's issue categories
  static String _mapLabelsToIssueType(List<String> labels) {
    // Issue category keywords mapping
    final categoryKeywords = {
      'Roads': [
        'road',
        'pothole',
        'asphalt',
        'pavement',
        'street',
        'highway',
        'crack',
        'damage',
        'hole',
        'construction',
      ],
      'Street Lighting': [
        'light',
        'lamp',
        'streetlight',
        'lighting',
        'bulb',
        'pole',
        'lamppost',
        'illumination',
        'dark',
      ],
      'Waste Management': [
        'trash',
        'garbage',
        'waste',
        'bin',
        'dumpster',
        'litter',
        'rubbish',
        'dump',
        'refuse',
        'landfill',
      ],
      'Traffic Signal': [
        'traffic',
        'signal',
        'traffic light',
        'stop light',
        'red light',
        'green light',
        'crosswalk',
        'pedestrian crossing',
      ],
      'Graffiti': [
        'graffiti',
        'vandalism',
        'spray paint',
        'wall art',
        'tag',
        'paint',
        'writing on wall',
      ],
      'Water Supply': [
        'water',
        'pipe',
        'leak',
        'tap',
        'faucet',
        'plumbing',
        'drainage',
        'flood',
        'hydrant',
      ],
      'Parks': [
        'park',
        'playground',
        'bench',
        'tree',
        'grass',
        'garden',
        'recreation',
        'swing',
        'slide',
      ],
      'Electricity': [
        'wire',
        'cable',
        'electric',
        'power line',
        'electricity',
        'transformer',
        'electrical',
      ],
    };

    // Count matches for each category
    final Map<String, int> categoryScores = {};
    
    for (var category in categoryKeywords.keys) {
      categoryScores[category] = 0;
      final keywords = categoryKeywords[category]!;
      
      for (var label in labels) {
        for (var keyword in keywords) {
          if (label.contains(keyword) || keyword.contains(label)) {
            categoryScores[category] = categoryScores[category]! + 1;
          }
        }
      }
    }

    // Find category with highest score
    var bestCategory = 'Other';
    var bestScore = 0;

    categoryScores.forEach((category, score) {
      if (score > bestScore) {
        bestScore = score;
        bestCategory = category;
      }
    });

    // Only return if we have reasonable confidence (at least 2 matches)
    return bestScore >= 2 ? bestCategory : 'Other';
  }

  /// Analyzes image severity (for priority scoring)
  /// Returns score 0-100 based on image content
  static Future<int> analyzeSeverity(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('$_visionApiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'requests': [
            {
              'image': {'content': base64Image},
              'features': [
                {'type': 'IMAGE_PROPERTIES'},
                {'type': 'SAFE_SEARCH_DETECTION'},
              ],
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        // Analyze image properties (darkness, colors, etc.)
        // Dark images might indicate lighting issues
        // Red/orange colors might indicate danger
        
        // TODO: Implement advanced severity analysis
        // Can use image properties from Vision API response
        // For now, return moderate severity
        return 50; // Moderate severity by default
      }
      
      return 50;
    } catch (e) {
      print('❌ Severity analysis error: $e');
      return 50; // Default to moderate
    }
  }

  /// Validates API key is configured
  static bool isConfigured() {
    return _apiKey != 'YOUR_GOOGLE_VISION_API_KEY' && _apiKey.isNotEmpty;
  }
}

/// Simple on-device alternative (no API needed)
/// Uses basic image analysis without cloud services
class SimpleImageClassifier {
  /// Analyzes image using basic heuristics
  /// Less accurate but free and works offline
  static Future<String?> predictIssueType(File imageFile) async {
    // TODO: Implement basic classification
    // Could analyze:
    // - Image brightness (dark = lighting issue)
    // - Predominant colors (gray/black = road, green = park)
    // - Image dimensions/aspect ratio
    
    return null; // Returns null to fallback to manual selection
  }
}

/// Configuration helper
class AIConfig {
  static const bool enableAIClassification = false; // Set to true when API key is added
  static const bool showAISuggestions = true;
  static const double confidenceThreshold = 0.7;
}

