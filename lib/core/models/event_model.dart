class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final int points;
  final String category;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.points,
    required this.category,
  });

  factory EventModel.fromParse(dynamic object) {
    return EventModel(
      id: object.objectId!,
      title: object.get<String>('title') ?? 'Untitled',
      description: object.get<String>('description') ?? '',
      location: object.get<String>('location') ?? 'No location',
      date: object.get<DateTime>('date') ?? DateTime.now(),
      points: object.get<int>('points') ?? 0,
      category: object.get<String>('category') ?? 'General',
    );
  }

  factory EventModel.fromMap(Map<String, dynamic> map) {
    return EventModel(
      id: map['id'].toString(),
      title: map['title'] ?? 'Untitled',
      description: map['description'] ?? '',
      location: map['location'] ?? 'No location',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      points: map['points'] ?? 0,
      category: map['category'] ?? 'General',
    );
  }
}
