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

  Future<void> joinEvent(String eventId, int points) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    if (joinedEventIds.contains(eventId)) return;

    final success = await SupabaseService.joinEvent(eventId);

    if (success) {
      // Award Points
      try {
        final profileResp = await Supabase.instance.client
            .from('profiles')
            .select('points')
            .eq('id', user.id)
            .single();
        
        final currentPoints = profileResp['points'] as int? ?? 0;
        final newPoints = currentPoints + points;
        final newLevel = (newPoints / 100).floor() + 1;
        
        await SupabaseService.updateProfile(
          userId: user.id,
          data: {
            'points': newPoints,
            'level': newLevel,
          },
        );

        joinedEventIds.add(eventId);
        notifyListeners();
      } catch (e) {
        debugPrint('Error awarding points: $e');
      }
    }
  }
}