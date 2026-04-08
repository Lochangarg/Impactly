import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/supabase_service.dart';
import '../../core/models/user_stats.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<LeaderboardEntry> _globalLeaders = [];
  List<LeaderboardEntry> _weeklyLeaders = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadLeaderboards();
  }

  Future<void> _loadLeaderboards() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      
      // 1. Fetch profiles for Leaderboard
      final response = await client
          .from('profiles')
          .select()
          .order('points', ascending: false)
          .limit(50);
      
      final users = List<Map<String, dynamic>>.from(response);

      if (mounted) {
        setState(() {
          _globalLeaders = _processUsers(users, sortByTotal: true);
          _weeklyLeaders = _processUsers(users, sortByTotal: false);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<LeaderboardEntry> _processUsers(List<Map<String, dynamic>> users, {required bool sortByTotal}) {
    final entries = users.map((u) {
      final stats = UserStats.fromMap(u);
      final String? picUrl = u['profile_picture'];
      
      return LeaderboardEntry(
        userId: u['id'].toString(),
        fullName: u['full_name'] ?? u['username'] ?? 'User',
        profilePicUrl: picUrl,
        score: sortByTotal ? stats.totalXP.toDouble() : stats.calculateLeaderboardScore(),
        rank: 0, 
        level: stats.level,
      );
    }).toList();

    // Sort by score
    entries.sort((a, b) => b.score.compareTo(a.score));
    
    // Assign ranks
    final rankedEntries = <LeaderboardEntry>[];
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      rankedEntries.add(LeaderboardEntry(
        userId: entry.userId,
        fullName: entry.fullName,
        profilePicUrl: entry.profilePicUrl,
        score: entry.score,
        rank: i + 1,
        level: entry.level,
      ));
    }
    
    return rankedEntries;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          labelColor: const Color(0xFF6366F1),
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Weekly'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLeaderboardList(_globalLeaders),
                _buildLeaderboardList(_weeklyLeaders),
              ],
            ),
    );
  }

  Widget _buildLeaderboardList(List<LeaderboardEntry> entries) {
    if (entries.isEmpty) return const Center(child: Text('No entries yet'));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final bool isTop3 = index < 3;
        
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
          ),
          child: ListTile(
            leading: SizedBox(
              width: 80,
              child: Row(
                children: [
                  Text(
                    '${entry.rank}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isTop3 ? const Color(0xFF6366F1) : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundImage: entry.profilePicUrl != null ? CachedNetworkImageProvider(entry.profilePicUrl!) : null,
                    child: entry.profilePicUrl == null ? const Icon(Icons.person) : null,
                  ),
                ],
              ),
            ),
            title: Text(entry.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Level ${entry.level}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  entry.score.toInt().toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6366F1)),
                ),
                const Text('Impact', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }
}
