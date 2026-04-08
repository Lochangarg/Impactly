import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('-----------------------------------------');
  print('Impactly Supabase Signup Automation');
  
  // Load environment variables for standalone script
  await dotenv.load(fileName: ".env");
  
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  final client = Supabase.instance.client;

  print('👉 Signing up Hamza Ali Mazari...');
  try {
    final response = await client.auth.signUp(
      email: 'hamza.ali@mazari.com',
      password: 'Password123!',
      data: {
        'full_name': 'Hamza Ali Mazari',
        'username': 'hamza_ali_mazari',
      },
    );

    if (response.user != null) {
      await client.from('profiles').insert({
        'id': response.user!.id,
        'full_name': 'Hamza Ali Mazari',
        'username': 'hamza_ali_mazari',
        'phone': '+919876543210',
        'city': 'Lyari',
      });
      print('✅ SUCCESS: Hamza Ali Mazari is now registered!');
    }
  } catch (e) {
    print('❌ FAILED: $e');
  }
  print('-----------------------------------------');
  
  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('Done! Check console.')))));
}
