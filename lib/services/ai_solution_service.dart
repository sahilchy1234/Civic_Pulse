import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/solution_model.dart';
import '../models/issue_model.dart';

class AISolutionService {
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
  static const String _model = 'gemini-2.5-flash';
  
  // Google Gemini API key
  static const String _apiKey = 'AIzaSyDUoWN4mofY6r2omsN7cS1BGTMFAC2rHtg';

  /// Analyze an issue and suggest appropriate solutions using AI
  static Future<AIAnalysisResult> analyzeIssueForSolutions(
    IssueModel issue,
    List<String> imageUrls, {
    List<SolutionModel>? similarSolutions,
  }) async {
    try {
      final prompt = _buildAnalysisPrompt(issue, similarSolutions);
      
      // Build Gemini content parts
      final contentParts = <Map<String, dynamic>>[
        {
          'text': '''You are an expert civic infrastructure analyst and community problem-solving specialist. 
          Your job is to analyze issues and suggest appropriate, safe, and effective solutions that community members can implement.

          Guidelines:
          1. Prioritize safety - never suggest dangerous solutions
          2. Consider DIY feasibility - suggest solutions appropriate for community members
          3. Provide realistic time and cost estimates
          4. Include necessary materials and tools
          5. Suggest difficulty levels based on skill requirements
          6. Consider environmental and social impact
          7. Provide safety warnings for any risks

          Response format should be JSON with the following structure:
          {
            "confidence": 0.85,
            "suggestedType": "diyFix|workaround|documentation|communityHelp|maintenance|improvement",
            "suggestedDifficulty": "easy|medium|advanced|expert",
            "suggestedMaterials": ["material1", "material2"],
            "estimatedTime": 120,
            "estimatedCost": 5000,
            "safetyWarnings": ["warning1", "warning2"],
            "successFactors": ["factor1", "factor2"],
            "summary": "Brief summary of the analysis",
            "metadata": {
              "alternativeApproaches": ["approach1", "approach2"],
              "longTermConsiderations": ["consideration1"],
              "communityImpact": "positive|neutral|negative"
            }
          }

          Issue to analyze:
          $prompt'''
        }
      ];

      // Add images if provided (skip if conversion fails)
      if (imageUrls.isNotEmpty) {
        for (final imageUrl in imageUrls) {
          try {
            final base64Image = await _getBase64Image(imageUrl);
            if (base64Image.isNotEmpty) {
              contentParts.add({
                'inline_data': {
                  'mime_type': 'image/jpeg',
                  'data': base64Image,
                }
              });
            }
          } catch (e) {
            print('Skipping image $imageUrl due to error: $e');
            // Continue without the image
          }
        }
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/models/$_model:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': contentParts
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 1000,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if we have candidates and content
        if (data['candidates'] != null && 
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null) {
          
          final candidate = data['candidates'][0];
          final finishReason = candidate['finishReason'];
          
          // Check if we have content parts
          if (candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty) {
            
            final content = candidate['content']['parts'][0]['text'];
            
            try {
              final analysisData = json.decode(content);
              return AIAnalysisResult.fromMap(analysisData);
            } catch (e) {
              print('JSON parsing failed: $e');
              print('Raw content: $content');
              // Fallback if JSON parsing fails
              return _createFallbackAnalysis(issue);
            }
          }
          
          // If response was truncated due to token limit, use fallback
          if (finishReason == 'MAX_TOKENS') {
            print('Analysis response truncated due to token limit, using fallback');
            return _createFallbackAnalysis(issue);
          }
        }
        
        print('Invalid response structure: $data');
        return _createFallbackAnalysis(issue);
      } else {
        print('AI Analysis Error: ${response.statusCode} - ${response.body}');
        return _createFallbackAnalysis(issue);
      }
    } catch (e) {
      print('AI Analysis Exception: $e');
      return _createFallbackAnalysis(issue);
    }
  }

  /// Analyze a submitted solution for quality and safety
  static Future<Map<String, dynamic>> analyzeSolutionQuality(
    SolutionModel solution,
    List<String> beforeImages,
    List<String> afterImages,
  ) async {
    try {
      final prompt = '''
        Analyze this community solution submission for quality, safety, and effectiveness.
        
        Solution Details:
        - Title: ${solution.title}
        - Description: ${solution.description}
        - Type: ${solution.type}
        - Difficulty: ${solution.difficulty}
        - Materials: ${solution.materials.join(', ')}
        - Estimated Time: ${solution.estimatedTime} minutes
        - Estimated Cost: \$${(solution.estimatedCost / 100).toStringAsFixed(2)}
        
        Please provide analysis in JSON format:
        {
          "qualityScore": 0.85,
          "safetyScore": 0.90,
          "feasibilityScore": 0.80,
          "costEffectiveness": 0.75,
          "recommendations": ["rec1", "rec2"],
          "safetyConcerns": ["concern1", "concern2"],
          "improvementSuggestions": ["suggestion1", "suggestion2"],
          "overallRating": 4.2
        }
      ''';

      final response = await http.post(
        Uri.parse('$_baseUrl/models/$_model:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''You are a safety and quality inspector for community solutions. Analyze solutions for safety, feasibility, and effectiveness.
                  
                  $prompt'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 800,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['candidates'] != null && 
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null) {
          
          final candidate = data['candidates'][0];
          final finishReason = candidate['finishReason'];
          
          // Check if we have content parts
          if (candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty) {
            
            final content = candidate['content']['parts'][0]['text'];
            
            try {
              return json.decode(content);
            } catch (e) {
              print('Quality analysis JSON parsing failed: $e');
              return _createFallbackQualityAnalysis();
            }
          }
          
          // If response was truncated due to token limit, use fallback
          if (finishReason == 'MAX_TOKENS') {
            print('Quality analysis response truncated due to token limit, using fallback');
            return _createFallbackQualityAnalysis();
          }
        }
        
        print('Invalid quality analysis response structure: $data');
        return _createFallbackQualityAnalysis();
      } else {
        print('Quality analysis API error: ${response.statusCode} - ${response.body}');
        return _createFallbackQualityAnalysis();
      }
    } catch (e) {
      print('Solution Quality Analysis Error: $e');
      return _createFallbackQualityAnalysis();
    }
  }

