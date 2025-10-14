import 'package:cloud_firestore/cloud_firestore.dart';

class SolutionModel {
  final String id;
  final String issueId;
  final String userId;
  final String userName;
  final String userProfileImageUrl;
  final String title;
  final String description;
  final List<String> images;
  final SolutionType type;
  final DifficultyLevel difficulty;
  final List<String> materials;
  final int estimatedTime; // minutes
  final int estimatedCost; // in cents
  final DateTime submittedAt;
  final DateTime? updatedAt;
  final SolutionStatus status;
  final List<String> verificationPhotos;
  final List<String> tags;
  final Map<String, dynamic> aiAnalysis;
  final int upvotes;
  final int downvotes;
  final List<String> voterIds;
  final List<SolutionComment> comments;
  final Map<String, dynamic>? authorityReview;
  final String? approvedBy;
  final DateTime? approvedAt;
  final bool isVerified;
  final int verificationCount;
  final double successRating; // 0.0 to 5.0
  final List<String> followUpDates;
  final String? finalStatus; // "working", "failed", "needs_maintenance"

  SolutionModel({
    required this.id,
    required this.issueId,
    required this.userId,
    required this.userName,
    required this.userProfileImageUrl,
    required this.title,
    required this.description,
    required this.images,
    required this.type,
    required this.difficulty,
    required this.materials,
    required this.estimatedTime,
    required this.estimatedCost,
    required this.submittedAt,
    this.updatedAt,
    required this.status,
    required this.verificationPhotos,
    required this.tags,
    required this.aiAnalysis,
    required this.upvotes,
    required this.downvotes,
    required this.voterIds,
    required this.comments,
    this.authorityReview,
    this.approvedBy,
    this.approvedAt,
    required this.isVerified,
    required this.verificationCount,
    required this.successRating,
    required this.followUpDates,
    this.finalStatus,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'issueId': issueId,
      'userId': userId,
      'userName': userName,
      'userProfileImageUrl': userProfileImageUrl,
      'title': title,
      'description': description,
      'images': images,
      'type': type.toString(),
      'difficulty': difficulty.toString(),
      'materials': materials,
      'estimatedTime': estimatedTime,
      'estimatedCost': estimatedCost,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'status': status.toString(),
      'verificationPhotos': verificationPhotos,
      'tags': tags,
      'aiAnalysis': aiAnalysis,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'voterIds': voterIds,
      'comments': comments.map((c) => c.toMap()).toList(),
      'authorityReview': authorityReview,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'isVerified': isVerified,
      'verificationCount': verificationCount,
      'successRating': successRating,
      'followUpDates': followUpDates,
      'finalStatus': finalStatus,
    };
  }

