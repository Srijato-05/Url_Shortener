import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../widgets/glass_container.dart';

class ShareHelper {
  /// Shares a shortened link using the native Web Share API, falling back to a custom platform dialog
  static Future<void> shareLink({
    required BuildContext context,
    required String url,
    String? title,
  }) async {
    final titleStr = title ?? 'Shortened URL';
    bool isNativeShared = false;

    try {
      // 1. Attempt native Web Share API (only works on HTTPS or localhost)
      if (html.window.navigator.share != null) {
        await html.window.navigator.share({
          'title': titleStr,
          'text': 'Check out this shortened link: $url',
          'url': url,
        });
        isNativeShared = true;
      }
    } catch (e) {
      // Fallback is triggered if native share fails or is blocked
    }

    if (!isNativeShared && context.mounted) {
      // 2. Fall back to custom Share Hub dialog
      _showSharePlatformDialog(context, url);
    }
  }

  /// Triggers a native browser download for the generated QR Code PNG image
  static void downloadQr({
    required String shortCode,
    required String qrUrl,
  }) {
    try {
      final anchor = html.AnchorElement(href: qrUrl)
        ..target = 'blank'
        ..download = 'qr_$shortCode.png';
      html.document.body?.append(anchor);
      anchor.click();
      anchor.remove();
    } catch (e) {
      // Fallback: opens the QR URL in a new tab if browser blocks anchor trigger
      html.window.open(qrUrl, '_blank');
    }
  }

  /// Displays the custom platform sharing overlay
  static void _showSharePlatformDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 380),
          child: GlassContainer(
            borderColor: Colors.white.withOpacity(0.12),
            fillColor: const Color(0xFF131218).withOpacity(0.96),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5A059).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.share, color: Color(0xFFC5A059), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Share Link',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildShareOption(
                  icon: Icons.chat_bubble_outline,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    html.window.open(
                      'https://api.whatsapp.com/send?text=${Uri.encodeComponent('Check out this shortened link: $url')}',
                      '_blank',
                    );
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                _buildShareOption(
                  icon: Icons.forum,
                  label: 'Discord',
                  color: const Color(0xFF5865F2),
                  onTap: () {
                    // Set clipboard synchronously in user gesture thread before any redirection
                    Clipboard.setData(ClipboardData(text: url));
                    html.window.open('https://discord.com/channels/@me', '_blank');
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied link to clipboard. Opening Discord...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildShareOption(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  color: const Color(0xFFEA4335),
                  onTap: () {
                    // mailto redirection inside the same browser tab prevents opening blank dummy tabs
                    html.window.open(
                      'mailto:?subject=${Uri.encodeComponent('Shortened URL Share')}&body=${Uri.encodeComponent('Check out this shortened link: $url')}',
                      '_self',
                    );
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: 12),
                _buildShareOption(
                  icon: Icons.copy,
                  label: 'Copy to Clipboard',
                  color: const Color(0xFFC5A059),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: url));
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied link to clipboard.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white60,
                      ),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 16),
          ],
        ),
      ),
    );
  }
}
