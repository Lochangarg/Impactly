import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_stats.dart';

class LeaderboardService {
  static final client = Supabase.instance.client;

  /// Fetch Global Leaderboard entry ranking by LS = IS_recent + (0.3 × IS_total)
  static Future<List<LeaderboardEntry>> fetchGlobalLeaderboard({int limit = 20}) async {
    try {
      // 1. Fetch current users with their stats from profiles
      final response = await client
          .from('profiles')
          .select()
          .order('points', ascending: false)
          .limit(limit * 2);

      final list = <LeaderboardEntry>[];
      final users = List<Map<String, dynamic>>.from(response);

      for (var user in users) {
        final stats = UserStats.fromMap(user);
        final score = stats.calculateLeaderboardScore();
        final String? picUrl = user['profile_picture'];

        list.add(LeaderboardEntry(
          userId: user['id'].toString(),
          fullName: user['full_name'] ?? user['username'] ?? 'User',
          profilePicUrl: picUrl,
          score: score,
          rank: 0, // Placeholder
          level: user['level'] ?? 1,
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

  /// Weekly Reset: Usually handled via Supabase edge functions or cron.
  static Future<void> checkWeeklyReset() async {
    // Moved to backend edge functions triggered by pg_cron
  }
}
