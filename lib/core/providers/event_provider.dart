import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class EventProvider extends ChangeNotifier {
  Set<String> joinedEventIds = {};

  Future<void> loadJoinedEvents() async {
    var user = await ParseUser.currentUser();

    final query = QueryBuilder<ParseObject>(ParseObject('UserEvents'))
      ..whereEqualTo('user', user)
      ..includeObject(['event']);

    final response = await query.query();

    if (response.results != null) {
      joinedEventIds = response.results!
        .map<String>((e) => e.get<ParseObject>('event')!.objectId!)
        .toSet();
    }

    notifyListeners(); // 🔥 important
  }

  bool isUserJoined(String? eventId) {
    if (eventId == null) return false;
    return joinedEventIds.contains(eventId);
  }

  Future<void> joinEvent(ParseObject event) async {
    final user = await ParseUser.currentUser() as ParseUser?;
    if (user == null) return;

    // 1. Check if already joined (client-side safety)
    if (joinedEventIds.contains(event.objectId)) return;

    // 2. Create the join record
    final userEvent = ParseObject('UserEvents')
      ..set('user', user)
      ..set('event', event.toPointer())
      ..set('joinedAt', DateTime.now());

    final response = await userEvent.save();

    if (response.success) {
      // 3. AWARD POINTS & UPDATE LEVEL 🚀
      final int awardAmount = event.get<int>('points') ?? 50; // Use event points or default 50
      final int currentPoints = user.get<int>('points') ?? 0;
      final int newPoints = currentPoints + awardAmount;
      
      user.set('points', newPoints);
      user.set('level', (newPoints / 100).floor() + 1); // Level up every 100 points
      
      await user.save();

      // 4. Update local state
      if (event.objectId != null) {
        joinedEventIds.add(event.objectId!);
      }
      notifyListeners();
    }
  }
}