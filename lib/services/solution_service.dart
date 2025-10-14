import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/solution_model.dart';
import '../models/issue_model.dart';
import 'ai_solution_service.dart';

class SolutionService {
  static const String _collection = 'solutions';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new solution
  static Future<String?> createSolution(SolutionModel solution) async {
    try {
      final docRef = await _firestore.collection(_collection).add(solution.toMap());
      
      // Update the solution with its ID
      await docRef.update({'id': docRef.id});
      
      return docRef.id;
    } catch (e) {
      print('Error creating solution: $e');
      return null;
    }
  }

  /// Get solution by ID
  static Future<SolutionModel?> getSolution(String solutionId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(solutionId).get();
      
      if (doc.exists) {
        return SolutionModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting solution: $e');
      return null;
    }
  }

  /// Get solutions for a specific issue
  static Future<List<SolutionModel>> getSolutionsForIssue(String issueId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('issueId', isEqualTo: issueId)
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SolutionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting solutions for issue: $e');
      return [];
    }
  }

  /// Get solutions by user
  static Future<List<SolutionModel>> getSolutionsByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SolutionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting solutions by user: $e');
      return [];
    }
  }

  /// Get top-rated solutions
  static Future<List<SolutionModel>> getTopSolutions({
    int limit = 10,
    SolutionType? type,
    DifficultyLevel? difficulty,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('status', isEqualTo: SolutionStatus.verified.toString())
          .where('isVerified', isEqualTo: true);

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString());
      }

      if (difficulty != null) {
        query = query.where('difficulty', isEqualTo: difficulty.toString());
      }

      final querySnapshot = await query.limit(limit).get();

      return querySnapshot.docs
          .map((doc) => SolutionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting top solutions: $e');
      return [];
    }
  }

  /// Get recent solutions
  static Future<List<SolutionModel>> getRecentSolutions({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: SolutionStatus.approved.toString())
          .orderBy('submittedAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => SolutionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting recent solutions: $e');
      return [];
    }
  }

  /// Search solutions
  static Future<List<SolutionModel>> searchSolutions(
    String query, {
    SolutionType? type,
    DifficultyLevel? difficulty,
    int limit = 20,
  }) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation. For production, consider using Algolia or similar
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: SolutionStatus.approved.toString())
          .orderBy('submittedAt', descending: true)
          .limit(limit * 2) // Get more results to filter
          .get();

      final allSolutions = querySnapshot.docs
          .map((doc) => SolutionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();

      // Filter by search query
      final filteredSolutions = allSolutions.where((solution) {
        final searchLower = query.toLowerCase();
        return solution.title.toLowerCase().contains(searchLower) ||
               solution.description.toLowerCase().contains(searchLower) ||
               solution.tags.any((tag) => tag.toLowerCase().contains(searchLower));
      }).toList();

      // Apply additional filters
      var result = filteredSolutions;
      if (type != null) {
        result = result.where((s) => s.type == type).toList();
      }
      if (difficulty != null) {
        result = result.where((s) => s.difficulty == difficulty).toList();
      }

      return result.take(limit).toList();
    } catch (e) {
      print('Error searching solutions: $e');
      return [];
    }
  }

  /// Update solution
  static Future<bool> updateSolution(SolutionModel solution) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(solution.id)
          .update(solution.toMap());
      return true;
    } catch (e) {
      print('Error updating solution: $e');
      return false;
    }
  }

  /// Vote on solution
  static Future<bool> voteSolution(String solutionId, String userId, bool isUpvote) async {
    try {
      final docRef = _firestore.collection(_collection).doc(solutionId);
      
      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (!doc.exists) {
          throw Exception('Solution not found');
        }
        
        final data = doc.data()!;
        final voterIds = List<String>.from(data['voterIds'] ?? []);
        
        if (voterIds.contains(userId)) {
          throw Exception('User already voted');
        }
        
        voterIds.add(userId);
        
        final newUpvotes = (data['upvotes'] ?? 0) + (isUpvote ? 1 : 0);
        final newDownvotes = (data['downvotes'] ?? 0) + (isUpvote ? 0 : 1);
        
        transaction.update(docRef, {
          'upvotes': newUpvotes,
          'downvotes': newDownvotes,
          'voterIds': voterIds,
        });
        
        return true;
      });
    } catch (e) {
      print('Error voting on solution: $e');
      return false;
    }
  }

  /// Add comment to solution
  static Future<bool> addComment(String solutionId, SolutionComment comment) async {
    try {
      final docRef = _firestore.collection(_collection).doc(solutionId);
      
      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (!doc.exists) {
          throw Exception('Solution not found');
        }
        
        final data = doc.data()!;
        final comments = List<Map<String, dynamic>>.from(data['comments'] ?? []);
        comments.add(comment.toMap());
        
        transaction.update(docRef, {
          'comments': comments,
        });
        
        return true;
      });
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }

  /// Update solution status
  static Future<bool> updateSolutionStatus(
    String solutionId,
    SolutionStatus status, {
    String? approvedBy,
    Map<String, dynamic>? authorityReview,
  }) async {
    try {
      final updateData = {
        'status': status.toString(),
        'updatedAt': Timestamp.now(),
      };
      
      if (approvedBy != null) {
        updateData['approvedBy'] = approvedBy;
        updateData['approvedAt'] = Timestamp.now();
      }
      
      if (authorityReview != null) {
        updateData['authorityReview'] = authorityReview;
      }
      
      await _firestore.collection(_collection).doc(solutionId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating solution status: $e');
      return false;
    }
  }

  /// Verify solution implementation
  static Future<bool> verifySolution(
    String solutionId,
    List<String> verificationPhotos,
    String finalStatus,
  ) async {
    try {
      final docRef = _firestore.collection(_collection).doc(solutionId);
      
      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (!doc.exists) {
          throw Exception('Solution not found');
        }
        
        final data = doc.data()!;
        final verificationCount = (data['verificationCount'] ?? 0) + 1;
        
        transaction.update(docRef, {
          'verificationPhotos': verificationPhotos,
          'verificationCount': verificationCount,
          'isVerified': true,
          'finalStatus': finalStatus,
          'updatedAt': Timestamp.now(),
        });
        
        return true;
      });
    } catch (e) {
      print('Error verifying solution: $e');
      return false;
    }
  }

  /// Get solution statistics
  static Future<Map<String, dynamic>> getSolutionStats() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      
      final solutions = querySnapshot.docs
          .map((doc) => SolutionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
        final stats = <String, dynamic>{
        'totalSolutions': solutions.length,
        'approvedSolutions': solutions.where((s) => s.status == SolutionStatus.approved).length,
        'verifiedSolutions': solutions.where((s) => s.isVerified).length,
        'averageRating': solutions.isNotEmpty 
            ? solutions.map((s) => s.successRating).reduce((a, b) => a + b) / solutions.length
            : 0.0,
        'solutionsByType': <String, int>{},
        'solutionsByDifficulty': <String, int>{},
      };
      
      // Count by type
      for (final solution in solutions) {
        final type = solution.type.toString();
        final typeMap = stats['solutionsByType'] as Map<String, int>;
        typeMap[type] = (typeMap[type] ?? 0) + 1;
        
        final difficulty = solution.difficulty.toString();
        final difficultyMap = stats['solutionsByDifficulty'] as Map<String, int>;
        difficultyMap[difficulty] = (difficultyMap[difficulty] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      print('Error getting solution stats: $e');
      return {};
    }
  }

  /// Generate AI-powered solution suggestions for an issue
  static Future<List<SolutionModel>> generateAISolutions(
    IssueModel issue,
    String userId,
    String userName,
    String userProfileImageUrl,
  ) async {
    try {
      final aiAnalysis = await AISolutionService.analyzeIssueForSolutions(
        issue,
        issue.imageUrl != null ? [issue.imageUrl!] : [],
      );
      
      final suggestedSolution = SolutionModel(
        id: '', // Will be set when created
        issueId: issue.id,
        userId: userId,
        userName: userName,
        userProfileImageUrl: userProfileImageUrl,
        title: 'AI-Suggested Solution: ${issue.title}',
        description: aiAnalysis.summary,
        images: [],
        type: SolutionType.values.firstWhere(
          (e) => e.toString() == 'SolutionType.${aiAnalysis.suggestedType}',
          orElse: () => SolutionType.diyFix,
        ),
        difficulty: aiAnalysis.suggestedDifficulty,
        materials: aiAnalysis.suggestedMaterials,
        estimatedTime: aiAnalysis.estimatedTime,
        estimatedCost: aiAnalysis.estimatedCost,
        submittedAt: DateTime.now(),
        status: SolutionStatus.pending,
        verificationPhotos: [],
        tags: await AISolutionService.generateSolutionTags(
          'AI-Suggested Solution',
          aiAnalysis.summary,
          SolutionType.diyFix,
        ),
        aiAnalysis: aiAnalysis.toMap(),
        upvotes: 0,
        downvotes: 0,
        voterIds: [],
        comments: [],
        isVerified: false,
        verificationCount: 0,
        successRating: 0.0,
        followUpDates: [],
      );
      
      return [suggestedSolution];
    } catch (e) {
      print('Error generating AI solutions: $e');
      return [];
    }
  }

  /// Get similar solutions for an issue
  static Future<List<SolutionModel>> getSimilarSolutions(
    IssueModel issue, {
    int limit = 5,
  }) async {
    try {
      final allSolutions = await _firestore
          .collection(_collection)
          .where('status', isEqualTo: SolutionStatus.verified.toString())
          .where('isVerified', isEqualTo: true)
          .limit(50) // Get more to filter
          .get();
      
      final solutions = allSolutions.docs
          .map((doc) => SolutionModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Use AI service to find similar solutions
      final similarSolutions = await AISolutionService.findSimilarSolutions(issue, solutions);
      
      return similarSolutions
          .map((item) => item['solution'] as SolutionModel)
          .take(limit)
          .toList();
    } catch (e) {
      print('Error getting similar solutions: $e');
      return [];
    }
  }

  /// Delete solution (admin only)
  static Future<bool> deleteSolution(String solutionId) async {
    try {
      await _firestore.collection(_collection).doc(solutionId).delete();
      return true;
    } catch (e) {
      print('Error deleting solution: $e');
      return false;
    }
  }

  /// Verify a solution (admin only)
  static Future<void> approveSolution(String solutionId) async {
    try {
      await _firestore.collection(_collection).doc(solutionId).update({
        'status': SolutionStatus.verified.toString(),
        'verifiedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('✅ Solution verified: $solutionId');
    } catch (e) {
      print('❌ Error verifying solution: $e');
      rethrow;
    }
  }

  /// Reject a solution (admin only)
  static Future<void> rejectSolution(String solutionId) async {
    try {
      await _firestore.collection(_collection).doc(solutionId).update({
        'status': SolutionStatus.rejected.toString(),
        'rejectedAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print('✅ Solution rejected: $solutionId');
    } catch (e) {
      print('❌ Error rejecting solution: $e');
      rethrow;
    }
  }

  /// Get all verified solutions
  static Future<List<SolutionModel>> getVerifiedSolutions() async {
    try {
      print('🔍 SolutionService: Querying verified solutions...');
      
      // First try the optimized query with both conditions
      try {
        final querySnapshot = await _firestore
            .collection(_collection)
            .where('status', isEqualTo: SolutionStatus.verified.toString())
            .where('isVerified', isEqualTo: true)
            .get();

        print('📊 SolutionService: Found ${querySnapshot.docs.length} verified solution documents');

        final solutions = <SolutionModel>[];
        for (final doc in querySnapshot.docs) {
          try {
            final solution = SolutionModel.fromMap(doc.data());
            solutions.add(solution);
          } catch (e) {
            print('❌ Error parsing solution document ${doc.id}: $e');
            print('📄 Document data: ${doc.data()}');
          }
        }

        print('✅ SolutionService: Successfully parsed ${solutions.length} solutions');
        return solutions;
      } catch (e) {
        print('⚠️ Optimized query failed, trying fallback query: $e');
        
        // Fallback: Get all solutions and filter in memory
        final allSolutionsSnapshot = await _firestore
            .collection(_collection)
            .get();
        
        print('📊 SolutionService: Found ${allSolutionsSnapshot.docs.length} total solution documents');
        
        final solutions = <SolutionModel>[];
        for (final doc in allSolutionsSnapshot.docs) {
          try {
            final data = doc.data();
            final status = data['status'];
            final isVerified = data['isVerified'] ?? false;
            
            print('📄 Solution ${doc.id}: status=$status, isVerified=$isVerified');
            
            if (status == SolutionStatus.verified.toString() && isVerified == true) {
              final solution = SolutionModel.fromMap(data);
              solutions.add(solution);
            }
          } catch (e) {
            print('❌ Error parsing solution document ${doc.id}: $e');
            print('📄 Document data: ${doc.data()}');
          }
        }
        
        print('✅ SolutionService: Successfully parsed ${solutions.length} verified solutions (fallback)');
        return solutions;
      }
    } catch (e) {
      print('❌ Error getting verified solutions: $e');
      return [];
    }
  }

  /// Get all solutions (admin only)
  static Future<List<SolutionModel>> getAllSolutions() async {
    try {
      print('🔍 SolutionService: Querying all solutions...');
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('submittedAt', descending: true)
          .get();

      print('📊 SolutionService: Found ${querySnapshot.docs.length} total solution documents');

      final solutions = <SolutionModel>[];
      for (final doc in querySnapshot.docs) {
        try {
          final solution = SolutionModel.fromMap(doc.data());
          solutions.add(solution);
          print('📄 Solution ${doc.id}: status=${solution.status}, verified=${solution.isVerified}');
        } catch (e) {
          print('❌ Error parsing solution document ${doc.id}: $e');
          print('📄 Document data: ${doc.data()}');
        }
      }

      print('✅ SolutionService: Successfully parsed ${solutions.length} total solutions');
      return solutions;
    } catch (e) {
      print('❌ Error getting all solutions: $e');
      return [];
    }
  }

  /// Get solution statistics for debugging
  static Future<Map<String, dynamic>> getSolutionDebugInfo() async {
    try {
      print('🔍 SolutionService: Testing Firestore connection...');
      final querySnapshot = await _firestore.collection(_collection).get();
      
      final allDocs = querySnapshot.docs;
      print('📊 Total solution documents in database: ${allDocs.length}');
      
      if (allDocs.isEmpty) {
        print('⚠️ No solution documents found in the solutions collection');
        print('💡 This means either:');
        print('   1. No solutions have been submitted yet');
        print('   2. Solutions are stored in a different collection');
        print('   3. There\'s a connection issue');
      }
      
      final statusCounts = <String, int>{};
      int verifiedCount = 0;
      int isVerifiedCount = 0;
      
      for (final doc in allDocs) {
        final data = doc.data();
        final status = data['status'] ?? 'unknown';
        final isVerified = data['isVerified'] ?? false;
        
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
        
        if (status == SolutionStatus.verified.toString()) {
          verifiedCount++;
        }
        if (isVerified == true) {
          isVerifiedCount++;
        }
        
        // Print first few documents for debugging
        if (allDocs.indexOf(doc) < 3) {
          print('📄 Document ${doc.id}: status=$status, isVerified=$isVerified');
          print('📄 Full data: $data');
        }
      }
      
      print('📈 Solution status distribution:');
      statusCounts.forEach((status, count) {
        print('   - $status: $count');
      });
      
      print('🔍 Verification analysis:');
      print('   - Solutions with status="verified": $verifiedCount');
      print('   - Solutions with isVerified=true: $isVerifiedCount');
      
      return {
        'totalDocuments': allDocs.length,
        'statusDistribution': statusCounts,
        'verifiedCount': verifiedCount,
        'isVerifiedCount': isVerifiedCount,
      };
    } catch (e) {
      print('❌ Error getting solution debug info: $e');
      print('💡 This might indicate a Firestore connection or permission issue');
      return {};
    }
  }
}
