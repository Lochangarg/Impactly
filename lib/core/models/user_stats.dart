class UserStats {
  final int totalXP;
  final int recentXP; // Weekly XP
  final int level;
  final int streaks;
  final int referrals;
  final DateTime lastActionDate;
  final int dailyXpEarned;

  UserStats({
    required this.totalXP,
    required this.recentXP,
    required this.level,
    this.streaks = 0,
    this.referrals = 0,
    required this.lastActionDate,
    this.dailyXpEarned = 0,
  });

  factory UserStats.fromMap(Map<String, dynamic> user) {
    return UserStats(
      totalXP: user['points'] ?? 0,
      recentXP: user['recent_xp'] ?? 0,
      level: user['level'] ?? 1,
      streaks: user['streaks'] ?? 0,
      referrals: user['referrals'] ?? 0,
      lastActionDate: user['last_action_date'] != null 
          ? DateTime.parse(user['last_action_date']) 
          : DateTime.now(),
      dailyXpEarned: user['daily_xp_earned'] ?? 0,
    );
  }

  double calculateLeaderboardScore() {
    return recentXP + (0.3 * totalXP);
  }
}

class LeaderboardEntry {
  final String userId;
  final String fullName;
  final String? profilePicUrl;
  final double score;
  final int rank;
  final int level;

  LeaderboardEntry({
    required this.userId,
    required this.fullName,
    this.profilePicUrl,
    required this.score,
    required this.rank,
    required this.level,
  });
}
