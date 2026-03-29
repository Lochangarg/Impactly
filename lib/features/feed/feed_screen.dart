import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/parse_service.dart';
import 'create_post_screen.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l10n.community_feed, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827))),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.favorite_border, color: Colors.black), onPressed: () {}),
          IconButton(icon: const Icon(Icons.send_outlined, color: Colors.black), onPressed: () {}),
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

                        final date = post.createdAt;
                        final locale = Localizations.localeOf(context).toString();
                        final imageUrl = post.get<ParseFile>('image')?.url;

                        return _PostCard(
                          userName: userName,
                          userProfileUrl: userProfileUrl,
                          eventTitle: event?.get<String>('title') ?? l10n.event_update,
                          content: post.get<String>('content') ?? '',
                          dateStr: date != null ? DateFormat('MMM d, hh:mm a', locale).format(date) : l10n.recently,
                          postImageUrl: imageUrl,
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
        label: Text(l10n.post_update, style: const TextStyle(color: Colors.white)),
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
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
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
              AppLocalizations.of(context)!.joined_at(eventTitle),
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
