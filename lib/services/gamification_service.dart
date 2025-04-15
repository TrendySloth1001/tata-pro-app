import '../models/energy_usage.dart';

class GamificationService {
  static const int basePoints = 10;
  
  int calculateUserScore(List<EnergyUsage> usageHistory) {
    int score = 0;
    double previousUsage = 0;
    
    for (var usage in usageHistory) {
      // Points for using less than allocation
      if (usage.consumption < 150) {
        score += basePoints;
      }
      
      // Bonus points for reducing consumption
      if (previousUsage > 0 && usage.consumption < previousUsage) {
        score += (basePoints * 2);
      }
      
      // Extra points for sharing energy
      if (usage.type == UsageType.shared) {
        score += (basePoints * 3);
      }
      
      previousUsage = usage.consumption;
    }
    
    return score;
  }

  String getUserLevel(int score) {
    if (score > 1000) return 'Energy Master';
    if (score > 500) return 'Power Saver Pro';
    if (score > 250) return 'Grid Guardian';
    return 'Energy Novice';
  }

  List<Achievement> getUserAchievements(List<EnergyUsage> history) {
    List<Achievement> achievements = [];
    
    // Calculate achievements based on usage patterns
    double totalShared = history.where((u) => u.type == UsageType.shared)
        .fold(0, (sum, usage) => sum + usage.consumption);
    
    if (totalShared > 100) {
      achievements.add(Achievement('Generous Contributor', 'Shared over 100 kW'));
    }
    
    return achievements;
  }
}

class Achievement {
  final String title;
  final String description;
  
  Achievement(this.title, this.description);
}
