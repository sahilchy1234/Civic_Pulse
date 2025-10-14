class LeaderboardEntryModel {
  final String userId;
  final String userName;
  final String? profileImageUrl;
  final int points;
  final int rank;
  final int totalReports;
  final int resolvedReports;
  final int totalUpvotes;
  final String? currentBadge;
  final String? location; // City/Ward
  final DateTime lastActive;

  LeaderboardEntryModel({
    required this.userId,
    required this.userName,
    this.profileImageUrl,
    required this.points,
    required this.rank,
    required this.totalReports,
    required this.resolvedReports,
    required this.totalUpvotes,
    this.currentBadge,
    this.location,
    required this.lastActive,
  });

  factory LeaderboardEntryModel.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntryModel(
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      points: map['points'] ?? 0,
      rank: map['rank'] ?? 0,
      totalReports: map['totalReports'] ?? 0,
      resolvedReports: map['resolvedReports'] ?? 0,
      totalUpvotes: map['totalUpvotes'] ?? 0,
      currentBadge: map['currentBadge'],
      location: map['location'],
      lastActive: map['lastActive'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastActive'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'profileImageUrl': profileImageUrl,
      'points': points,
      'rank': rank,
      'totalReports': totalReports,
      'resolvedReports': resolvedReports,
      'totalUpvotes': totalUpvotes,
      'currentBadge': currentBadge,
      'location': location,
      'lastActive': lastActive.millisecondsSinceEpoch,
    };
  }

  double get resolutionRate {
    if (totalReports == 0) return 0.0;
    return (resolvedReports / totalReports) * 100;
  }

  String get displayName {
    return userName.isNotEmpty ? userName : 'Anonymous User';
  }
}

class UserStats {
  final String userId;
  final int totalReports;
  final int resolvedReports;
  final int pendingReports;
  final int inProgressReports;
  final int totalUpvotes;
  final int currentStreak;
  final int longestStreak;
  final int earlyBirdReports;
  final int nightOwlReports;
  final Map<String, int> categoryReports;
  final List<String> earnedBadges;
  final DateTime? lastReportDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserStats({
    required this.userId,
    this.totalReports = 0,
    this.resolvedReports = 0,
    this.pendingReports = 0,
    this.inProgressReports = 0,
    this.totalUpvotes = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.earlyBirdReports = 0,
    this.nightOwlReports = 0,
    this.categoryReports = const {},
    this.earnedBadges = const [],
    this.lastReportDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserStats.fromMap(Map<String, dynamic> map) {
    return UserStats(
      userId: map['userId'] ?? '',
      totalReports: map['totalReports'] ?? 0,
      resolvedReports: map['resolvedReports'] ?? 0,
      pendingReports: map['pendingReports'] ?? 0,
      inProgressReports: map['inProgressReports'] ?? 0,
      totalUpvotes: map['totalUpvotes'] ?? 0,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      earlyBirdReports: map['earlyBirdReports'] ?? 0,
      nightOwlReports: map['nightOwlReports'] ?? 0,
      categoryReports: Map<String, int>.from(map['categoryReports'] ?? {}),
      earnedBadges: List<String>.from(map['earnedBadges'] ?? []),
      lastReportDate: map['lastReportDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastReportDate'])
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalReports': totalReports,
      'resolvedReports': resolvedReports,
      'pendingReports': pendingReports,
      'inProgressReports': inProgressReports,
      'totalUpvotes': totalUpvotes,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'earlyBirdReports': earlyBirdReports,
      'nightOwlReports': nightOwlReports,
      'categoryReports': categoryReports,
      'earnedBadges': earnedBadges,
      'lastReportDate': lastReportDate?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  double get resolutionRate {
    if (totalReports == 0) return 0.0;
    return (resolvedReports / totalReports) * 100;
  }

  String get mostReportedCategory {
    if (categoryReports.isEmpty) return 'None';
    return categoryReports.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  int get mostReportedCategoryCount {
    if (categoryReports.isEmpty) return 0;
    return categoryReports.values.reduce((a, b) => a > b ? a : b);
  }
}

