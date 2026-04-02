import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

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

  factory UserStats.fromParse(ParseUser user) {
    return UserStats(
      totalXP: user.get<int>('totalXP') ?? 0,
      recentXP: user.get<int>('recentXP') ?? 0,
      level: user.get<int>('level') ?? 1,
      streaks: user.get<int>('streaks') ?? 0,
      referrals: user.get<int>('referrals') ?? 0,
      lastActionDate: user.get<DateTime>('lastActionDate') ?? DateTime.now(),
      dailyXpEarned: user.get<int>('dailyXpEarned') ?? 0,
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
