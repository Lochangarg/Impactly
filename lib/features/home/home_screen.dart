import 'package:flutter/material.dart';
import 'widgets/home_content.dart';

class HomeScreen extends StatelessWidget {
  final Function(int, {String? category})? onNavigate;
  const HomeScreen({super.key, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: HomeContent(onNavigate: onNavigate),
    );
  }
}
