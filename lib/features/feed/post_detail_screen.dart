import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/services/parse_service.dart';
import '../../l10n/app_localizations.dart';

class PostDetailScreen extends StatefulWidget {
  final ParseObject post;
  final String userName;
  final String? userProfileUrl;
  final String eventTitle;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.userName,
    this.userProfileUrl,
    required this.eventTitle,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  List<ParseObject> _comments = [];
  bool _isLoadingComments = true;
  bool _isLiked = false;
  int _likeCount = 0;
  ParseUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    _currentUser = await ParseService.getCurrentUser();
    final List<dynamic> likes = widget.post.get<List<dynamic>>('likes') ?? [];
    if (_currentUser != null) {
      _isLiked = likes.contains(_currentUser!.objectId);
    }
    _likeCount = likes.length;
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    if (mounted) setState(() => _isLoadingComments = true);
    final comments = await ParseService.fetchComments(widget.post.objectId!);
    if (mounted) {
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _handleLike() async {
    if (_currentUser == null) return;
    
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });

    final success = await ParseService.toggleLike(widget.post);
    if (!success) {
      // Revert if failed
      setState(() {
        _isLiked = !_isLiked;
        _likeCount += _isLiked ? 1 : -1;
      });
    }
  }

  Future<void> _handleAddComment() async {
    if (_commentController.text.trim().isEmpty) return;
    
    final text = _commentController.text.trim();
    _commentController.clear();
    FocusScope.of(context).unfocus();

    final success = await ParseService.addComment(widget.post.objectId!, text);
    if (success) {
      _fetchComments();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = widget.post.createdAt;
    final locale = Localizations.localeOf(context).toString();
    final dateStr = date != null ? DateFormat('MMM d, yyyy • hh:mm a', locale).format(date) : l10n.recently;
    final postImageUrl = widget.post.get<ParseFile>('image')?.url;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.post, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFF6366F1),
                        backgroundImage: widget.userProfileUrl != null ? CachedNetworkImageProvider(widget.userProfileUrl!) : null,
                        child: widget.userProfileUrl == null ? const Icon(Icons.person, color: Colors.white) : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
                          Text(dateStr, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Event Tag
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event, size: 14, color: Color(0xFF6366F1)),
                        const SizedBox(width: 6),
                        Text(
                          widget.eventTitle,
                          style: const TextStyle(color: Color(0xFF6366F1), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Content
                  Text(
                    widget.post.get<String>('content') ?? '',
                    style: TextStyle(fontSize: 16, height: 1.6, color: Theme.of(context).colorScheme.onSurface),
                  ),
                  
                  // Image
                  if (postImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(
                          imageUrl: postImageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 300,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  const Divider(),
                  
                  // Actions Info
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _handleLike,
                        child: Row(
                          children: [
                              Icon(
                                _isLiked ? Icons.favorite : Icons.favorite_border,
                                color: _isLiked ? Colors.redAccent : Theme.of(context).hintColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.likes_count(_likeCount),
                                style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, color: Theme.of(context).hintColor, size: 22),
                            const SizedBox(width: 8),
                            Text(
                              '${_comments.length} ${l10n.comments}',
                              style: TextStyle(color: Theme.of(context).hintColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  Text(l10n.comments, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Comments List
                  if (_isLoadingComments)
                    const Center(child: CircularProgressIndicator(strokeWidth: 2))
                  else if (_comments.isEmpty)
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Icon(Icons.chat_bubble_outline, size: 40, color: Theme.of(context).dividerColor),
                          const SizedBox(height: 8),
                          Text(l10n.no_comments, style: TextStyle(color: Theme.of(context).hintColor)),
                        ],
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        final user = comment.get<ParseUser>('user');
                        final userName = user?.get<String>('fullName') ?? user?.username ?? 'User';
                        final avatar = user?.get('profilePicture');
                        final avatarUrl = avatar is ParseFileBase ? avatar.url : (avatar is String ? avatar : null);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                                backgroundImage: avatarUrl != null ? CachedNetworkImageProvider(avatarUrl) : null,
                                child: avatarUrl == null ? const Icon(Icons.person, size: 18, color: Color(0xFF6366F1)) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface)),
                                    const SizedBox(height: 4),
                                    Text(
                                      comment.get<String>('text') ?? '',
                                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          
          // Comment Input
          Container(
            padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).padding.bottom + 10),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: l10n.add_comment,
                      hintStyle: TextStyle(color: Theme.of(context).hintColor),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _handleAddComment,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
