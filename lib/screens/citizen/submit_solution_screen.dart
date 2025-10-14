import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../services/auth_service.dart';
import '../../services/solution_service.dart';
import '../../services/ai_solution_service.dart';
import '../../models/solution_model.dart';
import '../../models/issue_model.dart';
import '../../utils/helpers.dart';
import '../../test_gemini.dart';

class SubmitSolutionScreen extends StatefulWidget {
  final IssueModel issue;
  final SolutionModel? existingSolution; // For editing

  const SubmitSolutionScreen({
    super.key,
    required this.issue,
    this.existingSolution,
  });

  @override
  State<SubmitSolutionScreen> createState() => _SubmitSolutionScreenState();
}

class _SubmitSolutionScreenState extends State<SubmitSolutionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  SolutionType _selectedType = SolutionType.diyFix;
  DifficultyLevel _selectedDifficulty = DifficultyLevel.easy;
  List<String> _materials = [];
  int _estimatedTime = 60;
  int _estimatedCost = 0;
  List<File> _selectedImages = [];
  bool _isLoading = false;
  AIAnalysisResult? _aiAnalysis;
  List<String> _suggestedTags = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingSolution != null) {
      _loadExistingSolution();
    } else {
      _generateAISuggestions();
    }
  }

  void _loadExistingSolution() {
    final solution = widget.existingSolution!;
    _titleController.text = solution.title;
    _descriptionController.text = solution.description;
    _selectedType = solution.type;
    _selectedDifficulty = solution.difficulty;
    _materials = List.from(solution.materials);
    _estimatedTime = solution.estimatedTime;
    _estimatedCost = solution.estimatedCost;
    _suggestedTags = List.from(solution.tags);
    
    if (solution.aiAnalysis.isNotEmpty) {
      _aiAnalysis = AIAnalysisResult.fromMap(solution.aiAnalysis);
    }
  }

  Future<void> _generateAISuggestions() async {

    try {
      final analysis = await AISolutionService.analyzeIssueForSolutions(
        widget.issue,
        widget.issue.imageUrl != null ? [widget.issue.imageUrl!] : [],
      );
      
      setState(() {
        _aiAnalysis = analysis;
        _selectedType = SolutionType.values.firstWhere(
          (e) => e.toString() == 'SolutionType.${analysis.suggestedType}',
          orElse: () => SolutionType.diyFix,
        );
        _selectedDifficulty = analysis.suggestedDifficulty;
        _materials = List.from(analysis.suggestedMaterials);
        _estimatedTime = analysis.estimatedTime;
        _estimatedCost = analysis.estimatedCost;
      });

      // Generate tags
      final tags = await AISolutionService.generateSolutionTags(
        _titleController.text.isEmpty ? 'Solution for ${widget.issue.title}' : _titleController.text,
        _descriptionController.text.isEmpty ? analysis.summary : _descriptionController.text,
        _selectedType,
      );
      
      setState(() {
        _suggestedTags = tags;
      });

    } catch (e) {
      print('AI generation error: $e');
    } finally {
      // AI generation completed
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images.map((image) => File(image.path)).toList();
        });
      }
    } catch (e) {
      AppHelpers.showErrorSnackBar(context, 'Error picking images: ${e.toString()}');
    }
  }

  Future<void> _submitSolution() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      
      if (user == null) {
        AppHelpers.showErrorSnackBar(context, 'User not authenticated');
        return;
      }

      // Upload images if any
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        // TODO: Implement image upload service
        // For now, we'll skip image upload
        AppHelpers.showSuccessSnackBar(context, 'Images will be uploaded when service is implemented');
      }

      final solution = SolutionModel(
        id: widget.existingSolution?.id ?? '',
        issueId: widget.issue.id,
        userId: user.id,
        userName: user.name,
        userProfileImageUrl: user.profileImageUrl ?? '',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        images: imageUrls,
        type: _selectedType,
        difficulty: _selectedDifficulty,
        materials: _materials,
        estimatedTime: _estimatedTime,
        estimatedCost: _estimatedCost,
        submittedAt: widget.existingSolution?.submittedAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        status: widget.existingSolution?.status ?? SolutionStatus.pending,
        verificationPhotos: [],
        tags: _suggestedTags,
        aiAnalysis: _aiAnalysis?.toMap() ?? {},
        upvotes: widget.existingSolution?.upvotes ?? 0,
        downvotes: widget.existingSolution?.downvotes ?? 0,
        voterIds: widget.existingSolution?.voterIds ?? [],
        comments: widget.existingSolution?.comments ?? [],
        isVerified: widget.existingSolution?.isVerified ?? false,
        verificationCount: widget.existingSolution?.verificationCount ?? 0,
        successRating: widget.existingSolution?.successRating ?? 0.0,
        followUpDates: widget.existingSolution?.followUpDates ?? [],
      );

      bool success;
      if (widget.existingSolution != null) {
        success = await SolutionService.updateSolution(solution);
      } else {
        final solutionId = await SolutionService.createSolution(solution);
        success = solutionId != null;
      }

      if (success) {
        AppHelpers.showSuccessSnackBar(
          context, 
          widget.existingSolution != null 
            ? 'Solution updated successfully!' 
            : 'Solution submitted successfully!'
        );
        Navigator.pop(context, true);
      } else {
        AppHelpers.showErrorSnackBar(context, 'Failed to submit solution');
      }

    } catch (e) {
      AppHelpers.showErrorSnackBar(context, 'Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
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
              // Header
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
                              Text(
                                widget.existingSolution != null ? 'Edit Solution' : 'Submit Solution',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Help solve: ${widget.issue.title}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
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
                                onPressed: () async {
                                  await testGeminiIntegration();
                                },
                                icon: const Icon(Icons.psychology_rounded, color: Colors.white, size: 20),
                                style: IconButton.styleFrom(
                                  padding: const EdgeInsets.all(12),
                                ),
                                tooltip: 'Test Gemini API',
                              ),
                            ),
                            const SizedBox(width: 8),
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
                                onPressed: _isLoading ? null : _submitSolution,
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
                      ],
                    ),
                  ],
                ),
              ),
              
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
                          // AI Suggestions Section
                          if (_aiAnalysis != null) ...[
                            _buildAISuggestionsCard(),
                            const SizedBox(height: 20),
                          ],
                          
                          // Solution Type
                          _buildSolutionTypeField(),
                          const SizedBox(height: 16),
                          
                          // Title Field
                          _buildTitleField(),
                          const SizedBox(height: 16),
                          
                          // Description Field
                          _buildDescriptionField(),
                          const SizedBox(height: 16),
                          
                          // Difficulty Level
                          _buildDifficultyField(),
                          const SizedBox(height: 16),
                          
                          // Materials
                          _buildMaterialsField(),
                          const SizedBox(height: 16),
                          
                          // Time and Cost
                          _buildTimeCostFields(),
                          const SizedBox(height: 16),
                          
                          // Images
                          _buildImagesSection(),
                          const SizedBox(height: 20),
                          
                          // Submit Button
                          _buildSubmitButton(),
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

  Widget _buildAISuggestionsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Suggestions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Spacer(),
              Text(
                '${(_aiAnalysis!.confidence * 100).toInt()}% confidence',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _aiAnalysis!.summary,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2D3748),
            ),
          ),
          if (_aiAnalysis!.safetyWarnings.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '⚠️ Safety: ${_aiAnalysis!.safetyWarnings.first}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSolutionTypeField() {
    return Container(
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
      child: DropdownButtonFormField<SolutionType>(
        value: _selectedType,
        decoration: InputDecoration(
          labelText: 'Solution Type',
          labelStyle: const TextStyle(
            color: Color(0xFF667eea),
            fontWeight: FontWeight.w600,
            fontSize: 14,
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
            ),
            child: const Icon(Icons.build_rounded, color: Color(0xFF667eea), size: 18),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: SolutionType.values.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(_getSolutionTypeDisplayName(type)),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedType = value!;
          });
        },
      ),
    );
  }

  Widget _buildTitleField() {
    return Container(
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
      child: TextFormField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: 'Solution Title',
          labelStyle: const TextStyle(
            color: Color(0xFF667eea),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          hintText: 'Brief description of your solution',
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
            ),
            child: const Icon(Icons.title_rounded, color: Color(0xFF667eea), size: 18),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
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
    );
  }

  Widget _buildDescriptionField() {
    return Container(
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
          hintText: 'Provide step-by-step instructions for your solution',
          alignLabelWithHint: true,
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
            ),
            child: const Icon(Icons.description_rounded, color: Color(0xFF667eea), size: 18),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a description';
          }
          if (value.trim().length < 20) {
            return 'Description must be at least 20 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDifficultyField() {
    return Container(
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
      child: DropdownButtonFormField<DifficultyLevel>(
        value: _selectedDifficulty,
        decoration: InputDecoration(
          labelText: 'Difficulty Level',
          labelStyle: const TextStyle(
            color: Color(0xFF667eea),
            fontWeight: FontWeight.w600,
            fontSize: 14,
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
            ),
            child: const Icon(Icons.speed_rounded, color: Color(0xFF667eea), size: 18),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items: DifficultyLevel.values.map((difficulty) {
          return DropdownMenuItem(
            value: difficulty,
            child: Row(
              children: [
                Text(_getDifficultyEmoji(difficulty)),
                const SizedBox(width: 8),
                Text(_getDifficultyDisplayName(difficulty)),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedDifficulty = value!;
          });
        },
      ),
    );
  }

  Widget _buildMaterialsField() {
    return Container(
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
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF667eea).withOpacity(0.2),
                          const Color(0xFFf093fb).withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_rounded, color: Color(0xFF667eea), size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Materials Needed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _materials.map((material) {
                  return Chip(
                    label: Text(material),
                    onDeleted: () {
                      setState(() {
                        _materials.remove(material);
                      });
                    },
                    deleteIcon: const Icon(Icons.close, size: 18),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Add a material...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty && !_materials.contains(value.trim())) {
                    setState(() {
                      _materials.add(value.trim());
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeCostFields() {
    return Row(
      children: [
        Expanded(
          child: Container(
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
            child: TextFormField(
              initialValue: _estimatedTime.toString(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Time (minutes)',
                labelStyle: const TextStyle(
                  color: Color(0xFF667eea),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.access_time_rounded, color: Color(0xFF667eea)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                _estimatedTime = int.tryParse(value) ?? 60;
              },
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
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
            child: TextFormField(
              initialValue: (_estimatedCost / 100).toStringAsFixed(2),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Cost (\$)',
                labelStyle: const TextStyle(
                  color: Color(0xFF667eea),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(Icons.attach_money_rounded, color: Color(0xFF667eea)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                final cost = double.tryParse(value) ?? 0.0;
                _estimatedCost = (cost * 100).round();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagesSection() {
    return Container(
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
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF667eea).withOpacity(0.2),
                          const Color(0xFFf093fb).withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: Color(0xFF667eea), size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Solution Photos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_selectedImages.isNotEmpty) ...[
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: FileImage(_selectedImages[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.add_photo_alternate_rounded),
                  label: const Text('Add Photos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF667eea),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  Widget _buildSubmitButton() {
    return Container(
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
          onPressed: _isLoading ? null : _submitSolution,
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
                      'Submitting...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 16),
                    Text(
                      widget.existingSolution != null ? 'Update Solution' : 'Submit Solution',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  String _getSolutionTypeDisplayName(SolutionType type) {
    switch (type) {
      case SolutionType.diyFix:
        return '🛠️ DIY Fix';
      case SolutionType.workaround:
        return '🔧 Workaround';
      case SolutionType.documentation:
        return '📋 Documentation';
      case SolutionType.communityHelp:
        return '🤝 Community Help';
      case SolutionType.maintenance:
        return '🔧 Maintenance';
      case SolutionType.improvement:
        return '✨ Improvement';
    }
  }

  String _getDifficultyEmoji(DifficultyLevel difficulty) {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return '🟢';
      case DifficultyLevel.medium:
        return '🟡';
      case DifficultyLevel.advanced:
        return '🟠';
      case DifficultyLevel.expert:
        return '🔴';
    }
  }

  String _getDifficultyDisplayName(DifficultyLevel difficulty) {
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
