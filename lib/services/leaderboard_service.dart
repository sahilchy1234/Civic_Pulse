import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/issue_model.dart';
import '../models/leaderboard_entry_model.dart';
import '../models/badge_model.dart';
import '../utils/constants.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Point values for different actions
  static const int pointsReportIssue = 10;
  static const int pointsIssueVerified = 25;
  static const int pointsIssueResolved = 50;
  static const int pointsFirstReport = 15;
  static const int pointsWithPhoto = 5;
  static const int pointsDetailedDescription = 5;
  static const int pointsUpdateIssue = 8;
  static const int pointsReceiveUpvote = 1;
  static const int pointsWeeklyActive = 20;
  static const int pointsDuplicateReport = -5;

  // Initialize user stats when they first sign up
  Future<void> initializeUserStats(String userId) async {
    try {
      final statsDoc = await _firestore
          .collection('userStats')
          .doc(userId)
          .get();

      if (!statsDoc.exists) {
        final stats = UserStats(
          userId: userId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _firestore
            .collection('userStats')
            .doc(userId)
            .set(stats.toMap());
        print('✅ Initialized user stats for user: $userId');
      }
    } catch (e) {
      print('❌ Error initializing user stats: $e');
    }
  }

  // Initialize stats for all existing users who don't have stats
  Future<void> initializeAllUserStats() async {
    try {
      print('🔄 Checking all users for missing stats...');
      
      // Get all users
      final usersSnapshot = await _firestore.collection(AppConstants.usersCollection).get();
      print('📊 Found ${usersSnapshot.docs.length} total users');
      
      int initializedCount = 0;
      
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final statsDoc = await _firestore.collection('userStats').doc(userId).get();
        
        if (!statsDoc.exists) {
          await initializeUserStats(userId);
          initializedCount++;
        }
      }
      
      print('✅ Initialized stats for $initializedCount users');
    } catch (e) {
      print('❌ Error initializing all user stats: $e');
    }
  }

  // Fix existing users who have generic "User" names
  Future<void> fixGenericUserNames() async {
    try {
      print('🔧 Fixing generic user names...');
      
      // Get all users
      final usersSnapshot = await _firestore.collection(AppConstants.usersCollection).get();
      print('📊 Found ${usersSnapshot.docs.length} total users');
      
      int fixedCount = 0;
      
      for (var userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final currentName = userData['name'] ?? '';
        final email = userData['email'] ?? '';
        
        // Check if user has generic name
        if (currentName == 'User' && email.isNotEmpty) {
          // Extract name from email
          final emailParts = email.split('@');
          if (emailParts.isNotEmpty) {
            String newName = emailParts[0].replaceAll('.', ' ').replaceAll('_', ' ');
            // Capitalize first letter of each word
            newName = newName.split(' ').map((word) => 
              word.isNotEmpty ? word[0].toUpperCase() + word.substring(1).toLowerCase() : ''
            ).join(' ');
            
            // Update the user's name
            await _firestore.collection(AppConstants.usersCollection).doc(userDoc.id).update({
              'name': newName,
            });
            
            print('✅ Fixed user ${userDoc.id}: "$currentName" -> "$newName"');
            fixedCount++;
          }
        }
      }
      
      print('✅ Fixed names for $fixedCount users');
    } catch (e) {
      print('❌ Error fixing generic user names: $e');
    }
  }

  // Award points for reporting an issue
  Future<void> awardPointsForReport({
    required String userId,
    required IssueModel issue,
    bool isFirstInArea = false,
  }) async {
    try {
      int pointsToAward = pointsReportIssue;

      // Bonus for photo
      if (issue.imageUrl != null && issue.imageUrl!.isNotEmpty) {
        pointsToAward += pointsWithPhoto;
      }

      // Bonus for detailed description
      if (issue.description.length > 100) {
        pointsToAward += pointsDetailedDescription;
      }

      // Bonus for being first reporter in area
      if (isFirstInArea) {
        pointsToAward += pointsFirstReport;
      }

      // Check if early bird or night owl
      final hour = issue.createdAt.hour;
      final isEarlyBird = hour >= 5 && hour < 8;
      final isNightOwl = hour >= 22 || hour < 5;

      // Update user points
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'points': FieldValue.increment(pointsToAward),
      });

      // Update user stats
      await _updateUserStats(
        userId,
        issue,
        isEarlyBird: isEarlyBird,
        isNightOwl: isNightOwl,
      );

      print('✅ Awarded $pointsToAward points to user $userId');
    } catch (e) {
      print('❌ Error awarding points: $e');
    }
  }

  // Update user stats when they report an issue
  Future<void> _updateUserStats(
    String userId,
    IssueModel issue, {
    bool isEarlyBird = false,
    bool isNightOwl = false,
  }) async {
    try {
      final statsRef = _firestore.collection('userStats').doc(userId);
      final statsDoc = await statsRef.get();

      if (!statsDoc.exists) {
        await initializeUserStats(userId);
      }

      final stats = statsDoc.exists
          ? UserStats.fromMap(statsDoc.data()!)
          : UserStats(
              userId: userId,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

      // Calculate streak
      final now = DateTime.now();
      final lastReport = stats.lastReportDate;
      int newStreak = stats.currentStreak;

      if (lastReport != null) {
        final daysSinceLastReport = now.difference(lastReport).inDays;
        if (daysSinceLastReport == 1) {
          newStreak += 1;
        } else if (daysSinceLastReport > 1) {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }

      final longestStreak = newStreak > stats.longestStreak ? newStreak : stats.longestStreak;

      // Update category count
      final updatedCategories = Map<String, int>.from(stats.categoryReports);
      updatedCategories[issue.issueType] = (updatedCategories[issue.issueType] ?? 0) + 1;

      // Update stats
      await statsRef.update({
        'totalReports': FieldValue.increment(1),
        'pendingReports': FieldValue.increment(1),
        'currentStreak': newStreak,
        'longestStreak': longestStreak,
        'earlyBirdReports': isEarlyBird ? FieldValue.increment(1) : stats.earlyBirdReports,
        'nightOwlReports': isNightOwl ? FieldValue.increment(1) : stats.nightOwlReports,
        'categoryReports': updatedCategories,
        'lastReportDate': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      });

      // Check and award badges
      await _checkAndAwardBadges(userId, statsRef);
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  // Award points when issue is resolved
  Future<void> awardPointsForResolution(String userId, String issueId) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'points': FieldValue.increment(pointsIssueResolved),
      });

      // Update stats
      await _firestore
          .collection('userStats')
          .doc(userId)
          .update({
        'resolvedReports': FieldValue.increment(1),
        'pendingReports': FieldValue.increment(-1),
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      print('✅ Awarded $pointsIssueResolved points for resolution');
    } catch (e) {
      print('Error awarding resolution points: $e');
    }
  }

  // Award points when issue status changes
  Future<void> updateStatsForStatusChange(
    String userId,
    String oldStatus,
    String newStatus,
  ) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (oldStatus == 'Pending' && newStatus == 'In Progress') {
        updates['pendingReports'] = FieldValue.increment(-1);
        updates['inProgressReports'] = FieldValue.increment(1);
      } else if (oldStatus == 'In Progress' && newStatus == 'Resolved') {
        updates['inProgressReports'] = FieldValue.increment(-1);
        updates['resolvedReports'] = FieldValue.increment(1);
        // Award resolution points
        await awardPointsForResolution(userId, '');
      } else if (oldStatus == 'Pending' && newStatus == 'Resolved') {
        updates['pendingReports'] = FieldValue.increment(-1);
        updates['resolvedReports'] = FieldValue.increment(1);
        // Award resolution points
        await awardPointsForResolution(userId, '');
      }

      if (updates.length > 1) {
        await _firestore.collection('userStats').doc(userId).update(updates);
      }
    } catch (e) {
      print('Error updating stats for status change: $e');
    }
  }

  // Award points for receiving upvotes
  Future<void> awardPointsForUpvote(String userId) async {
    try {
      // Update user points (create if doesn't exist)
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .set({
        'points': FieldValue.increment(pointsReceiveUpvote),
      }, SetOptions(merge: true));

      // Update user stats (create if doesn't exist)
      await _firestore.collection('userStats').doc(userId).set({
        'totalUpvotes': FieldValue.increment(1),
        'userId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error awarding upvote points: $e');
    }
  }

  // Remove points for upvote removal
  Future<void> removePointsForUpvote(String userId) async {
    try {
      // Update user points (create if doesn't exist)
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .set({
        'points': FieldValue.increment(-pointsReceiveUpvote),
      }, SetOptions(merge: true));

      // Update user stats (create if doesn't exist)
      await _firestore.collection('userStats').doc(userId).set({
        'totalUpvotes': FieldValue.increment(-1),
        'userId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error removing upvote points: $e');
    }
  }

  // Check and award badges based on achievements
  Future<void> _checkAndAwardBadges(
    String userId,
    DocumentReference statsRef,
  ) async {
    try {
      final statsDoc = await statsRef.get();
      if (!statsDoc.exists) return;

      final stats = UserStats.fromMap(statsDoc.data() as Map<String, dynamic>);
      final earnedBadges = List<String>.from(stats.earnedBadges);
      bool badgesUpdated = false;

      // Check tier badges
      final tierBadge = BadgeModel.getTierBadge(stats.totalReports);
      if (tierBadge != null && !earnedBadges.contains(tierBadge.type.toString())) {
        earnedBadges.add(tierBadge.type.toString());
        badgesUpdated = true;
      }

      // Check early bird badge
      if (stats.earlyBirdReports >= 5 && !earnedBadges.contains(BadgeType.earlyBird.toString())) {
        earnedBadges.add(BadgeType.earlyBird.toString());
        badgesUpdated = true;
      }

      // Check night owl badge
      if (stats.nightOwlReports >= 5 && !earnedBadges.contains(BadgeType.nightOwl.toString())) {
        earnedBadges.add(BadgeType.nightOwl.toString());
        badgesUpdated = true;
      }

      // Check category expert badge
      if (stats.mostReportedCategoryCount >= 20 &&
          !earnedBadges.contains(BadgeType.categoryExpert.toString())) {
        earnedBadges.add(BadgeType.categoryExpert.toString());
        badgesUpdated = true;
      }

      // Check resolution champion badge
      if (stats.resolvedReports >= 10 &&
          !earnedBadges.contains(BadgeType.resolutionChampion.toString())) {
        earnedBadges.add(BadgeType.resolutionChampion.toString());
        badgesUpdated = true;
      }

      // Check streak master badge
      if (stats.currentStreak >= 30 &&
          !earnedBadges.contains(BadgeType.streakMaster.toString())) {
        earnedBadges.add(BadgeType.streakMaster.toString());
        badgesUpdated = true;
      }

      // Check quality inspector badge
      if (stats.resolutionRate >= 95 &&
          stats.totalReports >= 20 &&
          !earnedBadges.contains(BadgeType.qualityInspector.toString())) {
        earnedBadges.add(BadgeType.qualityInspector.toString());
        badgesUpdated = true;
      }

      // Check impact maker badge
      if (stats.totalUpvotes >= 100 &&
          !earnedBadges.contains(BadgeType.impactMaker.toString())) {
        earnedBadges.add(BadgeType.impactMaker.toString());
        badgesUpdated = true;
      }

      if (badgesUpdated) {
        await statsRef.update({
          'earnedBadges': earnedBadges,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
        print('✅ New badges awarded to user $userId');
      }
    } catch (e) {
      print('Error checking and awarding badges: $e');
    }
  }

  // Get leaderboard entries with time period filter
  Future<List<LeaderboardEntryModel>> getLeaderboard({
    String period = 'all', // 'daily', 'weekly', 'monthly', 'all'
    int limit = 100,
  }) async {
    try {
      print('🏆 Getting leaderboard data...');
      
      // First, let's check if we have any users at all
      final allUsersSnapshot = await _firestore.collection(AppConstants.usersCollection).get();
      print('📊 Total users in database: ${allUsersSnapshot.docs.length}');
      
      if (allUsersSnapshot.docs.isEmpty) {
        print('⚠️ No users found in database');
        return [];
      }

      // Log user data for debugging
      for (var doc in allUsersSnapshot.docs) {
        final userData = doc.data();
        print('👤 User: ${userData['name']} - Role: ${userData['role']} - Points: ${userData['points']}');
      }

      Query query = _firestore.collection(AppConstants.usersCollection);

      // For time-based leaderboards, we'd need to track points per period
      // For now, we'll use total points and filter by role
      query = query
          .where('role', isEqualTo: AppConstants.citizenRole)
          .orderBy('points', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      print('📈 Found ${snapshot.docs.length} citizen users');
      
      final entries = <LeaderboardEntryModel>[];

      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final userData = doc.data() as Map<String, dynamic>;
        
        print('🔄 Processing user ${i + 1}: ${userData['name']}');
        
        // Get user stats
        final statsDoc = await _firestore
            .collection('userStats')
            .doc(doc.id)
            .get();

        final stats = statsDoc.exists
            ? UserStats.fromMap(statsDoc.data()!)
            : UserStats(
                userId: doc.id,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

        print('📊 User stats - Reports: ${stats.totalReports}, Resolved: ${stats.resolvedReports}, Upvotes: ${stats.totalUpvotes}');

        // Get tier badge
        final tierBadge = BadgeModel.getTierBadge(stats.totalReports);

        final entry = LeaderboardEntryModel(
          userId: doc.id,
          userName: userData['name'] ?? 'Anonymous',
          profileImageUrl: userData['profileImageUrl'],
          points: userData['points'] ?? 0,
          rank: i + 1,
          totalReports: stats.totalReports,
          resolvedReports: stats.resolvedReports,
          totalUpvotes: stats.totalUpvotes,
          currentBadge: tierBadge?.emoji,
          lastActive: stats.updatedAt,
        );
        
        entries.add(entry);
        print('✅ Added entry: ${entry.userName} - ${entry.points} points - ${entry.totalReports} reports');
      }

      print('🏆 Leaderboard complete with ${entries.length} entries');
      return entries;
    } catch (e) {
      print('❌ Error getting leaderboard: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  // Get user's rank
  Future<int> getUserRank(String userId) async {
    try {
      final userDoc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!userDoc.exists) return 0;

      final userPoints = userDoc.data()?['points'] ?? 0;

      final higherRankedUsers = await _firestore
          .collection(AppConstants.usersCollection)
          .where('role', isEqualTo: AppConstants.citizenRole)
          .where('points', isGreaterThan: userPoints)
          .get();

      return higherRankedUsers.docs.length + 1;
    } catch (e) {
      print('Error getting user rank: $e');
      return 0;
    }
  }

  // Get user stats
  Future<UserStats?> getUserStats(String userId) async {
    try {
      final doc = await _firestore.collection('userStats').doc(userId).get();

      if (doc.exists) {
        return UserStats.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user stats: $e');
      return null;
    }
  }

  // Get user's earned badges
  Future<List<BadgeModel>> getUserBadges(String userId) async {
    try {
      final stats = await getUserStats(userId);
      if (stats == null) return [];

      final allBadges = BadgeModel.getAllBadges();
      final earnedBadges = <BadgeModel>[];

      for (final badgeTypeStr in stats.earnedBadges) {
        final badgeType = BadgeType.values.firstWhere(
          (e) => e.toString() == badgeTypeStr,
          orElse: () => BadgeType.bronzeCitizen,
        );
        
        final badge = allBadges.firstWhere(
          (b) => b.type == badgeType,
          orElse: () => allBadges.first,
        );

        earnedBadges.add(badge);
      }

      return earnedBadges;
    } catch (e) {
      print('Error getting user badges: $e');
      return [];
    }
  }

  // Get nearby users (can be used for local leaderboards)
  Future<List<LeaderboardEntryModel>> getNearbyLeaderboard({
    required double latitude,
    required double longitude,
    double radiusInKm = 10.0,
    int limit = 50,
  }) async {
    // This is a simplified version
    // For production, you'd want to use geohashing or GeoFirestore
    return getLeaderboard(limit: limit);
  }

  // Update user name
  Future<void> updateUserName(String userId, String newName) async {
    try {
      await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
        'name': newName,
      });
      print('✅ Updated user name: $userId -> $newName');
    } catch (e) {
      print('❌ Error updating user name: $e');
    }
  }

  // Debug method to check database state
  Future<void> debugDatabaseState() async {
    try {
      print('🔍 DEBUG: Checking database state...');
      
      // Check users collection
      final usersSnapshot = await _firestore.collection(AppConstants.usersCollection).get();
      print('👥 Users collection: ${usersSnapshot.docs.length} documents');
      
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        print('   - ${data['name']} (${data['role']}) - ${data['points']} points');
      }
      
      // Check userStats collection
      final statsSnapshot = await _firestore.collection('userStats').get();
      print('📊 UserStats collection: ${statsSnapshot.docs.length} documents');
      
      for (var doc in statsSnapshot.docs) {
        final data = doc.data();
        print('   - User ${doc.id}: ${data['totalReports']} reports, ${data['resolvedReports']} resolved');
      }
      
      // Check if there are any issues
      final issuesSnapshot = await _firestore.collection(AppConstants.issuesCollection).get();
      print('🐛 Issues collection: ${issuesSnapshot.docs.length} documents');
      
    } catch (e) {
      print('❌ Debug error: $e');
    }
  }

  // Stream of leaderboard updates
  Stream<List<LeaderboardEntryModel>> getLeaderboardStream({int limit = 50}) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: AppConstants.citizenRole)
        .orderBy('points', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      print('🔄 Stream update: ${snapshot.docs.length} users');
      final entries = <LeaderboardEntryModel>[];

      for (int i = 0; i < snapshot.docs.length; i++) {
        final doc = snapshot.docs[i];
        final userData = doc.data();

        // Get user stats
        final statsDoc = await _firestore
            .collection('userStats')
            .doc(doc.id)
            .get();

        final stats = statsDoc.exists
            ? UserStats.fromMap(statsDoc.data()!)
            : UserStats(
                userId: doc.id,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

        final tierBadge = BadgeModel.getTierBadge(stats.totalReports);

        entries.add(LeaderboardEntryModel(
          userId: doc.id,
          userName: userData['name'] ?? 'Anonymous',
          profileImageUrl: userData['profileImageUrl'],
          points: userData['points'] ?? 0,
          rank: i + 1,
          totalReports: stats.totalReports,
          resolvedReports: stats.resolvedReports,
          totalUpvotes: stats.totalUpvotes,
          currentBadge: tierBadge?.emoji,
          lastActive: stats.updatedAt,
        ));
      }

      return entries;
    });
  }
}

