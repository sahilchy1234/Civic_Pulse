class CommentModel {
  final String id;
  final String issueId;
  final String userId;
  final String userName;
  final String userEmail;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int likes;
  final List<String> likedBy;

  CommentModel({
    required this.id,
    required this.issueId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.likes = 0,
    this.likedBy = const [],
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] ?? '',
      issueId: map['issueId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      content: map['content'] ?? '',
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : DateTime.now(),
      likes: map['likes'] ?? 0,
      likedBy: List<String>.from(map['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'issueId': issueId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'likes': likes,
      'likedBy': likedBy,
    };
  }

  CommentModel copyWith({
    String? id,
    String? issueId,
    String? userId,
    String? userName,
    String? userEmail,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? likes,
    List<String>? likedBy,
  }) {
    return CommentModel(
      id: id ?? this.id,
      issueId: issueId ?? this.issueId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
    );
  }

  bool isLikedBy(String userId) {
    return likedBy.contains(userId);
  }
}
