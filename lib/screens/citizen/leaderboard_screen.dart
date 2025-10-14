import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../models/leaderboard_entry_model.dart';
import '../../services/leaderboard_service.dart';
import '../../services/auth_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LeaderboardService _leaderboardService = LeaderboardService();
  
  String _selectedPeriod = 'all';
  List<LeaderboardEntryModel> _leaderboardData = [];
  LeaderboardEntryModel? _currentUserEntry;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initializeAndLoadLeaderboard();
  }

  Future<void> _initializeAndLoadLeaderboard() async {
    try {
      // Debug database state first
      await _leaderboardService.debugDatabaseState();
      
      // Fix generic user names first
      await _leaderboardService.fixGenericUserNames();
      
      // Then, ensure all users have stats initialized
      await _leaderboardService.initializeAllUserStats();
      // Finally load the leaderboard
      await _loadLeaderboard();
    } catch (e) {
      print('❌ Error initializing and loading leaderboard: $e');
      // Still try to load leaderboard even if initialization fails
      await _loadLeaderboard();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    
    setState(() {
      switch (_tabController.index) {
        case 0:
          _selectedPeriod = 'daily';
          break;
        case 1:
          _selectedPeriod = 'weekly';
          break;
        case 2:
          _selectedPeriod = 'monthly';
          break;
        case 3:
          _selectedPeriod = 'all';
          break;
      }
    });
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);

    try {
      print('🔄 Loading leaderboard...');
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUserId = authService.user?.id;

      final data = await _leaderboardService.getLeaderboard(
        period: _selectedPeriod,
        limit: 100,
      );

      print('📊 Loaded ${data.length} leaderboard entries');

      if (currentUserId != null) {
        _currentUserEntry = data.firstWhere(
          (entry) => entry.userId == currentUserId,
          orElse: () => LeaderboardEntryModel(
            userId: currentUserId,
            userName: authService.user?.name ?? 'You',
            points: 0,
            rank: 0,
            totalReports: 0,
            resolvedReports: 0,
            totalUpvotes: 0,
            lastActive: DateTime.now(),
          ),
        );
        print('👤 Current user entry: ${_currentUserEntry!.userName} - ${_currentUserEntry!.points} points');
      }

      setState(() {
        _leaderboardData = data;
        _isLoading = false;
      });
      
      print('✅ Leaderboard loaded successfully');
    } catch (e) {
      print('❌ Error loading leaderboard: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '🏆 Leaderboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'All Time'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadLeaderboard,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Current user card
                  if (_currentUserEntry != null) _buildCurrentUserCard(),
                  
                  // Top 3 podium
                  if (_leaderboardData.length >= 3) _buildPodium(),
                  
                  // Leaderboard list
                  Expanded(
                    child: _leaderboardData.isEmpty
                        ? _buildEmptyState()
                        : _buildLeaderboardList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCurrentUserCard() {
    if (_currentUserEntry == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _currentUserEntry!.rank > 0 ? '#${_currentUserEntry!.rank}' : '--',
                style: TextStyle(
                  color: const Color(0xFF667eea),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Rank',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  _currentUserEntry!.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Points
          Column(
            children: [
              Text(
                '${_currentUserEntry!.points}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'points',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    final top3 = _leaderboardData.take(3).toList();
    if (top3.length < 3) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place
          _buildPodiumPlace(top3[1], 2, 120, Colors.grey.shade400),
          const SizedBox(width: 16),
          // 1st place
          _buildPodiumPlace(top3[0], 1, 150, Colors.amber),
          const SizedBox(width: 16),
          // 3rd place
          _buildPodiumPlace(top3[2], 3, 100, Colors.brown.shade400),
        ],
      ),
    );
  }

  Widget _buildPodiumPlace(
    LeaderboardEntryModel entry,
    int place,
    double height,
    Color color,
  ) {
    String medal = place == 1
        ? '🥇'
        : place == 2
            ? '🥈'
            : '🥉';

    return Column(
      children: [
        // Profile picture with medal
        Stack(
          alignment: Alignment.topCenter,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: CircleAvatar(
                radius: 35,
                backgroundColor: color.withOpacity(0.3),
                backgroundImage: entry.profileImageUrl != null
                    ? CachedNetworkImageProvider(entry.profileImageUrl!)
                    : null,
                child: entry.profileImageUrl == null
                    ? Text(
                        entry.userName.isNotEmpty
                            ? entry.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            Text(medal, style: const TextStyle(fontSize: 32)),
          ],
        ),
        const SizedBox(height: 8),
        
        // Name
        SizedBox(
          width: 90,
          child: Text(
            entry.userName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Badge
        if (entry.currentBadge != null)
          Text(entry.currentBadge!, style: const TextStyle(fontSize: 20)),
        
        // Points
        Text(
          '${entry.points} pts',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        
        // Podium
        Container(
          width: 90,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$place',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${entry.totalReports} reports',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardList() {
    // Start from 4th place if we have a podium, otherwise show all
    final startIndex = _leaderboardData.length >= 3 ? 3 : 0;
    final listData = _leaderboardData.sublist(startIndex);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: listData.length,
      itemBuilder: (context, index) {
        final entry = listData[index];
        final isCurrentUser = _currentUserEntry?.userId == entry.userId;
        
        return _buildLeaderboardCard(entry, isCurrentUser);
      },
    );
  }

  Widget _buildLeaderboardCard(LeaderboardEntryModel entry, bool isCurrentUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? const Color(0xFF667eea).withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: const Color(0xFF667eea), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rank
            SizedBox(
              width: 40,
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: entry.rank <= 10 ? const Color(0xFF667eea) : Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Profile picture
            CircleAvatar(
              radius: 25,
              backgroundColor: const Color(0xFF667eea).withOpacity(0.2),
              backgroundImage: entry.profileImageUrl != null
                  ? CachedNetworkImageProvider(entry.profileImageUrl!)
                  : null,
              child: entry.profileImageUrl == null
                  ? Text(
                      entry.userName.isNotEmpty
                          ? entry.userName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.userName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (entry.currentBadge != null)
              Text(entry.currentBadge!, style: const TextStyle(fontSize: 20)),
          ],
        ),
        subtitle: Text(
          '${entry.totalReports} reports • ${entry.resolvedReports} resolved • ${entry.totalUpvotes} upvotes',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.points}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF667eea),
              ),
            ),
            Text(
              'points',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.leaderboard_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No leaderboard data yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to report issues!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

