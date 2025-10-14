import 'package:cloud_firestore/cloud_firestore.dart';

class IssueModel {
  final String id;
  final String userId;
  final String userName;
  final String? userProfileImageUrl;
  final String title;
  final String description;
  final String issueType;
  final Map<String, double> location; // {lat: double, lng: double}
  final String? imageUrl;
  final String status; // 'Pending', 'In Progress', 'Resolved'
  final DateTime createdAt;
  final DateTime updatedAt;
  final int upvotes;
  final List<String> likedBy;
  final String? authorityNotes;
  final String? resolvedImageUrl;

  IssueModel({
    required this.id,
    required this.userId,
    this.userName = 'User',
    this.userProfileImageUrl,
    required this.title,
    required this.description,
    required this.issueType,
    required this.location,
    this.imageUrl,
    this.status = 'Pending',
    required this.createdAt,
    required this.updatedAt,
    this.upvotes = 0,
    this.likedBy = const [],
    this.authorityNotes,
    this.resolvedImageUrl,
  });

  factory IssueModel.fromMap(Map<String, dynamic> map) {
    return IssueModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'User',
      userProfileImageUrl: map['userProfileImageUrl'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      issueType: map['issueType'] ?? '',
      location: Map<String, double>.from(map['location'] ?? {}),
      imageUrl: map['imageUrl'],
      status: map['status'] ?? 'Pending',
      createdAt: IssueModel._parseDateTime(map['createdAt']),
      updatedAt: IssueModel._parseDateTime(map['updatedAt']),
      upvotes: map['upvotes'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      authorityNotes: map['authorityNotes'],
      resolvedImageUrl: map['resolvedImageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userProfileImageUrl': userProfileImageUrl,
      'title': title,
      'description': description,
      'issueType': issueType,
      'location': location,
      'imageUrl': imageUrl,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'upvotes': upvotes,
      'likedBy': likedBy,
      'authorityNotes': authorityNotes,
      'resolvedImageUrl': resolvedImageUrl,
    };
  }

  IssueModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userProfileImageUrl,
    String? title,
    String? description,
    String? issueType,
    Map<String, double>? location,
    String? imageUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? upvotes,
    List<String>? likedBy,
    String? authorityNotes,
    String? resolvedImageUrl,
  }) {
    return IssueModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userProfileImageUrl: userProfileImageUrl ?? this.userProfileImageUrl,
      title: title ?? this.title,
      description: description ?? this.description,
      issueType: issueType ?? this.issueType,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      upvotes: upvotes ?? this.upvotes,
      likedBy: likedBy ?? this.likedBy,
      authorityNotes: authorityNotes ?? this.authorityNotes,
      resolvedImageUrl: resolvedImageUrl ?? this.resolvedImageUrl,
    );
  }

  // Helper methods
  bool get isPending => status == 'Pending';
  bool get isInProgress => status == 'In Progress';
  bool get isResolved => status == 'Resolved';
  
  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }

  String get statusEmoji {
    switch (status) {
      case 'Pending':
        return '⏳';
      case 'In Progress':
        return '🔧';
      case 'Resolved':
        return '✅';
      default:
        return '❓';
    }
  }

  /// Helper method to parse DateTime from various Firestore timestamp formats
  static DateTime _parseDateTime(dynamic timestamp) {
    if (timestamp == null) {
      return DateTime.now();
    }
    
    if (timestamp is Timestamp) {
      // Handle Firestore Timestamp objects
      return timestamp.toDate();
    } else if (timestamp is int) {
      // Handle milliseconds since epoch
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else if (timestamp is String) {
      // Handle ISO string format
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        print('❌ Error parsing date string: $timestamp');
        return DateTime.now();
      }
    } else {
      print('❌ Unknown timestamp type: ${timestamp.runtimeType}');
      return DateTime.now();
    }
  }
}
