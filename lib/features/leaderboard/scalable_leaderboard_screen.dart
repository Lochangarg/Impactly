import 'package:flutter/material.dart';
import '../../core/models/user_stats.dart';
import '../../core/services/leaderboard_service.dart';
import '../../core/utils/level_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ScalableLeaderboardScreen extends StatefulWidget {
  const ScalableLeaderboardScreen({super.key});

  @override
  State<ScalableLeaderboardScreen> createState() => _ScalableLeaderboardScreenState();
}

class _ScalableLeaderboardScreenState extends State<ScalableLeaderboardScreen> {
  final List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshLeaderboard();
  }

  Future<void> _refreshLeaderboard() async {
    setState(() => _isLoading = true);
    final results = await LeaderboardService.fetchGlobalLeaderboard(limit: 20);
    if (mounted) {
      setState(() {
        _entries.clear();
        _entries.addAll(results);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Impact Leaderboard', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: _refreshLeaderboard, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : _entries.isEmpty 
              ? const Center(child: Text('No entries found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    final tier = LevelUtils.getImpactTier(entry.level);
                    final tierName = LevelUtils.getTierName(tier);
                    
                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      color: Theme.of(context).cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
                      ),
                      child: ListTile(
                        leading: _buildRankBadge(entry.rank),
                        title: Row(
                          children: [
                            Text(entry.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            _buildLevelBadge(entry.level, tier),
                          ],
                        ),
                        subtitle: Text(
                          tierName,
                          style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              entry.score.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6366F1)),
                            ),
                            const Text('LS', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildRankBadge(int rank) {
    final color = rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey : (rank == 3 ? Colors.brown : Colors.transparent));
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: rank <= 3 ? Border.all(color: color, width: 2) : null,
      ),
      child: Center(
        child: Text(
          rank.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: rank <= 3 ? color : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBadge(int level, ImpactTier tier) {
    Color tierColor = const Color(0xFF6366F1);
    if (tier == ImpactTier.Changemaker) tierColor = Colors.orange;
    if (tier == ImpactTier.Leader) tierColor = Colors.purple;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tierColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tierColor.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        'Lvl $level',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: tierColor),
      ),
    );
  }
}
