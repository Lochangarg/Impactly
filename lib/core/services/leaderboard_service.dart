import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../models/user_stats.dart';

class LeaderboardService {
  /// Fetch Global Leaderboard entry ranking by LS = IS_recent + (0.3 × IS_total)
  static Future<List<LeaderboardEntry>> fetchGlobalLeaderboard({int limit = 20, String? community}) async {
    try {
      final query = QueryBuilder<ParseUser>(ParseUser.forQuery());
      
      if (community != null && community.isNotEmpty) {
        query.whereEqualTo('community', community);
      }

      // 1. Fetch current users with their stats
      // Note: We can't sort by the LS = IS_recent + (0.3 * IS_total) directly in most NoSQL backends.
      // So we fetch the top candidates by totalXP or recentXP and sort them in-memory for accuracy.
      // Alternatively, we use Cloud Code (Back4App) to pre-calculate LS.
      // We'll fetch top total as candidate pool for efficiency.
      query.orderByDescending('totalXP');
      query.setLimit(limit * 2); // Fetch more for sorting accuracy

      final response = await query.query();
      if (!response.success || response.results == null) return [];

      final list = <LeaderboardEntry>[];
      final users = response.results!.cast<ParseUser>();

      for (var user in users) {
        final stats = UserStats.fromParse(user);
        final score = stats.calculateLeaderboardScore();
        final dynamic pic = user.get('profilePicture');
        final String? picUrl = pic is ParseFileBase ? pic.url : (pic is String ? pic : null);

        list.add(LeaderboardEntry(
          userId: user.objectId!,
          fullName: user.get<String>('fullName') ?? user.username ?? 'User',
          profilePicUrl: picUrl,
          score: score,
          rank: 0, // Placeholder for now
          level: user.get<int>('level') ?? 1,
        ));
      }

      // 2. Sort by our custom LS formula in-memory
      list.sort((a, b) => b.score.compareTo(a.score));

      // 3. Assign Ranks and trim to requested limit
      final finalResults = list.take(limit).toList();
      for (int i = 0; i < finalResults.length; i++) {
        finalResults[i] = LeaderboardEntry(
          userId: finalResults[i].userId,
          fullName: finalResults[i].fullName,
          profilePicUrl: finalResults[i].profilePicUrl,
          score: finalResults[i].score,
          rank: i + 1,
          level: finalResults[i].level,
        );
      }

      return finalResults;
    } catch (e) {
        debugPrint('ERROR in fetchGlobalLeaderboard: $e');
        return [];
    }
  }

  /// Weekly Reset: This is usually handled via Cron or Cloud Functions.
  /// Locally, we can detect reset by storing last reset date and checking it.
  static Future<void> checkWeeklyReset() async {
    final query = QueryBuilder<ParseObject>(ParseObject('SystemConfig'))
      ..whereEqualTo('key', 'lastWeeklyReset');
    
    final response = await query.query();
    DateTime lastReset = DateTime.now();

    if (response.success && response.results != null && response.results!.isNotEmpty) {
      lastReset = response.results!.first.get<DateTime>('value')!;
    }

    final now = DateTime.now();
    if (now.difference(lastReset).inDays >= 7) {
       // Reset all users' recentXP to 0
       // This MUST be Cloud Functions in production for scalability.
       // locally we mock reset notification or call cloud function trigger
    }
  }
}
