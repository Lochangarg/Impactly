import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/parse_service.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/translation_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<ParseObject> _posts = [];
  bool _isLoading = true;
  ParseUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    _currentUser = await ParseService.getCurrentUser();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final fetchedPosts = await ParseService.fetchFeedPosts();
      
      final locale = Localizations.maybeLocaleOf(context)?.toString() ?? 'en';
      if (locale == 'hi') {
        for (var post in fetchedPosts) {
          final content = post.get<String>('content') ?? '';
          final translatedContent = await TranslationService.translate(content, 'hi');
          post.set('content', translatedContent);

          final event = post.get<ParseObject>('event');
          if (event != null) {
            final title = event.get<String>('title') ?? '';
            final translatedTitle = await TranslationService.translate(title, 'hi');
            event.set('title', translatedTitle);
          }
        }
      }

      if (mounted) {
        setState(() {
          _posts = fetchedPosts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(l10n.community_feed, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_outlined, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.search_outlined, color: Colors.black), onPressed: () {}),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1), strokeWidth: 2))
          : RefreshIndicator(
              onRefresh: _fetchPosts,
              color: const Color(0xFF6366F1),
              child: _posts.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.7,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.dynamic_feed_outlined, size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(l10n.no_posts_yet, style: const TextStyle(fontSize: 18, color: Color(0xFF111827), fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(l10n.be_the_first_to_share, style: const TextStyle(color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        final ParseObject? rawUser = (post.get('createdBy') ?? post.get('user')) as ParseObject?;
                        final ParseObject? event = post.get('event') as ParseObject?;
                        
                        String userName = "User";
                        if (rawUser != null) {
                          final String? nameInDb = rawUser.get<String>('fullName');
                          final String? usernameInDb = rawUser.get<String>('username');
                          userName = (nameInDb != null && nameInDb.isNotEmpty) ? nameInDb : (usernameInDb ?? "User");
                        }

                        final dynamic profilePicRaw = rawUser?.get('profilePicture');
                        final String? userProfileUrl = profilePicRaw is ParseFileBase ? profilePicRaw.url : (profilePicRaw is String ? profilePicRaw : null);

                        return _PostCard(
                          post: post,
                          userName: userName,
                          userProfileUrl: userProfileUrl,
                          eventTitle: event?.get<String>('title') ?? l10n.event_update,
                          onRefresh: _fetchPosts,
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const CreatePostScreen()));
          if (result == true) _fetchPosts();
        },
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
        label: Text(l10n.post_update, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final ParseObject post;
  final String userName;
  final String? userProfileUrl;
  final String eventTitle;
  final VoidCallback onRefresh;

  const _PostCard({
    required this.post,
    required this.userName,
    this.userProfileUrl,
    required this.eventTitle,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = post.createdAt;
    final locale = Localizations.localeOf(context).toString();
    final dateStr = date != null ? DateFormat('MMM d, hh:mm a', locale).format(date) : l10n.recently;
    final imageUrl = post.get<ParseFile>('image')?.url;
    final List<dynamic> likes = post.get<List<dynamic>>('likes') ?? [];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(
                  post: post,
                  userName: userName,
                  userProfileUrl: userProfileUrl,
                  eventTitle: eventTitle,
                ),
              ),
            );
            if (result == true) onRefresh();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                      backgroundImage: userProfileUrl != null ? CachedNetworkImageProvider(userProfileUrl!) : null,
                      child: userProfileUrl == null ? const Icon(Icons.person, color: Color(0xFF6366F1), size: 18) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text(dateStr, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.more_horiz, color: Color(0xFF9CA3AF)),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Event Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.joined_at(eventTitle),
                    style: const TextStyle(color: Color(0xFF6366F1), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Content
                Text(
                  post.get<String>('content') ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF374151), height: 1.5, fontSize: 14),
                ),
                
                // Image
                if (imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(color: Colors.grey[50]),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                
                // Footer Actions
                Row(
                  children: [
                    Icon(likes.isNotEmpty ? Icons.favorite : Icons.favorite_border, 
                         size: 18, 
                         color: likes.isNotEmpty ? Colors.redAccent : Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text('${likes.length}', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(l10n.comments, style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('View Details', style: TextStyle(color: const Color(0xFF6366F1), fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
