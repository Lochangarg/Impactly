class Event {
  final String title;
  final String date;
  final String time;
  final String location;
  final int points;
  final String category;
  final String imageUrl;

  Event({
    required this.title,
    required this.date,
    required this.time,
    required this.location,
    required this.points,
    required this.category,
    this.imageUrl = '',
  });
}

final List<Event> dummyEvents = [
  Event(
    title: 'Beach Cleanup Drive',
    date: 'March 25, 2024',
    time: '09:00 AM - 12:00 PM',
    location: 'Marine Drive Beach',
    points: 150,
    category: 'Cleaning',
  ),
  Event(
    title: 'Elderly Care Visit',
    date: 'March 26, 2024',
    time: '10:00 AM - 01:00 PM',
    location: 'Sunshine Home',
    points: 200,
    category: 'Volunteering',
  ),
  Event(
    title: 'Sustainable Living Workshop',
    date: 'March 28, 2024',
    time: '02:00 PM - 04:00 PM',
    location: 'Green Community Hall',
    points: 100,
    category: 'Workshops',
  ),
  Event(
    title: 'Community Music Night',
    date: 'March 30, 2024',
    time: '06:00 PM - 09:00 PM',
    location: 'Central Park',
    points: 50,
    category: 'Music',
  ),
  Event(
    title: 'Charity Football Match',
    date: 'April 02, 2024',
    time: '04:00 PM - 06:30 PM',
    location: 'Sports Complex',
    points: 120,
    category: 'Social',
  ),
];
