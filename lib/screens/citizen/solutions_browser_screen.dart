import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/solution_service.dart';
import '../../models/solution_model.dart';
import '../../models/issue_model.dart';
import '../../utils/helpers.dart';
import 'submit_solution_screen.dart';

class SolutionsBrowserScreen extends StatefulWidget {
  final IssueModel? issue; // Optional - if browsing for specific issue

  const SolutionsBrowserScreen({
    super.key,
    this.issue,
  });

  @override
  State<SolutionsBrowserScreen> createState() => _SolutionsBrowserScreenState();
}

class _SolutionsBrowserScreenState extends State<SolutionsBrowserScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<SolutionModel> _topSolutions = [];
  List<SolutionModel> _recentSolutions = [];
  List<SolutionModel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String _searchQuery = '';
  SolutionType? _selectedType;
  DifficultyLevel? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSolutions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSolutions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final topSolutions = await SolutionService.getTopSolutions(limit: 20);
      final recentSolutions = await SolutionService.getRecentSolutions(limit: 20);

      setState(() {
        _topSolutions = topSolutions;
        _recentSolutions = recentSolutions;
      });
    } catch (e) {
      AppHelpers.showErrorSnackBar(context, 'Error loading solutions: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchSolutions() async {
    if (_searchQuery.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await SolutionService.searchSolutions(
        _searchQuery,
        type: _selectedType,
        difficulty: _selectedDifficulty,
        limit: 50,
      );

      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      AppHelpers.showErrorSnackBar(context, 'Search error: ${e.toString()}');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _voteSolution(SolutionModel solution, bool isUpvote) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    
    if (user == null) {
      AppHelpers.showErrorSnackBar(context, 'Please login to vote');
      return;
    }

    if (solution.voterIds.contains(user.id)) {
      AppHelpers.showErrorSnackBar(context, 'You have already voted on this solution');
      return;
    }

    try {
      final success = await SolutionService.voteSolution(solution.id, user.id, isUpvote);
      
      if (success) {
        setState(() {
          if (isUpvote) {
            solution = solution.copyWith(upvotes: solution.upvotes + 1);
          } else {
            solution = solution.copyWith(downvotes: solution.downvotes + 1);
          }
          solution = solution.copyWith(voterIds: [...solution.voterIds, user.id]);
        });
        
        AppHelpers.showSuccessSnackBar(context, 'Vote recorded!');
      } else {
        AppHelpers.showErrorSnackBar(context, 'Failed to record vote');
      }
    } catch (e) {
      AppHelpers.showErrorSnackBar(context, 'Error voting: ${e.toString()}');
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
                              const Text(
                                'Solutions',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.issue != null 
                                    ? 'Solutions for: ${widget.issue!.title}'
                                    : 'Browse community solutions',
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
                        if (widget.issue != null)
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
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SubmitSolutionScreen(issue: widget.issue!),
                                  ),
                                ).then((_) => _loadSolutions());
                              },
                              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                              style: IconButton.styleFrom(
                                padding: const EdgeInsets.all(12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Search and Filter Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
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
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                          if (value.trim().isNotEmpty) {
                            _searchSolutions();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Search solutions...',
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF667eea)),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                    _searchSolutions();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Filter Chips
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          FilterChip(
                            label: const Text('All Types'),
                            selected: _selectedType == null,
                            onSelected: (selected) {
                              setState(() {
                                _selectedType = null;
                              });
                              if (_searchQuery.isNotEmpty) _searchSolutions();
                            },
                          ),
                          const SizedBox(width: 8),
                          ...SolutionType.values.map((type) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(_getSolutionTypeShortName(type)),
                                selected: _selectedType == type,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedType = selected ? type : null;
                                  });
                                  if (_searchQuery.isNotEmpty) _searchSolutions();
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withOpacity(0.2),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  tabs: const [
                    Tab(text: 'Top Rated'),
                    Tab(text: 'Recent'),
                    Tab(text: 'Search'),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSolutionsList(_topSolutions, 'top'),
                    _buildSolutionsList(_recentSolutions, 'recent'),
                    _buildSolutionsList(_searchResults, 'search'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSolutionsList(List<SolutionModel> solutions, String type) {
    if (_isLoading && (type == 'top' || type == 'recent')) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (_isSearching && type == 'search') {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (solutions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'search' ? Icons.search_off_rounded : Icons.lightbulb_outline_rounded,
              size: 64,
              color: Colors.white.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              type == 'search' 
                  ? 'No solutions found'
                  : type == 'top'
                      ? 'No top solutions yet'
                      : 'No recent solutions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type == 'search'
                  ? 'Try different search terms'
                  : 'Be the first to submit a solution!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: solutions.length,
        itemBuilder: (context, index) {
          final solution = solutions[index];
          return _buildSolutionCard(solution);
        },
      ),
    );
  }

  Widget _buildSolutionCard(SolutionModel solution) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        child: InkWell(
          onTap: () => _showSolutionDetails(solution),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: solution.userProfileImageUrl.isNotEmpty
                          ? NetworkImage(solution.userProfileImageUrl)
                          : null,
                      child: solution.userProfileImageUrl.isEmpty
                          ? Text(
                              solution.userName.isNotEmpty 
                                  ? solution.userName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            solution.userName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          Text(
                            AppHelpers.formatTimeAgo(solution.submittedAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildSolutionTypeChip(solution.type),
                  ],
                ),
                const SizedBox(height: 12),

                // Title and Description
                Text(
                  solution.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  solution.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // Tags
                if (solution.tags.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: solution.tags.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667eea).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            color: const Color(0xFF667eea),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Footer
                Row(
                  children: [
                    _buildDifficultyChip(solution.difficulty),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${solution.estimatedTime}m',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.attach_money_rounded,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '\$${(solution.estimatedCost / 100).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    _buildVoteButtons(solution),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolutionTypeChip(SolutionType type) {
    Color color;
    String text;
    
    switch (type) {
      case SolutionType.diyFix:
        color = Colors.green;
        text = 'DIY';
        break;
      case SolutionType.workaround:
        color = Colors.orange;
        text = 'Workaround';
        break;
      case SolutionType.documentation:
        color = Colors.blue;
        text = 'Docs';
        break;
      case SolutionType.communityHelp:
        color = Colors.purple;
        text = 'Community';
        break;
      case SolutionType.maintenance:
        color = Colors.teal;
        text = 'Maintenance';
        break;
      case SolutionType.improvement:
        color = Colors.pink;
        text = 'Improvement';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(DifficultyLevel difficulty) {
    Color color;
    String text;
    
    switch (difficulty) {
      case DifficultyLevel.easy:
        color = Colors.green;
        text = 'Easy';
        break;
      case DifficultyLevel.medium:
        color = Colors.orange;
        text = 'Medium';
        break;
      case DifficultyLevel.advanced:
        color = Colors.red;
        text = 'Advanced';
        break;
      case DifficultyLevel.expert:
        color = Colors.purple;
        text = 'Expert';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildVoteButtons(SolutionModel solution) {
    return Row(
      children: [
        InkWell(
          onTap: () => _voteSolution(solution, true),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.thumb_up_rounded,
                  size: 16,
                  color: Colors.green[600],
                ),
                const SizedBox(width: 4),
                Text(
                  solution.upvotes.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        InkWell(
          onTap: () => _voteSolution(solution, false),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.thumb_down_rounded,
                  size: 16,
                  color: Colors.red[600],
                ),
                const SizedBox(width: 4),
                Text(
                  solution.downvotes.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSolutionDetails(SolutionModel solution) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Solution details
                Text(
                  solution.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    _buildSolutionTypeChip(solution.type),
                    const SizedBox(width: 8),
                    _buildDifficultyChip(solution.difficulty),
                    const Spacer(),
                    _buildVoteButtons(solution),
                  ],
                ),
                const SizedBox(height: 16),

                Text(
                  solution.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D3748),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Materials section
                if (solution.materials.isNotEmpty) ...[
                  const Text(
                    'Materials Needed',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: solution.materials.map((material) {
                      return Chip(
                        label: Text(material),
                        backgroundColor: const Color(0xFF667eea).withOpacity(0.1),
                        labelStyle: const TextStyle(
                          color: Color(0xFF667eea),
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // Stats
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${solution.estimatedTime}m',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            Text(
                              'Time',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '\$${(solution.estimatedCost / 100).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            Text(
                              'Cost',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.grey[300],
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              solution.successRating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),
                            Text(
                              'Rating',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Implement solution implementation tracking
                          AppHelpers.showSuccessSnackBar(context, 'Solution marked as implemented!');
                        },
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Mark as Implemented'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // TODO: Implement solution reporting
                          AppHelpers.showSuccessSnackBar(context, 'Solution reported!');
                        },
                        icon: const Icon(Icons.flag_rounded),
                        label: const Text('Report'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
    );
  }

  String _getSolutionTypeShortName(SolutionType type) {
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
}
