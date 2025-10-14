enum BadgeType {
  bronzeCitizen,
  silverGuardian,
  goldChampion,
  platinumHero,
  diamondLegend,
  earlyBird,
  nightOwl,
  categoryExpert,
  resolutionChampion,
  streakMaster,
  qualityInspector,
  impactMaker,
  firstReporter,
  weeklyWarrior,
  monthlyMaven,
}

class BadgeModel {
  final BadgeType type;
  final String name;
  final String description;
  final String emoji;
  final int requiredValue;
  final DateTime? earnedAt;

  BadgeModel({
    required this.type,
    required this.name,
    required this.description,
    required this.emoji,
    required this.requiredValue,
    this.earnedAt,
  });

  factory BadgeModel.fromMap(Map<String, dynamic> map) {
    return BadgeModel(
      type: BadgeType.values.firstWhere(
        (e) => e.toString() == 'BadgeType.${map['type']}',
        orElse: () => BadgeType.bronzeCitizen,
      ),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      emoji: map['emoji'] ?? '🏅',
      requiredValue: map['requiredValue'] ?? 0,
      earnedAt: map['earnedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['earnedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.toString().split('.').last,
      'name': name,
      'description': description,
      'emoji': emoji,
      'requiredValue': requiredValue,
      'earnedAt': earnedAt?.millisecondsSinceEpoch,
    };
  }

  bool get isEarned => earnedAt != null;

  // Static method to get all available badges
  static List<BadgeModel> getAllBadges() {
    return [
      // Tier badges
      BadgeModel(
        type: BadgeType.bronzeCitizen,
        name: 'Bronze Citizen',
        description: 'Report 10 issues',
        emoji: '🥉',
        requiredValue: 10,
      ),
      BadgeModel(
        type: BadgeType.silverGuardian,
        name: 'Silver Guardian',
        description: 'Report 50 issues',
        emoji: '🥈',
        requiredValue: 50,
      ),
      BadgeModel(
        type: BadgeType.goldChampion,
        name: 'Gold Champion',
        description: 'Report 100 issues',
        emoji: '🥇',
        requiredValue: 100,
      ),
      BadgeModel(
        type: BadgeType.platinumHero,
        name: 'Platinum Hero',
        description: 'Report 500 issues',
        emoji: '💎',
        requiredValue: 500,
      ),
      BadgeModel(
        type: BadgeType.diamondLegend,
        name: 'Diamond Legend',
        description: 'Report 1000 issues',
        emoji: '🏅',
        requiredValue: 1000,
      ),
      // Achievement badges
      BadgeModel(
        type: BadgeType.earlyBird,
        name: 'Early Bird',
        description: 'Report 5 issues before 8 AM',
        emoji: '🌅',
        requiredValue: 5,
      ),
      BadgeModel(
        type: BadgeType.nightOwl,
        name: 'Night Owl',
        description: 'Report 5 issues after 10 PM',
        emoji: '🦉',
        requiredValue: 5,
      ),
      BadgeModel(
        type: BadgeType.categoryExpert,
        name: 'Category Expert',
        description: 'Report 20 issues in one category',
        emoji: '🎯',
        requiredValue: 20,
      ),
      BadgeModel(
        type: BadgeType.resolutionChampion,
        name: 'Resolution Champion',
        description: 'Have 10 issues resolved',
        emoji: '✅',
        requiredValue: 10,
      ),
      BadgeModel(
        type: BadgeType.streakMaster,
        name: 'Streak Master',
        description: 'Report for 30 consecutive days',
        emoji: '🔥',
        requiredValue: 30,
      ),
      BadgeModel(
        type: BadgeType.qualityInspector,
        name: 'Quality Inspector',
        description: 'Maintain 95% approval rate on 20+ reports',
        emoji: '⭐',
        requiredValue: 20,
      ),
      BadgeModel(
        type: BadgeType.impactMaker,
        name: 'Impact Maker',
        description: 'Get 100+ total upvotes',
        emoji: '💪',
        requiredValue: 100,
      ),
      BadgeModel(
        type: BadgeType.firstReporter,
        name: 'First Reporter',
        description: 'First to report an issue in your area',
        emoji: '🚀',
        requiredValue: 1,
      ),
      BadgeModel(
        type: BadgeType.weeklyWarrior,
        name: 'Weekly Warrior',
        description: 'Top 10 in weekly leaderboard',
        emoji: '⚔️',
        requiredValue: 1,
      ),
      BadgeModel(
        type: BadgeType.monthlyMaven,
        name: 'Monthly Maven',
        description: 'Top 10 in monthly leaderboard',
        emoji: '👑',
        requiredValue: 1,
      ),
    ];
  }

  static BadgeModel? getTierBadge(int reportCount) {
    if (reportCount >= 1000) {
      return getAllBadges().firstWhere((b) => b.type == BadgeType.diamondLegend);
    } else if (reportCount >= 500) {
      return getAllBadges().firstWhere((b) => b.type == BadgeType.platinumHero);
    } else if (reportCount >= 100) {
      return getAllBadges().firstWhere((b) => b.type == BadgeType.goldChampion);
    } else if (reportCount >= 50) {
      return getAllBadges().firstWhere((b) => b.type == BadgeType.silverGuardian);
    } else if (reportCount >= 10) {
      return getAllBadges().firstWhere((b) => b.type == BadgeType.bronzeCitizen);
    }
    return null;
  }
}

