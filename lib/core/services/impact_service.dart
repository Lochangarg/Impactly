import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../models/user_stats.dart';
import '../utils/level_utils.dart';

class ImpactService {
  // Anti-cheat constants
  static const int dailyXpCap = 1500;
  
  // XP Values for verified actions
  static const int xpPerEvent = 200;
  static const int xpPerReferral = 500;
  static const int xpStreakBonus = 50;
  static const int xpPerTask = 100;

  static Future<bool> awardXp({required String action, int? customAmount}) async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user == null) return false;
    return awardXpToUser(user, action: action, customAmount: customAmount);
  }

  static Future<bool> awardXpToUser(ParseUser targetUser, {required String action, int? customAmount}) async {
    try {
      // 1. Anti-Cheat: Daily Cap Check
      final now = DateTime.now();
      final lastDate = targetUser.get<DateTime>('lastActionDate') ?? now;
      int dailyXp = targetUser.get<int>('dailyXpEarned') ?? 0;

      // If it's a new day, reset daily XP
      if (now.day != lastDate.day || now.month != lastDate.month || now.year != lastDate.year) {
        dailyXp = 0;
      }

      final int xpToAward = customAmount ?? _getXpForAction(action);
      
      if (dailyXp + xpToAward > dailyXpCap) {
        debugPrint('DAILY XP CAP REACHED for user ${targetUser.objectId}');
        return false;
      }

      int currentXP = targetUser.get<int>('totalXP') ?? 0;
      int recentXP = targetUser.get<int>('recentXP') ?? 0;
      int level = targetUser.get<int>('level') ?? 1;

      currentXP += xpToAward;
      recentXP += xpToAward;
      dailyXp += xpToAward;

      if (LevelUtils.isLevelUp(currentXP, level)) {
          level++;
      }

      targetUser.set('totalXP', currentXP);
      targetUser.set('recentXP', recentXP);
      targetUser.set('dailyXpEarned', dailyXp);
      targetUser.set('level', level);
      targetUser.set('lastActionDate', now);

      final resp = await targetUser.save();
      return resp.success;
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
      final user = await ParseUser.currentUser() as ParseUser?;
      if (user == null) return;
      
      int currentXP = user.get<int>('totalXP') ?? 0;
      currentXP = (currentXP - amount).clamp(0, 9999999);
      user.set('totalXP', currentXP);
      await user.save();
  }
}
