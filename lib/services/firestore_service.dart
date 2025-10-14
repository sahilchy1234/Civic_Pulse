import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/issue_model.dart';
import '../models/user_model.dart';
import '../models/comment_model.dart';
import '../utils/constants.dart';
import 'leaderboard_service.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LeaderboardService _leaderboardService = LeaderboardService();

  // Issue operations
  Future<String> createIssue(IssueModel issue) async {
    try {
      print('🔥 FirestoreService: Creating issue...');
      print('📊 Issue data: ${issue.toMap()}');
      
      final docRef = await _firestore
          .collection(AppConstants.issuesCollection)
          .add(issue.toMap());
      
      print('✅ Issue document created with ID: ${docRef.id}');
      
      // Update the issue with the generated ID
      await docRef.update({'id': docRef.id});
      print('✅ Issue ID updated successfully');
      
      // Award points for creating the issue
      await _leaderboardService.awardPointsForReport(
        userId: issue.userId,
        issue: issue,
        isFirstInArea: false, // TODO: Implement first-in-area detection
      );
      print('✅ Points awarded for report');
      
      return docRef.id;
    } catch (e) {
      print('❌ FirestoreService: Error creating issue: $e');
      rethrow;
    }
  }

  Future<void> updateIssue(String issueId, Map<String, dynamic> updates) async {
    try {
      // Get the issue before updating to track status changes
      final issue = await getIssue(issueId);
      final oldStatus = issue?.status;
      
      await _firestore
          .collection(AppConstants.issuesCollection)
          .doc(issueId)
          .update({
        ...updates,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      // Award points if status changed
      if (issue != null && updates.containsKey('status')) {
        final newStatus = updates['status'] as String;
        if (oldStatus != null && oldStatus != newStatus) {
          await _leaderboardService.updateStatsForStatusChange(
            issue.userId,
            oldStatus,
            newStatus,
          );
        }
      }
    } catch (e) {
      print('Error updating issue: $e');
      rethrow;
    }
  }

  Future<void> updateIssueStatus(String issueId, String status) async {
    try {
      await _firestore
          .collection(AppConstants.issuesCollection)
          .doc(issueId)
          .update({
        'status': status,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      print('✅ Issue status updated to: $status');
    } catch (e) {
      print('❌ Error updating issue status: $e');
      rethrow;
    }
  }

  Future<void> deleteIssue(String issueId) async {
    try {
      await _firestore
          .collection(AppConstants.issuesCollection)
          .doc(issueId)
          .delete();
    } catch (e) {
      print('Error deleting issue: $e');
      rethrow;
    }
  }

  Future<IssueModel?> getIssue(String issueId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.issuesCollection)
          .doc(issueId)
          .get();
      
      if (doc.exists) {
        return IssueModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting issue: $e');
      return null;
    }
  }

  Stream<List<IssueModel>> getIssuesStream({
    String? status,
    String? issueType,
    String? userId,
    int limit = 50,
  }) {
    Query query = _firestore.collection(AppConstants.issuesCollection);

    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (issueType != null) {
      query = query.where('issueType', isEqualTo: issueType);
    }
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }

    return query
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      try {
        return snapshot.docs
            .map((doc) {
              try {
                return IssueModel.fromMap(doc.data() as Map<String, dynamic>);
              } catch (e) {
                print('❌ Error parsing issue document ${doc.id}: $e');
                print('📄 Document data: ${doc.data()}');
                return null;
              }
            })
            .where((issue) => issue != null)
            .cast<IssueModel>()
            .toList();
      } catch (e) {
        print('❌ Error processing issues snapshot: $e');
        return <IssueModel>[];
      }
    }).handleError((error) {
      print('❌ Firestore stream error: $error');
    });
  }

  Future<List<IssueModel>> getIssues({
    String? status,
    String? issueType,
    String? userId,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection(AppConstants.issuesCollection);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      if (issueType != null) {
        query = query.where('issueType', isEqualTo: issueType);
      }
      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => IssueModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting issues: $e');
      return [];
    }
  }

  Future<void> upvoteIssue(String issueId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.issuesCollection)
          .doc(issueId)
          .update({
        'upvotes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([userId]),
      });
      
      // Award points in background (don't wait for it)
      // _awardPointsInBackground(issueId); // Temporarily disabled to prevent page reloads
    } catch (e) {
      print('Error upvoting issue: $e');
      rethrow;
    }
  }


  Future<void> removeUpvote(String issueId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.issuesCollection)
          .doc(issueId)
          .update({
        'upvotes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([userId]),
      });
      
      // Remove points in background (don't wait for it)
      // _removePointsInBackground(issueId); // Temporarily disabled to prevent page reloads
    } catch (e) {
      print('Error removing upvote: $e');
      rethrow;
    }
  }


  // User operations
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  Stream<UserModel?> getUserStream(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // Update user points
  Future<void> updateUserPoints(String userId, int pointsToAdd) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({
        'points': FieldValue.increment(pointsToAdd),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      // Also update user stats
      await _firestore
          .collection(AppConstants.userStatsCollection)
          .doc(userId)
          .update({
        'points': FieldValue.increment(pointsToAdd),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      print('✅ Updated points for user $userId: +$pointsToAdd');
    } catch (e) {
      print('❌ Error updating user points: $e');
      rethrow;
    }
  }

  // Comment operations
  Future<void> addComment(CommentModel comment) async {
    try {
      await _firestore
          .collection(AppConstants.issuesCollection)
          .doc(comment.issueId)
          .collection('comments')
          .doc(comment.id)
          .set(comment.toMap());
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }

  Stream<List<CommentModel>> getCommentsStream(String issueId) {
    return _firestore
        .collection(AppConstants.issuesCollection)
        .doc(issueId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CommentModel.fromMap(doc.data()))
          .toList();
    });
  }

  Future<void> likeComment(String issueId, String commentId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.issuesCollection)
          .doc(issueId)
          .collection('comments')
          .doc(commentId)
          .update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      print('Error liking comment: $e');
      rethrow;
    }
  }

  Future<void> unlikeComment(String issueId, String commentId, String userId) async {
    try {
      await _firestore
          .collection(AppConstants.issuesCollection)
          .doc(issueId)
          .collection('comments')
          .doc(commentId)
          .update({
        'likes': FieldValue.increment(-1),
        'likedBy': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      print('Error unliking comment: $e');
      rethrow;
    }
  }

  // Analytics operations
  Future<Map<String, int>> getIssueStats() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.issuesCollection)
          .get();

      final stats = <String, int>{
        'total': 0,
        'pending': 0,
        'inProgress': 0,
        'resolved': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data();
        stats['total'] = (stats['total'] ?? 0) + 1;
        
        final status = data['status'] as String?;
        if (status != null) {
          switch (status) {
            case 'Pending':
              stats['pending'] = (stats['pending'] ?? 0) + 1;
              break;
            case 'In Progress':
              stats['inProgress'] = (stats['inProgress'] ?? 0) + 1;
              break;
            case 'Resolved':
              stats['resolved'] = (stats['resolved'] ?? 0) + 1;
              break;
          }
        }
      }

      return stats;
    } catch (e) {
      print('Error getting issue stats: $e');
      return {};
    }
  }

  Future<Map<String, int>> getIssueTypeStats() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.issuesCollection)
          .get();

      final stats = <String, int>{};

      for (final doc in snapshot.docs) {
        final issueType = doc.data()['issueType'] as String?;
        if (issueType != null) {
          stats[issueType] = (stats[issueType] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting issue type stats: $e');
      return {};
    }
  }

  // Search operations
  Future<List<IssueModel>> searchIssues(String query) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.issuesCollection)
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: query + 'z')
          .get();

      return snapshot.docs
          .map((doc) => IssueModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error searching issues: $e');
      return [];
    }
  }
}
