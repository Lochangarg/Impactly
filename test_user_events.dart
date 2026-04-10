import 'dart:convert';
import 'dart:io';

void main() async {
  var url = Uri.parse('https://cmkwdxrvdzhfrxxiroxr.supabase.co/rest/v1/user_events');
  var request = await HttpClient().postUrl(url);
  request.headers.add('apikey', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3dkeHJ2ZHpoZnJ4eGlyb3hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMjc4NDksImV4cCI6MjA5MDgwMzg0OX0.H5W11ic9mhFUOsawu91x-Fkr6TEmdP56lsSAIfmb8pU');
  request.headers.add('Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNta3dkeHJ2ZHpoZnJ4eGlyb3hyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMjc4NDksImV4cCI6MjA5MDgwMzg0OX0.H5W11ic9mhFUOsawu91x-Fkr6TEmdP56lsSAIfmb8pU');
  request.headers.add('Content-Type', 'application/json');
  request.headers.add('Prefer', 'return=representation');
  request.write(jsonEncode({'user_id': '00000000-0000-0000-0000-000000000000', 'event_id': '00000000-0000-0000-0000-000000000000'}));
  var response = await request.close();
  var body = await response.transform(utf8.decoder).join();
  print('Response code: ${response.statusCode}');
  print('Response body: $body');
}
