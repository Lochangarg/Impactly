import 'dart:math';

enum ImpactTier { Initiate, Contributor, Organizer, Leader, Changemaker }

class LevelUtils {
  /// Required XP = 100 × (level ^ 1.5)
  static int getRequiredXPForLevel(int level) {
    if (level <= 0) return 0;
    return (100 * pow(level, 1.5)).floor();
  }

  static double getProgressToNextLevel(int currentXP, int level) {
    final int currentLevelXP = getRequiredXPForLevel(level);
    final int nextLevelXP = getRequiredXPForLevel(level + 1);
    
    if (currentXP < currentLevelXP) return 0.0;
    
    final int xpInLevel = currentXP - currentLevelXP;
    final int xpRequiredForNext = nextLevelXP - currentLevelXP;
    
    return xpInLevel / xpRequiredForNext.clamp(1, double.maxFinite.toInt());
  }

  static ImpactTier getImpactTier(int level) {
    if (level < 5) return ImpactTier.Initiate;
    if (level < 15) return ImpactTier.Contributor;
    if (level < 30) return ImpactTier.Organizer;
    if (level < 50) return ImpactTier.Leader;
    return ImpactTier.Changemaker;
  }

  static String getTierName(ImpactTier tier) => tier.toString().split('.').last;

  static bool isLevelUp(int currentXP, int currentLevel) {
    return currentXP >= getRequiredXPForLevel(currentLevel + 1);
  }
}
