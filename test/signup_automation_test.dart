import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() {
  test('Signup Automation for Hamza Ali Mazari', () async {
    // Initialize Parse
    await Parse().initialize(
      'Ot1QBE1dxFxarhPmKBKEztxmc7f289u7w7DHq5e0',
      'https://parseapi.back4app.com',
      clientKey: 'HYAeMieKjBKTH2V3xDgdCMjGEoG2yaNwr3o0BBra',
    );

    final String username = 'hamza_ali_mazari';
    final String email = 'hamza.ali@mazari.com';
    final String password = 'Password123!';
    final String fullName = 'Hamza Ali Mazari';
    final String phone = '+919876543210';
    final String location = 'Lyari';

    print('🚀 Starting Signup Automation...');

    final user = ParseUser.createUser(username, password, email);
    user.set('name', fullName);
    user.set('fullName', fullName);
    user.set('phone', phone);
    user.set('location', location);

    // Set Permissions
    final acl = ParseACL()
      ..setPublicReadAccess(allowed: true)
      ..setPublicWriteAccess(allowed: false);
    user.setACL(acl);

    final response = await user.signUp();

    if (response.success) {
      print('✅ SUCCESS: Account created for $username');
      print('Username: $username');
      print('Password: $password');
    } else {
      print('❌ FAILED: ${response.error?.message}');
      if (response.error?.code == 202) {
        print('ℹ️ Note: Account already exists.');
      }
    }
  });
}
