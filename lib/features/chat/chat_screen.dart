import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/services/parse_service.dart';

class ChatScreen extends StatefulWidget {
  final ParseUser otherUser;
  const ChatScreen({super.key, required this.otherUser});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<ParseObject> _messages = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _initCurrentUser();
    _loadMessages();
  }

  Future<void> _initCurrentUser() async {
    final user = await ParseService.getCurrentUser();
    if (mounted && user != null) {
      setState(() {
        _currentUserId = user.objectId;
      });
    }
  }

  Future<void> _loadMessages() async {
    final msgs = await ParseService.fetchMessages(widget.otherUser);
    if (mounted) {
      setState(() {
        _messages = msgs;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    
    // Insert locally for immediate feedback
    // Since we don't have objectId/createdAt, it won't be perfectly standard but we reload anyway
    await ParseService.sendMessage(widget.otherUser, text);
    _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final String fullName = widget.otherUser.get<String>('fullName') ?? widget.otherUser.username ?? 'Chat';
    final dynamic profilePicRaw = widget.otherUser.get('profilePicture');
    final String? profileUrl = profilePicRaw is ParseFileBase 
        ? profilePicRaw.url 
        : (profilePicRaw is String ? profilePicRaw : null);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
              backgroundImage: profileUrl != null ? CachedNetworkImageProvider(profileUrl!) : null,
              child: profileUrl == null ? const Icon(Icons.person, size: 16, color: Color(0xFF6366F1)) : null,
            ),
            const SizedBox(width: 12),
            Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                : _messages.isEmpty 
                  ? Center(child: Text('Say Hi!', style: TextStyle(color: Theme.of(context).hintColor)))
                  : ListView.builder(
                      reverse: true, // Messages from parse are ordered by descending, so newest first
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final sender = msg.get<ParseUser>('sender');
                        final isMe = _currentUserId != null && sender?.objectId == _currentUserId;
                        final content = msg.get<String>('content') ?? '';

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8, top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isMe ? const Color(0xFF6366F1) : Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20).copyWith(
                                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
                                bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(20),
                              ),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Text(
                              content,
                              style: TextStyle(
                                color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -1))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: Theme.of(context).hintColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF6366F1),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
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
