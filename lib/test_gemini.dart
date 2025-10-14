import 'services/ai_solution_service.dart';
import 'models/solution_model.dart';
import 'models/issue_model.dart';

/// Test script to verify Gemini API integration
Future<void> testGeminiIntegration() async {
  print('🧪 Testing Gemini API Integration...');
  
  // Test 1: Check if service is configured
  print('\n1. Checking API configuration...');
  final isConfigured = AISolutionService.isConfigured();
  print('   API Configured: $isConfigured');
  
  // Test 2: Check service status
  print('\n2. Checking service status...');
  final status = await AISolutionService.getServiceStatus();
  print('   Service Available: ${status['available']}');
  print('   Status: ${status['reason']}');
  
  if (status['available'] == true) {
    print('\n✅ Gemini API is working correctly!');
    print('   The AI solution service is ready to use.');
  } else {
    print('\n❌ Gemini API is not working:');
    print('   Reason: ${status['reason']}');
    if (status.containsKey('instructions')) {
      print('   Instructions: ${status['instructions']}');
    }
  }
  
  // Test 3: Generate sample tags
  print('\n3. Testing tag generation...');
  try {
    final tags = await AISolutionService.generateSolutionTags(
      'Fix Pothole',
      'Fill pothole with asphalt patch',
      SolutionType.diyFix,
    );
    print('   Generated tags: $tags');
  } catch (e) {
    print('   Tag generation failed: $e');
  }
  
  // Test 4: Test basic text generation
  print('\n4. Testing basic text generation...');
  try {
    // Create a simple test issue
    final testIssue = IssueModel(
      id: 'test',
      userId: 'test',
      userName: 'Test User',
      userProfileImageUrl: '',
      title: 'Test Pothole Issue',
      description: 'There is a small pothole on Main Street that needs fixing.',
      issueType: 'Pothole',
      location: {'lat': 40.7128, 'lng': -74.0060},
      status: 'Pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final analysis = await AISolutionService.analyzeIssueForSolutions(testIssue, []);
    print('   Analysis confidence: ${(analysis.confidence * 100).toInt()}%');
    print('   Suggested type: ${analysis.suggestedType}');
    print('   Suggested difficulty: ${analysis.suggestedDifficulty}');
    print('   Summary: ${analysis.summary}');
  } catch (e) {
    print('   Issue analysis failed: $e');
  }
}
