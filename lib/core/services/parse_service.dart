import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class ParseService {
  static Set<String> joinedEventIds = {};

   // --- USER ---
  static Future<ParseUser?> getCurrentUser() async {
    return await ParseUser.currentUser() as ParseUser?;
  }

  static Future<void> _rewardUser(int amount) async {
    final user = await getCurrentUser();
    if (user == null) return;
    
    final currentPoints = user.get<int>('points') ?? 0;
    final totalPoints = currentPoints + amount;
    
    user.set('points', totalPoints);
    
    // Level up logic (e.g., Level up every 500 points)
    final newLevel = (totalPoints / 500).floor() + 1;
    user.set('level', newLevel);
    
    await user.save();
  }

  // --- EVENTS ---
  static Future<List<ParseObject>> fetchEvents({String? category, String? searchQuery}) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Events'));
    if (category != null && category != 'All') {
      query.whereEqualTo('category', category);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query.whereContains('title', searchQuery);
    }
    query.includeObject(['createdBy']);
    query.orderByDescending('createdAt');
    final response = await query.query();
    return response.success ? (response.results?.cast<ParseObject>() ?? []) : [];
  }

  static Future<List<ParseObject>> fetchRecommendedEvents(List<dynamic> interests) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Events'));
    if (interests.isNotEmpty) {
      query.whereContainedIn('category', interests);
    }
    query.includeObject(['createdBy']);
    query.orderByDescending('createdAt');
    query.setLimit(5);
    final response = await query.query();
    return response.success ? (response.results?.cast<ParseObject>() ?? []) : [];
  }

  static Future<bool> isUserJoined(ParseObject event) async {
    final user = await getCurrentUser();
    if (user == null) return false;

    final query = QueryBuilder<ParseObject>(ParseObject('UserEvents'))
      ..whereEqualTo('user', user)
      ..whereEqualTo('event', event);

    final response = await query.query();
    return response.success && response.results != null && response.results!.isNotEmpty;
  }

  static Future<bool> joinEvent(ParseObject event) async {
    final user = await getCurrentUser();
    if (user == null) return false;

    // Prevent duplicate join
    if (joinedEventIds.contains(event.objectId)) {
      return true;
    }

    final query = QueryBuilder<ParseObject>(ParseObject('UserEvents'))
      ..whereEqualTo('user', user)
      ..whereEqualTo('event', event);

    final checkResponse = await query.query();
    if (checkResponse.results != null && checkResponse.results!.isNotEmpty) {
      if (event.objectId != null) joinedEventIds.add(event.objectId!);
      return true;
    }

    final userEvent = ParseObject('UserEvents')
      ..set('user', user)
      ..set('event', event)
      ..set('joinedAt', DateTime.now());
    
    final response = await userEvent.save();
    if (response.success && event.objectId != null) {
      joinedEventIds.add(event.objectId!);
      // 🏆 Reward for joining
      await _rewardUser(50);
    }
    return response.success;
  }

  static Future<Set<String>> getJoinedEventIds() async {
    final user = await getCurrentUser();
    if (user == null) {
      joinedEventIds = {};
      return {};
    }

    final query = QueryBuilder<ParseObject>(ParseObject('UserEvents'))
      ..whereEqualTo('user', user)
      ..includeObject(['event']);
    
    final response = await query.query();
    if (!response.success || response.results == null) return joinedEventIds;

    joinedEventIds = response.results!
        .map((e) => (e as ParseObject).get<ParseObject>('event')?.objectId)
        .where((id) => id != null)
        .cast<String>()
        .toSet();
    
    return joinedEventIds;
  }

  static Future<List<ParseObject>> fetchJoinedEvents() async {
    final user = await getCurrentUser();
    if (user == null) return [];

    final query = QueryBuilder<ParseObject>(ParseObject('UserEvents'))
      ..whereEqualTo('user', user)
      ..includeObject(['event', 'event.createdBy']);
    
    final response = await query.query();
    if (!response.success || response.results == null) return [];

    return response.results!
        .map((e) => (e as ParseObject).get<ParseObject>('event'))
        .where((event) => event != null)
        .cast<ParseObject>()
        .toList();
  }

  // --- FEED & POSTS ---
  static Future<List<ParseObject>> fetchFeedPosts() async {
    final query = QueryBuilder<ParseObject>(ParseObject('Posts'))
      ..includeObject(['createdBy', 'event'])
      ..orderByDescending('createdAt');
    
    final response = await query.query();
    if (!response.success && response.error != null) {
      debugPrint('ERROR: Feed Fetch Failed: ${response.error!.message}');
    }
    return response.success ? (response.results?.cast<ParseObject>() ?? []) : [];
  }

  static Future<List<ParseObject>> fetchUserPosts(ParseUser user) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Posts'))
      ..whereEqualTo('createdBy', user.toPointer())
      ..includeObject(['createdBy', 'event'])
      ..orderByDescending('createdAt');
    
    final response = await query.query();
    return response.success ? (response.results?.cast<ParseObject>() ?? []) : [];
  }

  static Future<bool> createPost({required String content, required ParseObject event, File? image}) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return false;

    final post = ParseObject('Posts')
      ..set('content', content)
      ..set('createdBy', currentUser)
      ..set('event', event.toPointer());

    if (image != null) {
      post.set('image', ParseFile(image));
    }

    final response = await post.save();
    if (response.success) {
      // 🏆 Reward for post
      await _rewardUser(20);
    }
    return response.success;
  }

  static Future<bool> toggleLike(ParseObject post) async {
    final user = await getCurrentUser();
    if (user == null) return false;

    final List<dynamic> likes = post.get<List<dynamic>>('likes') ?? [];
    final String userId = user.objectId!;

    if (likes.contains(userId)) {
      likes.remove(userId);
    } else {
      likes.add(userId);
    }

    post.set('likes', likes);
    final response = await post.save();
    return response.success;
  }

  static Future<List<ParseObject>> fetchComments(String postId) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Comments'))
      ..whereEqualTo('post', (ParseObject('Posts')..objectId = postId).toPointer())
      ..includeObject(['user'])
      ..orderByAscending('createdAt');
    
    final response = await query.query();
    return response.success ? (response.results?.cast<ParseObject>() ?? []) : [];
  }

  static Future<bool> addComment(String postId, String text) async {
    final user = await getCurrentUser();
    if (user == null) return false;

    final comment = ParseObject('Comments')
      ..set('text', text)
      ..set('user', user)
      ..set('post', (ParseObject('Posts')..objectId = postId).toPointer());
    
    final response = await comment.save();
    return response.success;
  }

  // --- PROFILE ---
  static Future<bool> updateProfile(Map<String, dynamic> data) async {
    final user = await getCurrentUser();
    if (user == null) return false;

    for (var entry in data.entries) {
      if (entry.value is File) {
        user.set(entry.key, ParseFile(entry.value));
      } else {
        user.set(entry.key, entry.value);
      }
    }

    final response = await user.save();
    if (response.success) {
      await user.fetch();
    }
    return response.success;
  }

  // --- LEADERBOARD ---
  static Future<List<ParseUser>> fetchLeaderboard() async {
    final query = QueryBuilder<ParseUser>(ParseUser.forQuery())
      ..orderByDescending('points')
      ..setLimit(50);
    
    final response = await query.query();
    return response.success ? (response.results?.cast<ParseUser>() ?? []) : [];
  }

  // --- SOCIAL / FRIENDS ---
  static Future<List<ParseUser>> searchUsers(String queryText) async {
    final currentUser = await getCurrentUser();
    
    // Search by username
    final queryUsername = QueryBuilder<ParseUser>(ParseUser.forQuery())
      ..whereContains('username', queryText);
    
    // Search by fullName
    final queryFullName = QueryBuilder<ParseUser>(ParseUser.forQuery())
      ..whereContains('fullName', queryText);
    
    final mainQuery = QueryBuilder.or(ParseUser.forQuery(), [queryUsername, queryFullName]);
    if (currentUser != null) {
      mainQuery.whereNotEqualTo('objectId', currentUser.objectId);
    }
    mainQuery.setLimit(20);
    
    final response = await mainQuery.query();
    return response.success ? (response.results?.cast<ParseUser>() ?? []) : [];
  }

  static Future<bool> toggleFriend(ParseUser targetUser) async {
    try {
      final currentUser = await ParseUser.currentUser() as ParseUser?;
      if (currentUser == null) {
        debugPrint('ERROR: No current user found.');
        return false;
      }

      final isFriend = await checkIfFriend(targetUser);

      if (isFriend) {
        currentUser.removeRelation('friends', [targetUser]);
      } else {
        currentUser.addRelation('friends', [targetUser]);
      }

      final response = await currentUser.save();
      if (!response.success && response.error != null) {
        debugPrint('PARSE ERROR during save: ${response.error!.message}');
      }
      return response.success;
    } catch (e) {
      debugPrint('EXCEPTION in toggleFriend: $e');
      return false;
    }
  }

  static Future<bool> checkIfFriend(ParseObject targetUser) async {
    try {
      final currentUser = await ParseUser.currentUser() as ParseUser?;
      if (currentUser == null) return false;

      final relation = currentUser.getRelation('friends');
      final query = relation.getQuery()
        ..whereEqualTo('objectId', targetUser.objectId);
      
      final response = await query.query();
      return response.success && response.results != null && response.results!.isNotEmpty;
    } catch (e) {
      debugPrint('EXCEPTION in checkIfFriend: $e');
      return false;
    }
  }

  static Future<List<ParseUser>> getFriends() async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return [];

    final relation = currentUser.getRelation('friends');
    final response = await relation.getQuery().query();
    
    return response.success ? (response.results?.cast<ParseUser>() ?? []) : [];
  }

  // --- CHAT / MESSAGES ---
  static Future<bool> sendMessage(ParseUser receiver, String text) async {
    final sender = await getCurrentUser();
    if (sender == null) return false;

    final message = ParseObject('DirectMessages')
      ..set('sender', sender)
      ..set('receiver', receiver)
      ..set('content', text);

    final response = await message.save();
    return response.success;
  }

  static Future<List<ParseObject>> fetchMessages(ParseUser otherUser) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return [];

    final query1 = QueryBuilder<ParseObject>(ParseObject('DirectMessages'))
      ..whereEqualTo('sender', currentUser.toPointer())
      ..whereEqualTo('receiver', otherUser.toPointer());

    final query2 = QueryBuilder<ParseObject>(ParseObject('DirectMessages'))
      ..whereEqualTo('sender', otherUser.toPointer())
      ..whereEqualTo('receiver', currentUser.toPointer());

    final mainQuery = QueryBuilder.or(ParseObject('DirectMessages'), [query1, query2])
      ..includeObject(['sender', 'receiver'])
      ..orderByDescending('createdAt')
      ..setLimit(50);

    final response = await mainQuery.query();
    return response.success ? (response.results?.cast<ParseObject>() ?? []) : [];
  }

  static Future<List<ParseUser>> fetchChatPartners() async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return [];

    final query1 = QueryBuilder<ParseObject>(ParseObject('DirectMessages'))
      ..whereEqualTo('sender', currentUser.toPointer());
      
    final query2 = QueryBuilder<ParseObject>(ParseObject('DirectMessages'))
      ..whereEqualTo('receiver', currentUser.toPointer());

    final mainQuery = QueryBuilder.or(ParseObject('DirectMessages'), [query1, query2])
      ..includeObject(['sender', 'receiver'])
      ..orderByDescending('createdAt')
      ..setLimit(100);

    final response = await mainQuery.query();
    if (!response.success || response.results == null) {
      // If no messages, return empty list. Or we could fallback to friends.
      return [];
    }

    final Set<String> uniqueIds = {};
    final List<ParseUser> partners = [];

    for (var msg in response.results!) {
      final obj = msg as ParseObject;
      final senderObj = obj.get('sender');
      final receiverObj = obj.get('receiver');
      
      if (senderObj != null && senderObj is ParseUser && senderObj.objectId != currentUser.objectId) {
        if (!uniqueIds.contains(senderObj.objectId!)) {
          uniqueIds.add(senderObj.objectId!);
          partners.add(senderObj);
        }
      }
      if (receiverObj != null && receiverObj is ParseUser && receiverObj.objectId != currentUser.objectId) {
        if (!uniqueIds.contains(receiverObj.objectId!)) {
          uniqueIds.add(receiverObj.objectId!);
          partners.add(receiverObj);
        }
      }
    }
    return partners;
  }

  // --- NOTIFICATIONS ---
  static Future<List<ParseObject>> fetchNotifications() async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return [];

    final query = QueryBuilder<ParseObject>(ParseObject('Notifications'))
      ..whereEqualTo('receiver', currentUser.toPointer())
      ..includeObject(['sender', 'event'])
      ..orderByDescending('createdAt');

    final response = await query.query();
    return response.success ? (response.results?.cast<ParseObject>() ?? []) : [];
  }

  static Future<bool> sendFriendRequest(ParseUser receiver) async {
    final sender = await getCurrentUser();
    if (sender == null) return false;

    // Check if request already exists
    final checkQuery = QueryBuilder<ParseObject>(ParseObject('Notifications'))
      ..whereEqualTo('sender', sender)
      ..whereEqualTo('receiver', receiver)
      ..whereEqualTo('type', 'friend_request');
    
    final checkResponse = await checkQuery.query();
    if (checkResponse.success && checkResponse.results != null && checkResponse.results!.isNotEmpty) {
      return true; // Already sent
    }

    final notification = ParseObject('Notifications')
      ..set('sender', sender)
      ..set('receiver', receiver)
      ..set('type', 'friend_request')
      ..set('status', 'pending')
      ..set('message', '${sender.get<String>('fullName') ?? sender.username} sent you a friend request');

    final response = await notification.save();
    return response.success;
  }

  static Future<bool> respondToFriendRequest(ParseObject notification, bool accept) async {
    if (accept) {
      final sender = notification.get<ParseUser>('sender');
      if (sender != null) {
        await toggleFriend(sender);
      }
      notification.set('status', 'accepted');
    } else {
      notification.set('status', 'declined');
    }
    
    final response = await notification.save();
    return response.success;
  }

  // --- OTHER USER PROFILE ---
  static Future<ParseUser?> fetchUserDetails(String userId) async {
    final query = QueryBuilder<ParseUser>(ParseUser.forQuery())
      ..whereEqualTo('objectId', userId);
    
    final response = await query.query();
    if (response.success && response.results != null && response.results!.isNotEmpty) {
      return response.results!.first as ParseUser;
    }
    return null;
  }
}
