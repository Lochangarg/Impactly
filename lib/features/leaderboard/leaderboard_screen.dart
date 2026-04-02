import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../../core/services/parse_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<ParseUser>> _leaderboardUsers;

  @override
  void initState() {
    super.initState();
    _leaderboardUsers = ParseService.fetchLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Impact Leaderboard', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<List<ParseUser>>(
        future: _leaderboardUsers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
          }

          final users = snapshot.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('No leaderboard data yet. Start making an impact!'));
          }

          return RefreshIndicator(
            onRefresh: () async => setState(() => _leaderboardUsers = ParseService.fetchLeaderboard()),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  _buildPodium(users.take(3).toList()),
                  const SizedBox(height: 40),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('All Contributors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  ...users.asMap().entries.map((entry) {
                    final index = entry.key;
                    final user = entry.value;
                    return _buildLeaderboardTile(index + 1, user);
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPodium(List<ParseUser> topUsers) {
    if (topUsers.isEmpty) return const SizedBox.shrink();

    // Reorder as [2nd, 1st, 3rd] for visual podium
    final podiumOrder = <ParseUser?>[null, null, null];
    if (topUsers.length >= 1) podiumOrder[1] = topUsers[0];
    if (topUsers.length >= 2) podiumOrder[0] = topUsers[1];
    if (topUsers.length >= 3) podiumOrder[2] = topUsers[2];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: podiumOrder.asMap().entries.map((entry) {
        final pos = entry.key; // 0=2nd, 1=1st, 2=3rd
        final user = entry.value;
        
        if (user == null) return const Expanded(child: SizedBox());

        final isFirst = pos == 1;
        final height = isFirst ? 180.0 : 140.0;
        final avatarSize = isFirst ? 80.0 : 60.0;

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: CircleAvatar(
                      radius: avatarSize / 2,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: Text(
                        (user.get<String>('fullName') ?? '?')[0].toUpperCase(),
                        style: TextStyle(fontSize: avatarSize / 3, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ),
                  if (isFirst)
                    const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 28),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                user.get<String>('fullName')?.split(' ')[0] ?? 'User',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: isFirst ? 16 : 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${user.get<int>('points') ?? 0} pts',
                style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w600, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Container(
                height: height * 0.4,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isFirst 
                      ? [const Color(0xFF6366F1), const Color(0xFF8B5CF6)]
                      : [Theme.of(context).colorScheme.surfaceContainerHighest, Theme.of(context).colorScheme.surface],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Text(
                    isFirst ? '1' : (pos == 0 ? '2' : '3'),
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: isFirst ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLeaderboardTile(int rank, ParseUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              rank.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? const Color(0xFF6366F1) : Theme.of(context).hintColor.withOpacity(0.4),
                fontSize: 16,
              ),
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Text(
              (user.get<String>('fullName') ?? 'U')[0].toUpperCase(),
              style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.get<String>('fullName') ?? 'User',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface),
                ),
                Text(
                  'Level ${user.get<int>('level') ?? 1}',
                  style: TextStyle(color: Theme.of(context).hintColor, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${user.get<int>('points') ?? 0} pts',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
          ),
        ],
      ),
    );
  }
}
