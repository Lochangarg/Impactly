import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/auth_field.dart';
import 'widgets/auth_button.dart';
import '../onboarding/interests_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }
    if (value.length < 3) {
      return 'Name must be at least 3 characters';
    }
    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) {
      return 'Name should not contain numbers or special characters';
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(value)) {
      return 'Enter a valid Indian phone number';
    }
    return null;
  }

  void _onSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();
      final username = _usernameController.text.trim();
      final fullName = _fullNameController.text.trim();
      final phone = '+91${_phoneController.text.trim()}';
      final location = _locationController.text.trim();

      final user = ParseUser.createUser(username, password, email);
      user.set('name', fullName);
      user.set('fullName', fullName);
      user.set('phone', phone);
      user.set('location', location);

      final acl = ParseACL()
        ..setPublicReadAccess(allowed: true)
        ..setPublicWriteAccess(allowed: false);
      user.setACL(acl);

      final response = await user.signUp();

      setState(() => _isLoading = false);

      if (response.success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Account created! Let's personalize your feed 🚀"),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const InterestsScreen()),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.error!.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF111827), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.create_account,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF111827),
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(l10n.join_community, 
                  style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                const SizedBox(height: 32),
                
                _buildLabel(l10n.full_name),
                AuthField(
                  controller: _fullNameController,
                  hintText: 'e.g. Parikshit Kurel',
                  prefixIcon: Icons.person_outline,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]')),
                  ],
                  validator: validateName,
                ),
                const SizedBox(height: 16),

                _buildLabel(l10n.username),
                AuthField(
                  controller: _usernameController,
                  hintText: 'e.g. parikshit_impact',
                  prefixIcon: Icons.alternate_email,
                  validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                _buildLabel(l10n.email),
                AuthField(
                  controller: _emailController,
                  hintText: l10n.email_address,
                  prefixIcon: Icons.mail_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(l10n.phone),
                          AuthField(
                            controller: _phoneController,
                            hintText: '9876543210',
                            prefixIcon: Icons.phone_outlined,
                            prefixText: '+91 ',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            validator: validatePhone,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel(l10n.city),
                          AuthField(
                            controller: _locationController,
                            hintText: 'Location',
                            prefixIcon: Icons.location_on_outlined,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                _buildLabel(l10n.password),
                AuthField(
                  controller: _passwordController,
                  hintText: l10n.password,
                  isPasswordField: true,
                  prefixIcon: Icons.lock_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _buildLabel(l10n.confirm_password),
                AuthField(
                  controller: _confirmPasswordController,
                  hintText: 'Match password',
                  isPasswordField: true,
                  prefixIcon: Icons.lock_reset,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                
                const SizedBox(height: 48),
                
                AuthButton(
                  onPressed: _onSignup,
                  label: l10n.sign_up,
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 32),
                
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        l10n.already_have_account,
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          l10n.login,
                          style: const TextStyle(
                            color: Color(0xFF6366F1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
      ),
    );
  }
}