  /// Generate solution suggestions based on issue similarity
  static Future<List<Map<String, dynamic>>> findSimilarSolutions(
    IssueModel issue,
    List<SolutionModel> existingSolutions,
  ) async {
    try {
      // Simple similarity matching based on issue type and description
      final similarSolutions = <Map<String, dynamic>>[];
      
      for (final solution in existingSolutions) {
        double similarity = _calculateSimilarity(issue, solution);
        
        if (similarity > 0.7) {
          similarSolutions.add({
            'solution': solution,
            'similarity': similarity,
            'reason': 'Similar issue type and description',
          });
        }
      }
      
      // Sort by similarity and return top 5
      similarSolutions.sort((a, b) => b['similarity'].compareTo(a['similarity']));
      return similarSolutions.take(5).toList();
    } catch (e) {
      print('Similar Solutions Error: $e');
      return [];
    }
  }

  /// Generate AI-powered tags for solutions
  static Future<List<String>> generateSolutionTags(
    String title,
    String description,
    SolutionType type,
  ) async {
    try {
      final prompt = '''
        Generate relevant tags for this community solution:
        Title: $title
        Description: $description
        Type: $type
        
        Return as JSON array: ["tag1", "tag2", "tag3"]
        Focus on: issue type, materials used, difficulty, location type, effectiveness
      ''';

      final response = await http.post(
        Uri.parse('$_baseUrl/models/$_model:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''Generate relevant tags for community solutions. Return only JSON array.
                  
                  $prompt'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 200,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['candidates'] != null && 
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null) {
          
          final candidate = data['candidates'][0];
          final finishReason = candidate['finishReason'];
          
          // Check if we have content parts
          if (candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty) {
            
            final content = candidate['content']['parts'][0]['text'];
            
            try {
              return List<String>.from(json.decode(content));
            } catch (e) {
              print('Tag generation JSON parsing failed: $e');
              return _generateFallbackTags(type);
            }
          }
          
          // If response was truncated due to token limit, use fallback
          if (finishReason == 'MAX_TOKENS') {
            print('Tag response truncated due to token limit, using fallback tags');
            return _generateFallbackTags(type);
          }
        }
        
        print('Invalid tag generation response structure: $data');
        return _generateFallbackTags(type);
      } else {
        print('Tag generation API error: ${response.statusCode} - ${response.body}');
        return _generateFallbackTags(type);
      }
    } catch (e) {
      print('Tag Generation Error: $e');
      return _generateFallbackTags(type);
    }
  }

  // Helper methods

