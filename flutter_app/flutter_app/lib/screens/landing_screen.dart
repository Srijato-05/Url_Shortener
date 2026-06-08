import 'package:flutter/material.dart';
import '../widgets/shorten_form.dart';
import '../widgets/history_list.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Base Dark Charcoal-Gold to Deep Black Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF221F2B),
                  Color(0xFF060509),
                ],
              ),
            ),
          ),

          // Radial Mesh 1: Bright Gold Accent (Top Right)
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 550,
              height: 550,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC5A059).withOpacity(0.38),
                    blurRadius: 220,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),
          
          // Radial Mesh 2: Warm Golden Bronze (Bottom Left)
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 550,
              height: 550,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8C6D31).withOpacity(0.32),
                    blurRadius: 220,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // Radial Mesh 3: Center-Left Warm Copper
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 250,
            left: -150,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5D4037).withOpacity(0.28),
                    blurRadius: 180,
                    spreadRadius: 30,
                  ),
                ],
              ),
            ),
          ),

          // Radial Mesh 4: Brilliant Golden Backlight (Directly behind the Glassmorphism Card Deck)
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 220,
            left: MediaQuery.of(context).size.width / 2 - 250,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE5C180).withOpacity(0.30),
                    blurRadius: 200,
                    spreadRadius: 40,
                  ),
                ],
              ),
            ),
          ),

          // Custom Painted Hyperlink Web Overlay & Flowing Bezier Connections (High Visibility)
          Positioned.fill(
            child: CustomPaint(
              painter: WebPainter(),
            ),
          ),

          // Foreground Content
          Positioned.fill(
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Clean Corporate Header with Gradient Text
                  _buildHeader(context),
                  const Divider(color: Colors.white10, height: 1),
                  
                  // Top-Down Content Layout
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: const [
                              ShortenForm(),
                              SizedBox(height: 32),
                              HistoryList(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFE5C180), Color(0xFF9E7E45)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'URL Shortener',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white, // Must be white for gradient mask
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Enterprise link management service',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.4),
                ),
              ),
            ],
          ),
          // Clean Minimal Status Indicators
          if (screenWidth > 640)
            Row(
              children: [
                _buildStatusIndicator('Database', true),
                const SizedBox(width: 16),
                _buildStatusIndicator('Cache', true),
                const SizedBox(width: 16),
                _buildStatusIndicator('Worker', true),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String name, bool isActive) {
    final color = isActive ? const Color(0xFFC5A059) : Colors.redAccent;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              if (isActive)
                BoxShadow(
                  color: color.withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class WebPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw a very fine structural grid pattern (technological blueprint style)
    final gridPaint = Paint()
      ..color = const Color(0xFFC5A059).withOpacity(0.025)
      ..strokeWidth = 0.6;

    final gridSpacing = 48.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Draw elegant concentric wireframe orbits (representing data pathways and links)
    final orbitPaint1 = Paint()
      ..color = const Color(0xFFC5A059).withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final orbitPaint2 = Paint()
      ..color = const Color(0xFF8C6D31).withOpacity(0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Top-Right Orbit Hub
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), 120.0, orbitPaint1);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), 240.0, orbitPaint2);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), 360.0, orbitPaint1);

    // Bottom-Left Orbit Hub
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.8), 160.0, orbitPaint1);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.8), 300.0, orbitPaint2);

    // 3. Draw curved flow connections (Bezier paths)
    final flowPaint = Paint()
      ..color = const Color(0xFFC5A059).withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;

    final flowPaintSecondary = Paint()
      ..color = const Color(0xFF8C6D31).withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    // Bezier flow line 1
    final path1 = Path();
    path1.moveTo(0, size.height * 0.25);
    path1.cubicTo(size.width * 0.3, size.height * 0.1, size.width * 0.6, size.height * 0.5, size.width, size.height * 0.35);
    canvas.drawPath(path1, flowPaint);

    // Bezier flow line 2
    final path2 = Path();
    path2.moveTo(0, size.height * 0.6);
    path2.cubicTo(size.width * 0.4, size.height * 0.85, size.width * 0.7, size.height * 0.3, size.width, size.height * 0.55);
    canvas.drawPath(path2, flowPaintSecondary);

    // 4. Draw detailed node network
    final linePaint = Paint()
      ..color = const Color(0xFFC5A059).withOpacity(0.12)
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = const Color(0xFFC5A059).withOpacity(0.40)
      ..style = PaintingStyle.fill;

    final dotGlowPaint = Paint()
      ..color = const Color(0xFFE5C180).withOpacity(0.18)
      ..style = PaintingStyle.fill;

    // Fixed network nodes coordinates across the screen
    final nodes = [
      Offset(size.width * 0.08, size.height * 0.22),
      Offset(size.width * 0.22, size.height * 0.14),
      Offset(size.width * 0.14, size.height * 0.38),
      Offset(size.width * 0.30, size.height * 0.32),
      Offset(size.width * 0.04, size.height * 0.65),
      Offset(size.width * 0.25, size.height * 0.55),
      
      Offset(size.width * 0.92, size.height * 0.25),
      Offset(size.width * 0.78, size.height * 0.18),
      Offset(size.width * 0.86, size.height * 0.44),
      Offset(size.width * 0.70, size.height * 0.36),
      Offset(size.width * 0.96, size.height * 0.72),
      Offset(size.width * 0.74, size.height * 0.62),
    ];

    // Connect nodes within specific distances
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist < size.width * 0.22) {
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }

    // Draw node dots with double-pass glowing cores
    for (final node in nodes) {
      canvas.drawCircle(node, 8.5, dotGlowPaint);
      canvas.drawCircle(node, 4.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
