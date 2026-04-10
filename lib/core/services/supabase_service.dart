import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final client = Supabase.instance.client;

  // --- AUTH ---
  static User? get currentUser => client.auth.currentUser;

  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp(String email, String password, {Map<String, dynamic>? data}) async {
    return await client.auth.signUp(email: email, password: password, data: data);
  }

  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  static Future<bool> updatePassword(String newPassword) async {
    try {
      await client.auth.updateUser(UserAttributes(password: newPassword));
      return true;
    } catch (e) {
      debugPrint('Error updating password: $e');
      return false;
    }
  }

  // --- PROFILE ---
  static Future<Map<String, dynamic>?> fetchUserDetails(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      debugPrint('Error fetching user details: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getProfile(String userId) => fetchUserDetails(userId);

  static Future<bool> updateProfile({
    required String userId,
    required Map<String, dynamic> data,
    Uint8List? imageBytes,
    String? fileExt,
  }) async {
    try {
      String? imageUrl;
      if (imageBytes != null) {
        final ext = fileExt ?? 'jpg';
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';
        
        await client.storage.from('profile_pictures').uploadBinary(
          fileName,
          imageBytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

        imageUrl = client.storage.from('profile_pictures').getPublicUrl(fileName);
        data['profile_picture'] = imageUrl;
      }

      await client.from('profiles').update(data).eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
    }
  }

  // --- EVENTS ---
  static Future<List<Map<String, dynamic>>> fetchEvents({String? category, String? searchQuery}) async {
    var query = client.from('events').select('*, profiles:created_by(*)');
    
    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('title', '%$searchQuery%');
    }
    
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<bool> createEvent({
    required String title,
    required String description,
    required String location,
    required String category,
    required int points,
    required DateTime date,
    Uint8List? imageBytes,
    String? fileExt,
  }) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      String? imageUrl;
      if (imageBytes != null) {
        imageUrl = await uploadEventImage(imageBytes, fileExt);
      }

      await client.from('events').insert({
        'title': title,
        'description': description,
        'location': location,
        'category': category,
        'points': points,
        'date': date.toIso8601String(),
        'created_by': user.id,
        'image_url': imageUrl,
      });
      return true;
    } catch (e) {
      debugPrint('Error creating event: $e');
      return false;
    }
  }

  static Future<bool> updateEvent({
    required String eventId,
    required Map<String, dynamic> data,
    Uint8List? imageBytes,
    String? fileExt,
  }) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      if (imageBytes != null) {
        data['image_url'] = await uploadEventImage(imageBytes, fileExt);
      }
      await client.from('events').update(data).eq('id', eventId).eq('created_by', user.id);
      return true;
    } catch (e) {
      debugPrint('Error updating event: $e');
      return false;
    }
  }

  static Future<bool> deleteEvent(String eventId) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      // Notify participants before deletion
      final event = await client.from('events').select('title').eq('id', eventId).single();
      await sendEventNotifications(
        eventId: eventId,
        message: 'The event "${event['title']}" has been cancelled.',
        type: 'event_cancelled',
      );

      await client.from('events').delete().eq('id', eventId).eq('created_by', user.id);
      return true;
    } catch (e) {
      debugPrint('Error deleting event: $e');
      return false;
    }
  }

  static Future<String?> uploadEventImage(Uint8List imageBytes, String? fileExt) async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final ext = fileExt ?? 'jpg';
      final fileName = 'event_${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      
      await client.storage.from('event_images').uploadBinary(
        fileName,
        imageBytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      return client.storage.from('event_images').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Error uploading event image: $e');
      return null;
    }
  }

  static Future<bool> joinEvent(String eventId) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      await client.from('user_events').insert({
        'user_id': user.id,
        'event_id': eventId,
        'status': 'award_pending',
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> leaveEvent(String eventId) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      await client
          .from('user_events')
          .delete()
          .eq('user_id', user.id)
          .eq('event_id', eventId);
      return true;
    } catch (e) {
      debugPrint('Error leaving event: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchJoinedEvents() async {
    final user = currentUser;
    if (user == null) return [];

    try {
      final response = await client
          .from('user_events')
          .select('events(*)')
          .eq('user_id', user.id);
      
      return List<Map<String, dynamic>>.from(response.map((e) => e['events'] as Map<String, dynamic>));
    } catch (e) {
      debugPrint('Error fetching joined events: $e');
      return [];
    }
  }

  // --- FEED ---
  static Future<List<Map<String, dynamic>>> fetchFeedPosts() async {
    final response = await client
        .from('posts')
        .select('*, profiles:created_by(*), events(*)')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> clearAllNotifications() async {
    final user = currentUser;
    if (user == null) return;
    await client.from('notifications').delete().eq('receiver_id', user.id);
  }

  static Future<void> markAllNotificationsAsRead() async {
    final user = currentUser;
    if (user == null) return;
    await client.from('notifications').update({'status': 'read'}).eq('receiver_id', user.id).eq('status', 'pending');
  }

  static Future<bool> createPost({
    required String content,
    required String eventId,
    Uint8List? imageBytes,
    String? fileExt,
  }) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      String? imageUrl;
      if (imageBytes != null) {
        imageUrl = await uploadPostImage(imageBytes, fileExt);
      }

      await client.from('posts').insert({
        'created_by': user.id,
        'event_id': eventId,
        'content': content,
        'image_url': imageUrl,
      });
      return true;
    } catch (e) {
      debugPrint('Error creating post: $e');
      return false;
    }
  }

  static Future<bool> updatePost({
    required String postId,
    required String content,
    Uint8List? imageBytes,
    String? fileExt,
  }) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      final Map<String, dynamic> data = {'content': content};
      if (imageBytes != null) {
        data['image_url'] = await uploadPostImage(imageBytes, fileExt);
      }
      await client.from('posts').update(data).eq('id', postId).eq('created_by', user.id);
      return true;
    } catch (e) {
      debugPrint('Error updating post: $e');
      return false;
    }
  }

  static Future<bool> deletePost(String postId) async {
    final user = currentUser;
    if (user == null) return false;

    try {
      await client.from('posts').delete().eq('id', postId).eq('created_by', user.id);
      return true;
    } catch (e) {
      debugPrint('Error deleting post: $e');
      return false;
    }
  }

  static Future<String?> uploadPostImage(Uint8List imageBytes, String? fileExt) async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final ext = fileExt ?? 'jpg';
      final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      
      await client.storage.from('post_images').uploadBinary(
        fileName,
        imageBytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      return client.storage.from('post_images').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Error uploading post image: $e');
      return null;
    }
  }

  // --- SOCIAL & LEADERBOARD ---
  static Future<List<Map<String, dynamic>>> fetchLeaderboard() async {
    final response = await client
        .from('profiles')
        .select()
        .order('points', ascending: false)
        .limit(10);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> getFriends({String? userId}) async {
    final id = userId ?? currentUser?.id;
    if (id == null) return [];
    
    final response = await client
        .from('friends')
        .select('profiles!friends_friend_id_fkey(*)')
        .eq('user_id', id);
    
    return List<Map<String, dynamic>>.from(response.map((e) => e['profiles']));
  }

  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final response = await client
        .from('profiles')
        .select()
        .ilike('username', '%$query%')
        .limit(20);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<List<Map<String, dynamic>>> searchPosts(String query) async {
    final response = await client
        .from('posts')
        .select('*, profiles:created_by(*), events(*)')
        .ilike('content', '%$query%')
        .limit(20);
    return List<Map<String, dynamic>>.from(response);
  }

  // --- NOTIFICATIONS ---
  static Future<List<Map<String, dynamic>>> fetchNotifications({bool onlyPending = false}) async {
    final user = currentUser;
    if (user == null) return [];

    var query = client
        .from('notifications')
        .select('*, profiles:sender_id(full_name, profile_picture)')
        .eq('receiver_id', user.id);
    
    if (onlyPending) {
      query = query.eq('status', 'pending');
    }
    
    final response = await query.order('created_at', ascending: false);
    
    // Deduplicate friend requests from the same user to avoid UI spam
    final List<Map<String, dynamic>> deduped = [];
    final Set<String> seenRequests = {};
    
    for (var notif in List<Map<String, dynamic>>.from(response)) {
      if (notif['type'] == 'friend_request') {
        final key = '${notif['sender_id']}_friend_request';
        if (seenRequests.contains(key)) continue;
        seenRequests.add(key);
      }
      deduped.add(notif);
    }
    
    return deduped;
  }

  static Future<void> sendEventNotifications({
    required String eventId,
    required String message,
    required String type,
  }) async {
    final user = currentUser;
    if (user == null) return;

    try {
      // 1. Fetch all users who have joined this event
      final participants = await client
          .from('user_events')
          .select('user_id')
          .eq('event_id', eventId);
      
      if (participants == null || (participants as List).isEmpty) return;

      final Set<String> receiverIds = (participants as List)
          .map<String>((p) => p['user_id'].toString())
          .toSet();
      
      // Don't notify the person who made the update
      receiverIds.remove(user.id);

      if (receiverIds.isEmpty) return;

      // 2. Insert notifications for all participants
      final List<Map<String, dynamic>> notifications = receiverIds.map((id) => {
        'receiver_id': id,
        'sender_id': user.id,
        'event_id': eventId,
        'type': type,
        'message': message,
      }).toList();

      await client.from('notifications').insert(notifications);
    } catch (e) {
      debugPrint('Error sending event notifications: $e');
    }
  }

  static Future<void> broadcastNotification({
    required String message,
    required String type,
    String? eventId,
  }) async {
    final user = currentUser;
    if (user == null) return;

    try {
      // Fetch all user IDs except the sender
      final profiles = await client.from('profiles').select('id');
      final List<String> userIds = (profiles as List)
          .map<String>((p) => p['id'].toString())
          .where((id) => id != user.id)
          .toList();

      if (userIds.isEmpty) return;

      final List<Map<String, dynamic>> notifications = userIds.map((id) => {
        'receiver_id': id,
        'sender_id': user.id,
        'type': type,
        'message': message,
        'event_id': eventId,
      }).toList();

      await client.from('notifications').insert(notifications);
    } catch (e) {
      debugPrint('Error broadcasting notification: $e');
    }
  }



  // --- CHAT ---
  static Stream<List<Map<String, dynamic>>> streamMessages(String otherUserId) {
    final myId = currentUser?.id;
    if (myId == null) return Stream.value([]);

    // We fetch messages where we are either sender or receiver
    // The RLS policy will also restrict this to only our messages
    return client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.where((m) => 
            (m['sender_id'] == myId && m['receiver_id'] == otherUserId) ||
            (m['sender_id'] == otherUserId && m['receiver_id'] == myId)
          ).toList());
  }

  static Future<void> sendMessage(String otherUserId, String text) async {
    final myId = currentUser?.id;
    if (myId == null) return;

    await client.from('messages').insert({
      'sender_id': myId,
      'receiver_id': otherUserId,
      'content': text,
    });
  }

  static Future<List<Map<String, dynamic>>> fetchChatPartners() async {
    final myId = currentUser?.id;
    if (myId == null) return [];

    try {
      // Fetch all messages where current user is involved
      final response = await client
          .from('messages')
          .select('sender_id, receiver_id')
          .or('sender_id.eq.$myId,receiver_id.eq.$myId');

      final Set<String> partnerIds = {};
      for (var msg in response) {
        if (msg['sender_id'] != myId) partnerIds.add(msg['sender_id']);
        if (msg['receiver_id'] != myId) partnerIds.add(msg['receiver_id']);
      }

      if (partnerIds.isEmpty) return [];

      // Fetch profiles of these partners
      final profiles = await client
          .from('profiles')
          .select()
          .inFilter('id', partnerIds.toList());

      return List<Map<String, dynamic>>.from(profiles);
    } catch (e) {
      debugPrint('Error fetching chat partners: $e');
      return [];
    }
  }

  // --- AWARDS ---
  static Future<List<Map<String, dynamic>>> fetchPendingAwardsForEvent(String eventId) async {
    final response = await client
        .from('user_events')
        .select('*, profiles:user_id(*)')
        .eq('event_id', eventId)
        .eq('status', 'award_pending');
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<bool> approveAward(String eventId, String userId, int points) async {
    try {
      await client.from('user_events').update({'status': 'approved'}).eq('event_id', eventId).eq('user_id', userId);
      final profile = await fetchUserDetails(userId);
      final currentPoints = profile?['points'] ?? 0;
      await updateProfile(userId: userId, data: {'points': currentPoints + points});
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> rejectAward(String eventId, String userId) async {
    try {
      await client.from('user_events').update({'status': 'rejected'}).eq('event_id', eventId).eq('user_id', userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchUserPosts(String userId) async {
    final response = await client
        .from('posts')
        .select('*, profiles:created_by(*), events(*)')
        .eq('created_by', userId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<bool> toggleLike(String postId) async {
    final userId = currentUser?.id;
    if (userId == null) return false;

    try {
      final post = await client.from('posts').select('likes').eq('id', postId).single();
      List<dynamic> likes = post['likes'] ?? [];
      
      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }
      
      await client.from('posts').update({'likes': likes}).eq('id', postId);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchComments(String postId) async {
    final response = await client
        .from('comments')
        .select('*, profiles:user_id(*)')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<bool> addComment(String postId, String text) async {
    final userId = currentUser?.id;
    if (userId == null) return false;

    try {
      await client.from('comments').insert({
        'post_id': postId,
        'user_id': userId,
        'text': text,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String> checkFriendshipStatus(String otherUserId) async {
    final myId = currentUser?.id;
    if (myId == null || myId == otherUserId) return 'None';

    try {
      final friendship = await client
          .from('friends')
          .select()
          .eq('user_id', myId)
          .eq('friend_id', otherUserId)
          .limit(1);
      if ((friendship as List).isNotEmpty) return 'Friends';

      final sentRequest = await client
          .from('notifications')
          .select()
          .eq('sender_id', myId)
          .eq('receiver_id', otherUserId)
          .eq('type', 'friend_request')
          .eq('status', 'pending')
          .limit(1);
      if ((sentRequest as List).isNotEmpty) return 'PendingSent';

      final receivedRequest = await client
          .from('notifications')
          .select()
          .eq('sender_id', otherUserId)
          .eq('receiver_id', myId)
          .eq('type', 'friend_request')
          .eq('status', 'pending')
          .limit(1);
      if ((receivedRequest as List).isNotEmpty) return 'PendingReceived';

      return 'None';
    } catch (e) {
      return 'None';
    }
  }

  static Future<bool> toggleFriend(String friendId) async {
    final myId = currentUser?.id;
    if (myId == null) return false;

    try {
      final status = await checkFriendshipStatus(friendId);
      if (status == 'Friends') {
        await client.from('friends').delete().eq('user_id', myId).eq('friend_id', friendId);
        await client.from('friends').delete().eq('user_id', friendId).eq('friend_id', myId);
        return true;
      } else if (status == 'None') {
        try {
          await client.from('notifications').insert({
            'receiver_id': friendId,
            'sender_id': myId,
            'type': 'friend_request',
            'message': 'sent you a friend request.',
            'status': 'pending',
          });
        } catch (e) {
          // Fallback if 'status' column is missing in the DB
          await client.from('notifications').insert({
            'receiver_id': friendId,
            'sender_id': myId,
            'type': 'friend_request',
            'message': 'sent you a friend request.',
          });
        }
        return true;
      } else if (status == 'PendingSent' || status == 'PendingReceived') {
        // Already requested or response pending - treat as success to avoid error message
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('CRITICAL: Error in toggleFriend: $e');
      return false;
    }
  }

  static Future<bool> respondToFriendRequest(String notificationId, bool accept) async {
    try {
      final notif = await client.from('notifications').select().eq('id', notificationId).single();
      final senderId = notif['sender_id'];
      final receiverId = notif['receiver_id'];

      await client.from('notifications').update({
        'status': accept ? 'accepted' : 'declined'
      }).eq('id', notificationId);

      if (accept) {
        await client.from('friends').insert([
          {'user_id': senderId, 'friend_id': receiverId},
          {'user_id': receiverId, 'friend_id': senderId},
        ]);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteAccount() async {
    try {
      final userId = currentUser?.id;
      if (userId == null) return false;
      
      // Delete profile first
      await client.from('profiles').delete().eq('id', userId);
      // Sign out
      await client.auth.signOut();
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      return false;
    }
  }
}