  /// Convert image URL to base64 for Gemini API
  static Future<String> _getBase64Image(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        return base64Encode(bytes);
      }
      throw Exception('Failed to fetch image');
    } catch (e) {
      print('Error converting image to base64: $e');
      // Return a placeholder or empty string
      return '';
    }
  }

  static String _buildAnalysisPrompt(IssueModel issue, List<SolutionModel>? similarSolutions) {
    final buffer = StringBuffer();
    
    buffer.writeln('Analyze this civic issue and suggest appropriate community solutions:');
    buffer.writeln();
    buffer.writeln('Issue Details:');
    buffer.writeln('- Type: ${issue.issueType}');
    buffer.writeln('- Title: ${issue.title}');
    buffer.writeln('- Description: ${issue.description}');
    buffer.writeln('- Location: ${issue.location}');
    buffer.writeln('- Status: ${issue.status}');
    buffer.writeln('- Created: ${issue.createdAt}');
    buffer.writeln();
    
    if (similarSolutions != null && similarSolutions.isNotEmpty) {
      buffer.writeln('Similar successful solutions found:');
      for (final solution in similarSolutions.take(3)) {
        buffer.writeln('- ${solution.title} (${solution.type}, ${solution.difficulty})');
        buffer.writeln('  Success rate: ${solution.successRating}/5.0');
        buffer.writeln('  Materials: ${solution.materials.join(', ')}');
        buffer.writeln();
      }
    }
    
    buffer.writeln('Please provide detailed analysis and recommendations.');
    
    return buffer.toString();
  }

  static double _calculateSimilarity(IssueModel issue, SolutionModel solution) {
    double similarity = 0.0;
    
    // Issue type similarity (40% weight)
    if (issue.issueType.toLowerCase().contains(solution.title.toLowerCase()) ||
        solution.title.toLowerCase().contains(issue.issueType.toLowerCase())) {
      similarity += 0.4;
    }
    
    // Description similarity (30% weight)
    final issueWords = issue.description.toLowerCase().split(' ');
    final solutionWords = solution.description.toLowerCase().split(' ');
    final commonWords = issueWords.where((word) => solutionWords.contains(word)).length;
    final descriptionSimilarity = commonWords / issueWords.length;
    similarity += descriptionSimilarity * 0.3;
    
    // Status similarity (20% weight)
    if (solution.status == SolutionStatus.verified || solution.successRating > 4.0) {
      similarity += 0.2;
    }
    
    // Difficulty appropriateness (10% weight)
    if (solution.difficulty == DifficultyLevel.easy || solution.difficulty == DifficultyLevel.medium) {
      similarity += 0.1;
    }
    
    return similarity;
  }

  static AIAnalysisResult _createFallbackAnalysis(IssueModel issue) {
    return AIAnalysisResult(
      confidence: 0.5,
      suggestedType: 'diyFix',
      suggestedDifficulty: DifficultyLevel.easy,
      suggestedMaterials: _getDefaultMaterials(issue.issueType),
      estimatedTime: 60,
      estimatedCost: 1000,
      safetyWarnings: ['Always prioritize safety', 'Wear appropriate protective gear'],
      successFactors: ['Proper materials', 'Following instructions', 'Regular maintenance'],
      summary: 'Community solution suggested based on issue type',
      metadata: {
        'fallback': true,
        'alternativeApproaches': ['Contact local authorities', 'Organize community effort'],
        'longTermConsiderations': ['Regular monitoring needed'],
        'communityImpact': 'positive'
      },
    );
  }

  static Map<String, dynamic> _createFallbackQualityAnalysis() {
    return {
      'qualityScore': 0.7,
      'safetyScore': 0.8,
      'feasibilityScore': 0.7,
      'costEffectiveness': 0.6,
      'recommendations': ['Provide more detailed instructions', 'Include safety measures'],
      'safetyConcerns': ['Ensure proper safety equipment'],
      'improvementSuggestions': ['Add before/after photos', 'Include material specifications'],
      'overallRating': 3.5,
    };
  }

  static List<String> _getDefaultMaterials(String issueType) {
    switch (issueType.toLowerCase()) {
      case 'pothole':
        return ['Asphalt patch', 'Tamping tool', 'Safety cones'];
      case 'garbage':
        return ['Trash bags', 'Gloves', 'Cleaning supplies'];
      case 'street light':
        return ['Electrical tester', 'Replacement bulb', 'Ladder'];
      case 'water leak':
        return ['Pipe repair kit', 'Wrench set', 'Tape'];
      default:
        return ['Basic tools', 'Safety equipment', 'Cleaning supplies'];
    }
  }

  static List<String> _generateFallbackTags(SolutionType type) {
    switch (type) {
      case SolutionType.diyFix:
        return ['diy', 'repair', 'fix', 'community'];
      case SolutionType.workaround:
        return ['temporary', 'workaround', 'quick-fix'];
      case SolutionType.documentation:
        return ['documentation', 'reporting', 'information'];
      case SolutionType.communityHelp:
        return ['community', 'group-effort', 'volunteer'];
      case SolutionType.maintenance:
        return ['maintenance', 'preventive', 'upkeep'];
      case SolutionType.improvement:
        return ['improvement', 'enhancement', 'upgrade'];
    }
  }

  /// Check if AI service is properly configured
  static bool isConfigured() {
    return _apiKey.isNotEmpty && _apiKey != 'your-gemini-api-key-here';
  }

  /// Get AI service status
  static Future<Map<String, dynamic>> getServiceStatus() async {
    if (!isConfigured()) {
      return {
        'available': false,
        'reason': 'API key not configured',
        'instructions': 'Please add your Google Gemini API key to use AI features'
      };
    }

    try {
      // First try to list available models
      final listResponse = await http.get(
        Uri.parse('$_baseUrl/models?key=$_apiKey'),
      );
      
      if (listResponse.statusCode == 200) {
        final modelsData = json.decode(listResponse.body);
        print('Available models: ${modelsData['models']?.map((m) => m['name']).toList()}');
      }

      // Then check if our specific model is available
      final response = await http.get(
        Uri.parse('$_baseUrl/models/$_model?key=$_apiKey'),
      );

      return {
        'available': response.statusCode == 200,
        'statusCode': response.statusCode,
        'reason': response.statusCode == 200 ? 'Service available' : 'API error',
        'model': _model,
      };
    } catch (e) {
      return {
        'available': false,
        'reason': 'Connection error: $e',
      };
    }
  }
}
