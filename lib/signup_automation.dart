import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('-----------------------------------------');
  print('Impactly Signup Automation');
  
  await Parse().initialize(
    'Ot1QBE1dxFxarhPmKBKEztxmc7f289u7w7DHq5e0',
    'https://parseapi.back4app.com',
    clientKey: 'HYAeMieKjBKTH2V3xDgdCMjGEoG2yaNwr3o0BBra',
  );

  final user = ParseUser.createUser(
    'hamza_ali_mazari', 
    'Password123!', 
    'hamza.ali@mazari.com'
  )
    ..set('name', 'Hamza Ali Mazari')
    ..set('fullName', 'Hamza Ali Mazari')
    ..set('phone', '+919876543210')
    ..set('location', 'Lyari');

  print('👉 Signing up Hamza Ali Mazari...');
  final response = await user.signUp();

  if (response.success) {
    print('✅ SUCCESS: Hamza Ali Mazari is now registered!');
  } else {
    print('❌ FAILED: ${response.error?.message}');
  }
  print('-----------------------------------------');
  
  // Just a placeholder app so it doesn't crash immediately
  runApp(const MaterialApp(home: Scaffold(body: Center(child: Text('Done! Check console.')))));
}
