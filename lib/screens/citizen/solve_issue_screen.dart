import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/issue_model.dart';
import '../../models/solution_model.dart';
import '../../services/auth_service.dart';
import '../../services/ai_solution_service.dart';
import '../../services/solution_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/helpers.dart';
import '../../utils/theme.dart';
import '../../services/cloudinary_storage_service.dart';

class SolveIssueScreen extends StatefulWidget {
  final IssueModel issue;

  const SolveIssueScreen({
    super.key,
    required this.issue,
  });

  @override
  State<SolveIssueScreen> createState() => _SolveIssueScreenState();
}

class _SolveIssueScreenState extends State<SolveIssueScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _materialsController = TextEditingController();
  
  // Solution details
  SolutionType _selectedType = SolutionType.diyFix;
  DifficultyLevel _selectedDifficulty = DifficultyLevel.easy;
  int _estimatedTime = 30;
  int _estimatedCost = 1000; // in cents
  
  // AI Help
  bool _isLoadingAI = false;
  AIAnalysisResult? _aiAnalysis;
  List<String> _aiSteps = [];
  List<String> _aiMaterials = [];
  
  // Photos
  List<String> _beforePhotos = [];
  List<String> _afterPhotos = [];
  bool _isUploadingPhoto = false;
  
  // Submission
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAIHelp();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _descriptionController.dispose();
    _materialsController.dispose();
    super.dispose();
  }

  Future<void> _loadAIHelp() async {
    setState(() => _isLoadingAI = true);
    
    try {
      final analysis = await AISolutionService.analyzeIssueForSolutions(
        widget.issue, 
        _beforePhotos,
      );
      
      setState(() {
        _aiAnalysis = analysis;
        _selectedType = _parseSolutionTypeFromString(analysis.suggestedType);
        _selectedDifficulty = analysis.suggestedDifficulty;
        _aiSteps = _parseStepsFromAnalysis(analysis.summary);
        _aiMaterials = _parseMaterialsFromAnalysis(analysis.summary);
      });
    } catch (e) {
      AppHelpers.showErrorSnackBar(context, 'Failed to load AI help: $e');
    } finally {
      setState(() => _isLoadingAI = false);
    }
  }

  List<String> _parseStepsFromAnalysis(String summary) {
    // Simple parsing - in real app, AI would return structured steps
    return [
      'Assess the issue and gather necessary materials',
      'Clean and prepare the area',
      'Apply the solution methodically',
      'Test and verify the fix',
      'Clean up and document the process'
    ];
  }

  List<String> _parseMaterialsFromAnalysis(String summary) {
    // Simple parsing - in real app, AI would return specific materials
    switch (widget.issue.issueType) {
      case 'Pothole':
        return ['Asphalt patch', 'Tamping tool', 'Safety cones', 'Gloves'];
      case 'Broken Streetlight':
        return ['New bulb', 'Ladder', 'Electrical tester', 'Gloves'];
      case 'Garbage':
        return ['Trash bags', 'Gloves', 'Disinfectant', 'Broom'];
      default:
        return ['Basic tools', 'Safety equipment', 'Cleaning supplies'];
    }
  }

  SolutionType _parseSolutionTypeFromString(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'diyfix':
      case 'diy_fix':
        return SolutionType.diyFix;
      case 'workaround':
        return SolutionType.workaround;
      case 'documentation':
        return SolutionType.documentation;
      case 'communityhelp':
      case 'community_help':
        return SolutionType.communityHelp;
      case 'maintenance':
        return SolutionType.maintenance;
      case 'improvement':
        return SolutionType.improvement;
      default:
        return SolutionType.diyFix;
    }
  }

  Future<void> _pickPhoto(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() => _isUploadingPhoto = true);
      
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.user;
        
        if (user == null) {
          AppHelpers.showErrorSnackBar(context, 'Please login to upload photos');
          setState(() => _isUploadingPhoto = false);
          return;
        }
        
        final imageUrl = await CloudinaryStorageService.uploadFile(
          File(pickedFile.path),
          userId: user.id,
          customPath: 'solutions',
        );
        
        if (imageUrl != null) {
          setState(() {
            if (type == 'before') {
              _beforePhotos.add(imageUrl);
            } else {
              _afterPhotos.add(imageUrl);
            }
            _isUploadingPhoto = false;
          });
        } else {
          setState(() => _isUploadingPhoto = false);
          AppHelpers.showErrorSnackBar(context, 'Failed to upload photo: No URL returned');
        }
      } catch (e) {
        setState(() => _isUploadingPhoto = false);
        AppHelpers.showErrorSnackBar(context, 'Failed to upload photo: $e');
      }
    }
  }

  Future<void> _submitSolution() async {
    if (!_formKey.currentState!.validate()) return;
    if (_afterPhotos.isEmpty) {
      AppHelpers.showErrorSnackBar(context, 'Please provide after photos as proof');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      
      if (user == null) {
        AppHelpers.showErrorSnackBar(context, 'Please login to submit solutions');
        return;
      }

      final solution = SolutionModel(
        id: '', // Will be generated by service
        issueId: widget.issue.id,
        userId: user.id,
        userName: user.name,
        userProfileImageUrl: user.profileImageUrl ?? '',
        title: 'Solution for ${widget.issue.title}',
        description: _descriptionController.text,
        images: _afterPhotos,
        type: _selectedType,
        difficulty: _selectedDifficulty,
        materials: _aiMaterials,
        estimatedTime: _estimatedTime,
        estimatedCost: _estimatedCost,
        submittedAt: DateTime.now(),
        status: SolutionStatus.pending,
        verificationPhotos: _afterPhotos,
        tags: [],
        aiAnalysis: {},
        upvotes: 0,
        downvotes: 0,
        voterIds: [],
        comments: [],
        isVerified: false,
        verificationCount: 0,
        successRating: 0.0,
        followUpDates: [],
      );

      await SolutionService.createSolution(solution);
      
      // Update issue status to "Under Review"
      await FirestoreService().updateIssueStatus(widget.issue.id, 'Under Review');
      
      if (mounted) {
        AppHelpers.showSuccessSnackBar(context, 'Solution submitted successfully!');
        Navigator.pop(context, true); // Return true to refresh the feed
      }
    } catch (e) {
      AppHelpers.showErrorSnackBar(context, 'Failed to submit solution: $e');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solve Issue'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.psychology), text: 'AI Help'),
            Tab(icon: Icon(Icons.build), text: 'Solution'),
            Tab(icon: Icon(Icons.photo_camera), text: 'Proof'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4CAF50),
              Color(0xFFE8F5E8),
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildAIHelpTab(),
            _buildSolutionTab(),
            _buildProofTab(),
          ],
        ),
      ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton.extended(
              onPressed: _isSubmitting ? null : _submitSolution,
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(_isSubmitting ? 'Submitting...' : 'Submit Solution'),
            )
          : null,
    );
  }

  Widget _buildAIHelpTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Issue Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.getIssueTypeColor(widget.issue.issueType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        AppHelpers.getIssueTypeEmoji(widget.issue.issueType),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.issue.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            widget.issue.issueType,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.issue.description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // AI Analysis
          if (_isLoadingAI)
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('AI is analyzing the issue...'),
                ],
              ),
            )
          else if (_aiAnalysis != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.psychology,
                        color: Color(0xFF4CAF50),
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AI Analysis',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${(_aiAnalysis!.confidence * 100).toInt()}% confident',
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _aiAnalysis!.summary,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Suggested Steps
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.list_alt,
                        color: Color(0xFF4CAF50),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Suggested Steps',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(_aiSteps.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _aiSteps[index],
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Suggested Materials
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.build,
                        color: Color(0xFF4CAF50),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Required Materials',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _aiMaterials.map((material) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          material,
                          style: const TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSolutionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Solution Type
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Solution Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SolutionType>(
                    value: _selectedType,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: SolutionType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getSolutionTypeLabel(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedType = value!);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Difficulty Level
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Difficulty Level',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DifficultyLevel>(
                    value: _selectedDifficulty,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: DifficultyLevel.values.map((difficulty) {
                      return DropdownMenuItem(
                        value: difficulty,
                        child: Text(_getDifficultyLabel(difficulty)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedDifficulty = value!);
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Solution Description',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: 'Describe how you solved the issue...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please describe your solution';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Time & Cost
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Time (minutes)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: _estimatedTime.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (value) {
                            _estimatedTime = int.tryParse(value) ?? 30;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cost (₹)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: (_estimatedCost / 100).toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          onChanged: (value) {
                            _estimatedCost = ((double.tryParse(value) ?? 0) * 100).round();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProofTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Before Photos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Before Photos (Optional)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                if (_beforePhotos.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _beforePhotos.map((photo) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            photo,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isUploadingPhoto ? null : () => _pickPhoto('before'),
                  icon: _isUploadingPhoto
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_a_photo),
                  label: Text(_isUploadingPhoto ? 'Uploading...' : 'Add Before Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // After Photos (Required)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'After Photos (Required)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'REQUIRED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_afterPhotos.isEmpty)
                  Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.photo_camera,
                            size: 32,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No after photos yet',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _afterPhotos.map((photo) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            photo,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isUploadingPhoto ? null : () => _pickPhoto('after'),
                  icon: _isUploadingPhoto
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_a_photo),
                  label: Text(_isUploadingPhoto ? 'Uploading...' : 'Add After Photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Submission Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Submission Process',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your solution will be reviewed by administrators before being marked as verified. You will receive points and rewards once approved.',
                  style: TextStyle(
                    color: Colors.blue[600],
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getSolutionTypeLabel(SolutionType type) {
    switch (type) {
      case SolutionType.diyFix:
        return 'DIY Fix';
      case SolutionType.workaround:
        return 'Workaround';
      case SolutionType.documentation:
        return 'Documentation';
      case SolutionType.communityHelp:
        return 'Community Help';
      case SolutionType.maintenance:
        return 'Maintenance';
      case SolutionType.improvement:
        return 'Improvement';
    }
  }

  String _getDifficultyLabel(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 'Easy';
      case DifficultyLevel.medium:
        return 'Medium';
      case DifficultyLevel.advanced:
        return 'Advanced';
      case DifficultyLevel.expert:
        return 'Expert';
    }
  }
}
