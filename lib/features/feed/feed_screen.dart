import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/supabase_service.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';
import '../social/user_search_screen.dart';
import '../../core/navigation/main_screen.dart';
import '../../l10n/app_localizations.dart';
import '../../core/services/translation_service.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    _currentUser = Supabase.instance.client.auth.currentUser;
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final fetchedPosts = await SupabaseService.fetchFeedPosts();
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

  bool _manualTranslate = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.community_feed, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: -1)),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () {
              MainScreen.of(context)?.setTab(1);
            },
          ),
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
                        autoTranslate: _manualTranslate,
                        onUpdate: _fetchPosts,
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
            Text(l10n.no_posts_yet, style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
            Text(l10n.be_the_first_to_share, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }
}

class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
  final User? currentUser;
  final bool autoTranslate;
  final VoidCallback onUpdate;

  const PostCard({super.key, required this.post, this.currentUser, this.autoTranslate = false, required this.onUpdate});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isLiked = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    final likes = widget.post['likes'] as List<dynamic>? ?? [];
    _likesCount = likes.length;
    _isLiked = widget.currentUser != null && likes.contains(widget.currentUser!.id);
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

    final success = await SupabaseService.toggleLike(widget.post['id'].toString());
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
    // 👤 User data (joined from profiles table)
    final userProfile = widget.post['profiles'];
    final String userName = userProfile?['full_name'] ?? userProfile?['username'] ?? "User";
    final String? avatarUrl = userProfile?['profile_picture'];
    
    // 📅 Content
    final createdAtStr = widget.post['created_at'];
    final date = createdAtStr != null ? DateTime.parse(createdAtStr) : DateTime.now();
    final timeStr = DateFormat('MMMM d').format(date);
    final imageUrl = widget.post['image_url'];
    final content = widget.post['content'] ?? '';
    final event = widget.post['events'];
    final String eventTitle = event?['title'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardColor,
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
                      Text(eventTitle, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
                  ],
                ),
                const Spacer(),
                if (widget.currentUser?.id == widget.post['created_by'])
                  PopupMenuButton<String>(
                    onSelected: (val) async {
                      if (val == 'delete') {
                        final success = await SupabaseService.deletePost(widget.post['id'].toString());
                        if (success) widget.onUpdate();
                      } else if (val == 'edit') {
                        // Implement edit logic if needed, or simple dialog
                        _showEditDialog(context);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
                    ],
                    icon: const Icon(Icons.more_horiz, size: 20),
                  )
                else
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
              child: FutureBuilder<String>(
                future: widget.autoTranslate ? TranslationService.translate(content, 'hi') : Future.value(content),
                builder: (context, snapshot) => Text(snapshot.data ?? content, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),
            ),

          // Action Bar (Non-functional likes removed as requested, keeping comments)
          // Wait, user said remove "Notification, Likes, and Share Button Is Not Functional, Remove Them!"
          // These were in the feed header and post card action bar.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.mode_comment_outlined, size: 26), onPressed: () => _showComments(context)),
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
              child: FutureBuilder<String>(
                future: widget.autoTranslate ? TranslationService.translate(content, 'hi') : Future.value(content),
                builder: (context, snapshot) {
                  final translatedContent = snapshot.data ?? content;
                  return RichText(
                    text: TextSpan(
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13.5),
                      children: [
                        TextSpan(text: '$userName ', style: const TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: translatedContent),
                      ],
                    ),
                  );
                }
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

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: widget.post['content']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Post'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter new content'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final success = await SupabaseService.updatePost(
                postId: widget.post['id'].toString(),
                content: controller.text.trim(),
              );
              if (success && mounted) {
                Navigator.pop(context);
                widget.onUpdate();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => _CommentSheet(postId: widget.post['id'].toString(), scrollController: controller),
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
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    final comments = await SupabaseService.fetchComments(widget.postId);
    if (mounted) setState(() { _comments = comments; _isLoading = false; });
  }

  void _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    
    _commentController.clear();
    final success = await SupabaseService.addComment(widget.postId, text);
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
                    final user = comment['profiles'];
                    final String name = user?['full_name'] ?? user?['username'] ?? 'User';
                    return ListTile(
                      leading: const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16)),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      subtitle: Text(comment['text'] ?? '', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13)),
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
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
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