  factory SolutionModel.fromMap(Map<String, dynamic> map) {
    return SolutionModel(
      id: map['id'] ?? '',
      issueId: map['issueId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userProfileImageUrl: map['userProfileImageUrl'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      type: SolutionType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => SolutionType.diyFix,
      ),
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.toString() == map['difficulty'],
        orElse: () => DifficultyLevel.easy,
      ),
      materials: List<String>.from(map['materials'] ?? []),
      estimatedTime: map['estimatedTime'] ?? 0,
      estimatedCost: map['estimatedCost'] ?? 0,
      submittedAt: (map['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      status: SolutionStatus.values.firstWhere(
        (e) => e.toString() == map['status'],
        orElse: () => SolutionStatus.pending,
      ),
      verificationPhotos: List<String>.from(map['verificationPhotos'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
      aiAnalysis: Map<String, dynamic>.from(map['aiAnalysis'] ?? {}),
      upvotes: map['upvotes'] ?? 0,
      downvotes: map['downvotes'] ?? 0,
      voterIds: List<String>.from(map['voterIds'] ?? []),
      comments: (map['comments'] as List<dynamic>?)
              ?.map((c) => SolutionComment.fromMap(c))
              .toList() ??
          [],
      authorityReview: map['authorityReview'],
      approvedBy: map['approvedBy'],
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      isVerified: map['isVerified'] ?? false,
      verificationCount: map['verificationCount'] ?? 0,
      successRating: (map['successRating'] ?? 0.0).toDouble(),
      followUpDates: List<String>.from(map['followUpDates'] ?? []),
      finalStatus: map['finalStatus'],
    );
  }

  SolutionModel copyWith({
    String? id,
    String? issueId,
    String? userId,
    String? userName,
    String? userProfileImageUrl,
    String? title,
    String? description,
    List<String>? images,
    SolutionType? type,
    DifficultyLevel? difficulty,
    List<String>? materials,
    int? estimatedTime,
    int? estimatedCost,
    DateTime? submittedAt,
    DateTime? updatedAt,
    SolutionStatus? status,
    List<String>? verificationPhotos,
    List<String>? tags,
    Map<String, dynamic>? aiAnalysis,
    int? upvotes,
    int? downvotes,
    List<String>? voterIds,
    List<SolutionComment>? comments,
    Map<String, dynamic>? authorityReview,
    String? approvedBy,
    DateTime? approvedAt,
    bool? isVerified,
    int? verificationCount,
    double? successRating,
    List<String>? followUpDates,
    String? finalStatus,
  }) {
    return SolutionModel(
      id: id ?? this.id,
      issueId: issueId ?? this.issueId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      type: type ?? this.type,
      difficulty: difficulty ?? this.difficulty,
      materials: materials ?? this.materials,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      verificationPhotos: verificationPhotos ?? this.verificationPhotos,
      tags: tags ?? this.tags,
      aiAnalysis: aiAnalysis ?? this.aiAnalysis,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      voterIds: voterIds ?? this.voterIds,
      comments: comments ?? this.comments,
      authorityReview: authorityReview ?? this.authorityReview,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      isVerified: isVerified ?? this.isVerified,
      verificationCount: verificationCount ?? this.verificationCount,
      successRating: successRating ?? this.successRating,
      followUpDates: followUpDates ?? this.followUpDates,
      finalStatus: finalStatus ?? this.finalStatus,
    );
  }
}

enum SolutionType {
  diyFix,
  workaround,
  documentation,
  communityHelp,
  maintenance,
  improvement,
}

enum DifficultyLevel {
  easy,
  medium,
  advanced,
  expert,
}

enum SolutionStatus {
  pending,
  underReview,
  approved,
  rejected,
  implemented,
  verified,
  expired,
}

class SolutionComment {
  final String id;
  final String userId;
  final String userName;
  final String userProfileImageUrl;
  final String content;
  final DateTime createdAt;
  final int likes;
  final List<String> likerIds;
  final bool isHelpful;
  final String? parentCommentId;

  SolutionComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userProfileImageUrl,
    required this.content,
    required this.createdAt,
    required this.likes,
    required this.likerIds,
    required this.isHelpful,
    this.parentCommentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userProfileImageUrl': userProfileImageUrl,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'likes': likes,
      'likerIds': likerIds,
      'isHelpful': isHelpful,
      'parentCommentId': parentCommentId,
    };
  }

  factory SolutionComment.fromMap(Map<String, dynamic> map) {
    return SolutionComment(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userProfileImageUrl: map['userProfileImageUrl'] ?? '',
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: map['likes'] ?? 0,
      likerIds: List<String>.from(map['likerIds'] ?? []),
      isHelpful: map['isHelpful'] ?? false,
      parentCommentId: map['parentCommentId'],
    );
  }
}

class AIAnalysisResult {
  final double confidence;
  final String suggestedType;
  final DifficultyLevel suggestedDifficulty;
  final List<String> suggestedMaterials;
  final int estimatedTime;
  final int estimatedCost;
  final List<String> safetyWarnings;
  final List<String> successFactors;
  final String summary;
  final Map<String, dynamic> metadata;

  AIAnalysisResult({
    required this.confidence,
    required this.suggestedType,
    required this.suggestedDifficulty,
    required this.suggestedMaterials,
    required this.estimatedTime,
    required this.estimatedCost,
    required this.safetyWarnings,
    required this.successFactors,
    required this.summary,
    required this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'confidence': confidence,
      'suggestedType': suggestedType,
      'suggestedDifficulty': suggestedDifficulty.toString(),
      'suggestedMaterials': suggestedMaterials,
      'estimatedTime': estimatedTime,
      'estimatedCost': estimatedCost,
      'safetyWarnings': safetyWarnings,
      'successFactors': successFactors,
      'summary': summary,
      'metadata': metadata,
    };
  }

  factory AIAnalysisResult.fromMap(Map<String, dynamic> map) {
    return AIAnalysisResult(
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      suggestedType: map['suggestedType'] ?? 'diyFix',
      suggestedDifficulty: DifficultyLevel.values.firstWhere(
        (e) => e.toString() == map['suggestedDifficulty'],
        orElse: () => DifficultyLevel.easy,
      ),
      suggestedMaterials: List<String>.from(map['suggestedMaterials'] ?? []),
      estimatedTime: map['estimatedTime'] ?? 0,
      estimatedCost: map['estimatedCost'] ?? 0,
      safetyWarnings: List<String>.from(map['safetyWarnings'] ?? []),
      successFactors: List<String>.from(map['successFactors'] ?? []),
      summary: map['summary'] ?? '',
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}
