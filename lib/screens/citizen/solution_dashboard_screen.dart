import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/solution_model.dart';
import '../../models/issue_model.dart';
import '../../services/solution_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/helpers.dart';

class SolutionDashboardScreen extends StatefulWidget {
  const SolutionDashboardScreen({super.key});

  @override
  State<SolutionDashboardScreen> createState() => _SolutionDashboardScreenState();
}

class _SolutionDashboardScreenState extends State<SolutionDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  
  List<SolutionModel> _verifiedSolutions = [];
  Map<String, IssueModel> _issuesMap = {};
  Map<String, int> _userStats = {};
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    print('🚀 SolutionDashboardScreen: initState called');
    _tabController = TabController(length: 2, vsync: this);
    _loadSolutions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSolutions() async {
    setState(() => _isLoading = true);
    
    try {
      print('🔍 Getting solution debug info...');
      await SolutionService.getSolutionDebugInfo();
      
      print('🔍 Loading verified solutions...');
      final solutions = await SolutionService.getVerifiedSolutions();
      print('📊 Found ${solutions.length} verified solutions');
      
      print('🔍 Loading all solutions for comparison...');
      final allSolutions = await SolutionService.getAllSolutions();
      print('📊 Found ${allSolutions.length} total solutions');
      
      print('🔍 Loading issues...');
      final issues = await _firestoreService.getIssues();
      print('📊 Found ${issues.length} issues');
      
      // Create issues map for quick lookup
      final issuesMap = <String, IssueModel>{};
      for (final issue in issues) {
        issuesMap[issue.id] = issue;
      }
      
      // Calculate user stats
      final userStats = <String, int>{};
      for (final solution in solutions) {
        userStats[solution.userId] = (userStats[solution.userId] ?? 0) + 1;
      }
      
      print('✅ Solutions loaded successfully');
      print('📈 User stats: ${userStats.length} contributors');
      
      setState(() {
        _verifiedSolutions = solutions;
        _issuesMap = issuesMap;
        _userStats = userStats;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading solutions: $e');
      setState(() => _isLoading = false);
      AppHelpers.showErrorSnackBar(context, 'Failed to load solutions: $e');
    }
  }

  List<SolutionModel> get _filteredSolutions {
    if (_selectedFilter == 'All') {
      return _verifiedSolutions;
    }
    
    return _verifiedSolutions.where((solution) {
      final issue = _issuesMap[solution.issueId];
      return issue?.issueType == _selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    print('🏗️ SolutionDashboardScreen: build called, isLoading: $_isLoading');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solution Dashboard'),
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _selectedFilter = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Types')),
              const PopupMenuItem(value: 'Pothole', child: Text('Pothole')),
              const PopupMenuItem(value: 'Broken Streetlight', child: Text('Streetlight')),
              const PopupMenuItem(value: 'Garbage', child: Text('Garbage')),
              const PopupMenuItem(value: 'Other', child: Text('Other')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: 'Solutions'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
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
            _buildSolutionsTab(),
            _buildLeaderboardTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionsTab() {
    print('🏗️ _buildSolutionsTab called, isLoading: $_isLoading, solutions count: ${_verifiedSolutions.length}');
    
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading solutions...'),
          ],
        ),
      );
    }

    if (_filteredSolutions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No verified solutions yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Solutions need to be verified by authorities before appearing here.',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to solve issue screen
                  Navigator.pushNamed(context, '/solve-issue');
                },
                icon: const Icon(Icons.build),
                label: const Text('Submit a Solution'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Stats Header
        Container(
          margin: const EdgeInsets.all(16),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.check_circle,
                label: 'Total Solved',
                value: '${_verifiedSolutions.length}',
                color: Colors.green,
              ),
              _buildStatItem(
                icon: Icons.people,
                label: 'Contributors',
                value: '${_userStats.length}',
                color: Colors.blue,
              ),
              _buildStatItem(
                icon: Icons.emoji_events,
                label: 'Total Points',
                value: '${_verifiedSolutions.length * 50}',
                color: Colors.orange,
              ),
            ],
          ),
        ),
        
        // Solutions List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filteredSolutions.length,
            itemBuilder: (context, index) {
              final solution = _filteredSolutions[index];
              final issue = _issuesMap[solution.issueId];
              return _buildSolutionCard(solution, issue);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final sortedUsers = _userStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No contributors yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedUsers.length,
      itemBuilder: (context, index) {
        final user = sortedUsers[index];
        final rank = index + 1;
        return _buildLeaderboardItem(user.key, user.value, rank);
      },
    );
  }

  Widget _buildSolutionCard(SolutionModel solution, IssueModel? issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        solution.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (issue != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              AppHelpers.getIssueTypeEmoji(issue.issueType),
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              issue.issueType,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Solved',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description
                Text(
                  solution.description,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 12),
                
                // Solution Details
                Row(
                  children: [
                    _buildDetailChip(
                      icon: Icons.build,
                      label: _getSolutionTypeLabel(solution.type),
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildDetailChip(
                      icon: Icons.schedule,
                      label: '${solution.estimatedTime}m',
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    _buildDetailChip(
                      icon: Icons.currency_rupee,
                      label: '${(solution.estimatedCost / 100).toStringAsFixed(0)}',
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _buildDetailChip(
                      icon: Icons.emoji_events,
                      label: '+50 pts',
                      color: Colors.purple,
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Before/After Photos
                if (solution.verificationPhotos.isNotEmpty) ...[
                  const Text(
                    'Solution Photos:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: solution.verificationPhotos.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: solution.verificationPhotos[index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(String userId, int solutionsCount, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          // Rank
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User ${userId.substring(0, 8)}...',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '$solutionsCount solutions solved',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Points
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Colors.orange,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${solutionsCount * 50}',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _getSolutionTypeLabel(SolutionType type) {
    switch (type) {
      case SolutionType.diyFix:
        return 'DIY Fix';
      case SolutionType.workaround:
        return 'Workaround';
      case SolutionType.maintenance:
        return 'Maintenance';
      case SolutionType.documentation:
        return 'Documentation';
      case SolutionType.communityHelp:
        return 'Community Help';
      case SolutionType.improvement:
        return 'Improvement';
    }
  }
}
