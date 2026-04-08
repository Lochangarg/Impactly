import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_stats.dart';
import '../utils/level_utils.dart';
import 'supabase_service.dart';

class ImpactService {
  // Anti-cheat constants
  static const int dailyXpCap = 1500;
  
  // XP Values for verified actions
  static const int xpPerEvent = 200;
  static const int xpPerReferral = 500;
  static const int xpStreakBonus = 50;
  static const int xpPerTask = 100;

  static final client = Supabase.instance.client;

  static Future<bool> awardXp({required String action, int? customAmount}) async {
    final user = client.auth.currentUser;
    if (user == null) return false;
    return awardXpToUser(user.id, action: action, customAmount: customAmount);
  }

  static Future<bool> awardXpToUser(String targetUserId, {required String action, int? customAmount}) async {
    try {
      final profile = await SupabaseService.getProfile(targetUserId);
      if (profile == null) return false;

      // 1. Anti-Cheat: Daily Cap Check
      final now = DateTime.now();
      final lastDateStr = profile['last_action_date'];
      final lastDate = lastDateStr != null ? DateTime.parse(lastDateStr) : now;
      int dailyXp = profile['daily_xp_earned'] ?? 0;

      // If it's a new day, reset daily XP
      if (now.day != lastDate.day || now.month != lastDate.month || now.year != lastDate.year) {
        dailyXp = 0;
      }

      final int xpToAward = customAmount ?? _getXpForAction(action);
      
      if (dailyXp + xpToAward > dailyXpCap) {
        debugPrint('DAILY XP CAP REACHED for user $targetUserId');
        return false;
      }

      int currentXP = profile['points'] ?? 0;
      int recentXP = profile['recent_xp'] ?? 0;
      int level = profile['level'] ?? 1;

      currentXP += xpToAward;
      recentXP += xpToAward;
      dailyXp += xpToAward;

      if (LevelUtils.isLevelUp(currentXP, level)) {
          level++;
      }

      await client.from('profiles').update({
        'points': currentXP,
        'recent_xp': recentXP,
        'daily_xp_earned': dailyXp,
        'level': level,
        'last_action_date': now.toIso8601String(),
      }).eq('id', targetUserId);

      return true;
    } catch (e) {
      debugPrint('ERROR in awardXpToUser: $e');
      return false;
    }
  }

  static int _getXpForAction(String action) {
    switch (action) {
      case 'event': return xpPerEvent;
      case 'referral': return xpPerReferral;
      case 'streak': return xpStreakBonus;
      case 'task': return xpPerTask;
      default: return 0;
    }
  }

  static Future<void> applyPenalty(int amount) async {
      final user = client.auth.currentUser;
      if (user == null) return;
      
      final profile = await SupabaseService.getProfile(user.id);
      if (profile == null) return;

      int currentXP = profile['points'] ?? 0;
      currentXP = (currentXP - amount).clamp(0, 9999999);
      
      await client.from('profiles').update({'points': currentXP}).eq('id', user.id);
  }
}
