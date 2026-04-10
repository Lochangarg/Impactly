import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class EventProvider extends ChangeNotifier {
  Set<String> joinedEventIds = {};

  Future<void> loadJoinedEvents() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await Supabase.instance.client
          .from('user_events')
          .select('event_id');

      joinedEventIds = (response as List)
          .map<String>((e) => e['event_id'].toString())
          .toSet();
    } catch (e) {
      debugPrint('Error loading joined events: $e');
    }

    notifyListeners();
  }

  bool isUserJoined(String? eventId) {
    if (eventId == null) return false;
    return joinedEventIds.contains(eventId);
  }

  Future<String?> joinEvent(String eventId, int points) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return "User is not logged in";

    if (joinedEventIds.contains(eventId)) return null;

    try {
      await Supabase.instance.client.from('user_events').insert({
        'user_id': user.id,
        'event_id': eventId,
        'status': 'award_pending',
      });
    } catch (e) {
      // Handle the case where user is already joined in the database
      if (e is PostgrestException && e.code == '23505') {
        // Just continue, we'll sync the state below
      } else {
        return e.toString();
      }
    }

    joinedEventIds.add(eventId);
    notifyListeners();

    // Points are no longer awarded automatically upon joining.
    // They must be manually awarded by the Host later.
    return null;
  }

  Future<bool> leaveEvent(String eventId, int points) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;

    final success = await SupabaseService.leaveEvent(eventId);

    if (success) {
      joinedEventIds.remove(eventId);
      notifyListeners();

      // Points are no longer deducted automatically if leaving,
      // as they were not awarded automatically.
      return true;
    }
    return false;
  }
}