import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/shorten_form.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium URL Shortener v3.0'),
        actions: [
          TextButton.icon(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.login, color: Colors.white),
            label: const Text('Sign In', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Text(
                'Shorten your long links instantly',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              const ShortenForm(),
              const SizedBox(height: 48),
              const Divider(),
              const SizedBox(height: 32),
              const Text(
                'Why sign up? Get detailed analytics, click tracking, and link history management.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Center(
                child: OutlinedButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Get Started for Free'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
