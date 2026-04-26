import 'package:flutter/material.dart';
import '../widgets/shorten_form.dart';
import '../widgets/history_list.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('STANDARD URL CONVERSION'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.blueGrey[900],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeroSection(),
              const SizedBox(height: 64),
              const ShortenForm(),
              const SizedBox(height: 80),
              _buildFeaturesGrid(context),
              const SizedBox(height: 80),
              const HistoryList(),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ANONYMOUS\nLINK MANAGEMENT',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -1.5,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'A high-performance utility for secure URL abbreviation, real-time telemetry, and persistent local link management. No account registration required.',
          style: TextStyle(
            fontSize: 18,
            color: Colors.blueGrey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SYSTEM CAPABILITIES',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            color: Colors.blueGrey[400],
          ),
        ),
        const SizedBox(height: 32),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
          childAspectRatio: 2.5,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          children: [
            _buildFeatureItem(
              Icons.qr_code_scanner,
              'Dynamic QR Generation',
              'Instant high-resolution code generation for every abbreviation.',
            ),
            _buildFeatureItem(
              Icons.analytics_outlined,
              'Real-Time Telemetry',
              'Publicly accessible engagement data and device distribution.',
            ),
            _buildFeatureItem(
              Icons.history,
              'Local Persistence',
              'Secure client-side history for anonymous session management.',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
