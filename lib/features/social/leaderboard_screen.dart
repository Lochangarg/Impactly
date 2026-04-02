import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/parse_service.dart';
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
      // 1. Fetch Global (ranked by Total XP)
      final globalQuery = QueryBuilder<ParseUser>(ParseUser.forQuery())
        ..orderByDescending('totalXP')
        ..setLimit(50);
      final globalResp = await globalQuery.query();
      
      // 2. Fetch Weekly (ranked by Recent XP / LS score)
      final weeklyQuery = QueryBuilder<ParseUser>(ParseUser.forQuery())
        ..setLimit(50);
      final weeklyResp = await weeklyQuery.query();

      if (mounted) {
        setState(() {
          _globalLeaders = _processUsers(globalResp.results as List<ParseObject>?, sortByTotal: true);
          _weeklyLeaders = _processUsers(weeklyResp.results as List<ParseObject>?, sortByTotal: false);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<LeaderboardEntry> _processUsers(List<ParseObject>? users, {required bool sortByTotal}) {
    if (users == null) return [];
    
    final entries = users.map((u) {
      final user = u as ParseUser;
      final stats = UserStats.fromParse(user);
      final dynamic pic = user.get('profilePicture');
      final String? picUrl = pic is ParseFileBase ? pic.url : (pic is String ? pic : null);
      
      return LeaderboardEntry(
        userId: user.objectId!,
        fullName: user.get<String>('fullName') ?? user.username ?? 'User',
        profilePicUrl: picUrl,
        score: sortByTotal ? stats.totalXP.toDouble() : stats.calculateLeaderboardScore(),
        rank: 0, 
        level: stats.level,
      );
    }).toList();

    // Sort by score
    entries.sort((a, b) => b.score.compareTo(a.score));
    
    // Assign ranks
    for (int i = 0; i < entries.length; i++) {
      // entries[i] = entries[i].copyWith(rank: i + 1); // If CopyWith existed
    }
    
    return entries;
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
                    '${index + 1}',
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
