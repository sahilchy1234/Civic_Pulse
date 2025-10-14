import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/badge_model.dart';
import '../../models/leaderboard_entry_model.dart';
import '../../services/leaderboard_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/badge_widget.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  
  UserStats? _userStats;
  List<BadgeModel> _earnedBadges = [];
  List<BadgeModel> _allBadges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.user?.id;

      if (userId != null) {
        final stats = await _leaderboardService.getUserStats(userId);
        final earnedBadges = await _leaderboardService.getUserBadges(userId);
        final allBadges = BadgeModel.getAllBadges();

        setState(() {
          _userStats = stats;
          _earnedBadges = earnedBadges;
          _allBadges = allBadges;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading achievements: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '🏅 Achievements',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats overview
                    _buildStatsOverview(),
                    
                    // Progress section
                    _buildProgressSection(),
                    
                    // Earned badges
                    _buildEarnedBadgesSection(),
                    
                    // All badges
                    _buildAllBadgesSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsOverview() {
    if (_userStats == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF667eea), const Color(0xFF667eea).withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Reports', _userStats!.totalReports.toString(), '📝'),
              _buildStatItem('Resolved', _userStats!.resolvedReports.toString(), '✅'),
              _buildStatItem('Upvotes', _userStats!.totalUpvotes.toString(), '👍'),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white30),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Streak', '${_userStats!.currentStreak} days', '🔥'),
              _buildStatItem('Badges', '${_earnedBadges.length}/${_allBadges.length}', '🏅'),
              _buildStatItem('Rate', '${_userStats!.resolutionRate.toStringAsFixed(0)}%', '⭐'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String emoji) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    if (_userStats == null) return const SizedBox.shrink();

    final nextBadge = _getNextBadgeToEarn();
    if (nextBadge == null) {
      return const SizedBox.shrink();
    }

    final progress = _calculateProgress(nextBadge);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Next Achievement',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(nextBadge.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextBadge.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      nextBadge.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF667eea)),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% complete',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEarnedBadgesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earned Badges (${_earnedBadges.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _earnedBadges.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.stars_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No badges earned yet',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _earnedBadges.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      child: BadgeWidget(
                        badge: _earnedBadges[index],
                        isEarned: true,
                        onTap: () => _showBadgeDetails(_earnedBadges[index], true),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildAllBadgesSection() {
    final lockedBadges = _allBadges.where((badge) {
      return !_earnedBadges.any((earned) => earned.type == badge.type);
    }).toList();

    if (lockedBadges.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Locked Badges (${lockedBadges.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
            ),
            itemCount: lockedBadges.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.all(4),
                child: BadgeWidget(
                  badge: lockedBadges[index],
                  isEarned: false,
                  onTap: () => _showBadgeDetails(lockedBadges[index], false),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  BadgeModel? _getNextBadgeToEarn() {
    if (_userStats == null) return null;

    // Find the next tier badge
    final tierBadges = [
      BadgeType.bronzeCitizen,
      BadgeType.silverGuardian,
      BadgeType.goldChampion,
      BadgeType.platinumHero,
      BadgeType.diamondLegend,
    ];

    for (final badgeType in tierBadges) {
      final badge = _allBadges.firstWhere((b) => b.type == badgeType);
      if (!_earnedBadges.any((e) => e.type == badgeType)) {
        return badge;
      }
    }

    // Find next achievement badge
    for (final badge in _allBadges) {
      if (!_earnedBadges.any((e) => e.type == badge.type)) {
        return badge;
      }
    }

    return null;
  }

  double _calculateProgress(BadgeModel badge) {
    if (_userStats == null) return 0.0;

    switch (badge.type) {
      case BadgeType.bronzeCitizen:
      case BadgeType.silverGuardian:
      case BadgeType.goldChampion:
      case BadgeType.platinumHero:
      case BadgeType.diamondLegend:
        return (_userStats!.totalReports / badge.requiredValue).clamp(0.0, 1.0);
      
      case BadgeType.earlyBird:
        return (_userStats!.earlyBirdReports / badge.requiredValue).clamp(0.0, 1.0);
      
      case BadgeType.nightOwl:
        return (_userStats!.nightOwlReports / badge.requiredValue).clamp(0.0, 1.0);
      
      case BadgeType.categoryExpert:
        return (_userStats!.mostReportedCategoryCount / badge.requiredValue).clamp(0.0, 1.0);
      
      case BadgeType.resolutionChampion:
        return (_userStats!.resolvedReports / badge.requiredValue).clamp(0.0, 1.0);
      
      case BadgeType.streakMaster:
        return (_userStats!.longestStreak / badge.requiredValue).clamp(0.0, 1.0);
      
      case BadgeType.qualityInspector:
        if (_userStats!.totalReports < badge.requiredValue) {
          return (_userStats!.totalReports / badge.requiredValue).clamp(0.0, 1.0);
        }
        return (_userStats!.resolutionRate / 95).clamp(0.0, 1.0);
      
      case BadgeType.impactMaker:
        return (_userStats!.totalUpvotes / badge.requiredValue).clamp(0.0, 1.0);
      
      default:
        return 0.0;
    }
  }

  void _showBadgeDetails(BadgeModel badge, bool isEarned) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                badge.name,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              badge.description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            if (isEarned) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Achievement Unlocked!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Progress: ${(_calculateProgress(badge) * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _calculateProgress(badge),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF667eea)),
                  minHeight: 8,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

