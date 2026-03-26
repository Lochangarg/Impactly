import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/parse_service.dart';
import 'create_post_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<ParseObject> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final fetchedPosts = await ParseService.fetchFeedPosts();
      if (mounted) {
        setState(() {
          _posts = fetchedPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading feed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Community Feed', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : RefreshIndicator(
              onRefresh: _fetchPosts,
              color: const Color(0xFF6366F1),
              child: _posts.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.dynamic_feed_outlined, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            const Text('No posts yet', style: TextStyle(fontSize: 18, color: Color(0xFF111827), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            const Text('Be the first to share an update!', style: TextStyle(color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];

                          // 🏗️ Step 1: Use multiple potential field names (createdBy or user)
                          final ParseObject? rawUser = (post.get('createdBy') ?? post.get('user')) as ParseObject?;
                          final ParseObject? event = post.get('event') as ParseObject?;
                          
                          // 🧠 High-Precision Name Logic
                          String userName = "User";

                          if (rawUser != null) {
                            final String? nameInDb = rawUser.get<String>('fullName');
                            final String? usernameInDb = rawUser.get<String>('username');
                            
                            debugPrint('DEBUG: Post ${post.objectId} User Hydrated: ${nameInDb != null}');

                            if (nameInDb != null && nameInDb.isNotEmpty) {
                              userName = nameInDb;
                            } else if (usernameInDb != null && usernameInDb.isNotEmpty) {
                              userName = usernameInDb;
                            }
                          }

                          // 🖼 Profile picture
                          final dynamic profilePicRaw = rawUser?.get('profilePicture');
                          final String? userProfileUrl =
                              profilePicRaw is ParseFileBase
                                  ? profilePicRaw.url
                                  : (profilePicRaw is String ? profilePicRaw : null);

                          // 📅 Date & Image
                          final date = post.createdAt;
                          final imageUrl = post.get<ParseFile>('image')?.url;

                        return _PostCard(
                          userName: userName,
                          userProfileUrl: userProfileUrl,
                          eventTitle: event?.get<String>('title') ?? 'Event Update',
                          content: post.get<String>('content') ?? '',
                          dateStr: date != null ? DateFormat('MMM d, hh:mm a').format(date) : 'Recently',
                          postImageUrl: imageUrl,
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
          if (result == true) {
            _fetchPosts();
          }
        },
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
        label: const Text('Post Update', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final String userName;
  final String? userProfileUrl;
  final String eventTitle;
  final String content;
  final String dateStr;
  final String? postImageUrl;

  const _PostCard({
    required this.userName,
    this.userProfileUrl,
    required this.eventTitle,
    required this.content,
    required this.dateStr,
    this.postImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF3F4F6), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF6366F1),
                backgroundImage: userProfileUrl != null ? CachedNetworkImageProvider(userProfileUrl!) : null,
                child: userProfileUrl == null ? const Icon(Icons.person, color: Colors.white, size: 20) : null,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(dateStr, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Event Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(
              'Joined: $eventTitle',
              style: const TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(content, style: const TextStyle(color: Color(0xFF374151), height: 1.5)),

          if (postImageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: postImageUrl!,
                  placeholder: (context, url) => Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
