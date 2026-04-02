import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/parse_service.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import '../social/user_search_screen.dart';
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
        title: Text(l10n.community_feed, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF111827), fontSize: 22, letterSpacing: -1)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_outlined, color: Colors.black), onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.search_outlined, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserSearchScreen()),
              );
            },
          ),
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
                  ? _buildEmptyState(l10n)
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: _posts.length,
                      itemBuilder: (context, index) => PostCard(
                        post: _posts[index],
                        currentUser: _currentUser,
                      ),
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

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.no_posts_yet, style: const TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
            Text(l10n.be_the_first_to_share, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final ParseObject post;
  final ParseUser? currentUser;

  const PostCard({super.key, required this.post, this.currentUser});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isLiked = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    final likes = widget.post.get<List<dynamic>>('likes') ?? [];
    _likesCount = likes.length;
    _isLiked = likes.contains(widget.currentUser?.objectId);
  }

  void _handleLike() async {
    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likesCount--;
      } else {
        _isLiked = true;
        _likesCount++;
      }
    });

    final success = await ParseService.toggleLike(widget.post);
    if (!success && mounted) {
      // Revert if failed
      setState(() {
        _isLiked = !_isLiked;
        _likesCount = _isLiked ? _likesCount + 1 : _likesCount - 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 👤 User data
    final ParseObject? rawUser = (widget.post.get('createdBy') ?? widget.post.get('user')) as ParseObject?;
    final String userName = rawUser?.get<String>('fullName') ?? rawUser?.get<String>('username') ?? "User";
    final dynamic profilePicRaw = rawUser?.get('profilePicture');
    final String? avatarUrl = profilePicRaw is ParseFileBase ? profilePicRaw.url : (profilePicRaw is String ? profilePicRaw : null);
    
    // 📅 Content
    final date = widget.post.createdAt;
    final timeStr = date != null ? DateFormat('MMMM d').format(date) : 'Recently';
    final imageUrl = widget.post.get<ParseFile>('image')?.url;
    final content = widget.post.get<String>('content') ?? '';
    final event = widget.post.get<ParseObject>('event');
    final String eventTitle = event?.get<String>('title') ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                  child: avatarUrl == null ? const Icon(Icons.person, size: 20, color: Colors.grey) : null,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                    if (eventTitle.isNotEmpty)
                      Text(eventTitle, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.more_horiz, size: 20),
              ],
            ),
          ),
          
          // Post Image
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl,
              width: double.infinity,
              fit: BoxFit.fitWidth,
              placeholder: (context, url) => Container(height: 300, color: Colors.grey[100]),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              width: double.infinity,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xFF6366F1), const Color(0xFF818CF8).withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
              child: Text(content, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),

          // Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : Colors.black, size: 28),
                  onPressed: _handleLike,
                ),
                IconButton(icon: const Icon(Icons.mode_comment_outlined, size: 26), onPressed: () => _showComments(context)),
                IconButton(icon: const Icon(Icons.send_outlined, size: 26), onPressed: () {}),
                const Spacer(),
                IconButton(icon: const Icon(Icons.bookmark_border, size: 28), onPressed: () {}),
              ],
            ),
          ),

          // Likes Count
          if (_likesCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('$_likesCount likes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),

          // Caption
          if (imageUrl != null && content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 13.5),
                  children: [
                    TextSpan(text: '$userName ', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: content),
                  ],
                ),
              ),
            ),

          // View all comments placeholder
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            child: GestureDetector(
              onTap: () => _showComments(context),
              child: const Text('View all comments', style: TextStyle(color: Colors.grey, fontSize: 13.5)),
            ),
          ),

          // Date
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Text(timeStr.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5)),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => _CommentSheet(postId: widget.post.objectId!, scrollController: controller),
      ),
    );
  }
}

class _CommentSheet extends StatefulWidget {
  final String postId;
  final ScrollController scrollController;
  const _CommentSheet({required this.postId, required this.scrollController});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  List<ParseObject> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    final comments = await ParseService.fetchComments(widget.postId);
    if (mounted) setState(() { _comments = comments; _isLoading = false; });
  }

  void _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    _commentController.clear();
    final success = await ParseService.addComment(widget.postId, text);
    if (success) _fetchComments();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(height: 5, width: 40, margin: const EdgeInsets.symmetric(vertical: 10), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(5))),
        const Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const Divider(),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator()) 
            : _comments.isEmpty 
              ? const Center(child: Text('No comments yet.'))
              : ListView.builder(
                  controller: widget.scrollController,
                  itemCount: _comments.length,
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    final user = comment.get<ParseObject>('user');
                    final String name = user?.get<String>('fullName') ?? user?.get<String>('username') ?? 'User';
                    return ListTile(
                      leading: const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16)),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      subtitle: Text(comment.get<String>('text') ?? '', style: const TextStyle(color: Colors.black, fontSize: 13)),
                    );
                  },
                ),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 8, top: 8),
          child: Row(
            children: [
              const CircleAvatar(radius: 18, child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(hintText: 'Add a comment...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 14)),
                ),
              ),
              TextButton(onPressed: _submitComment, child: const Text('Post', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
