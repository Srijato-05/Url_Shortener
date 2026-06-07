import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:qr_flutter/qr_flutter.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../notifiers/link_notifier.dart';
import '../notifiers/history_notifier.dart';
import '../models/link_model.dart';

class ShortenForm extends ConsumerStatefulWidget {
  const ShortenForm({super.key});

  @override
  ConsumerState<ShortenForm> createState() => _ShortenFormState();
}

class _ShortenFormState extends ConsumerState<ShortenForm> {
  final _urlController = TextEditingController();
  final _aliasController = TextEditingController();
  DateTime? _selectedDate;
  bool _isShortening = false;
  LinkModel? _lastLink;

  @override
  void dispose() {
    _urlController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  Future<void> _handleShorten() async {
    if (_urlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Validation Error: URL input is required.')),
      );
      return;
    }

    setState(() {
      _isShortening = true;
      _lastLink = null;
    });
    try {
      final newLink = await ref.read(linksProvider.notifier).shortenUrl(
        _urlController.text,
        customAlias: _aliasController.text.isEmpty ? null : _aliasController.text,
        expiry: _selectedDate,
      );
      
      if (mounted) {
        // Save to Local History
        await ref.read(historyProvider.notifier).addLink(newLink);
        
        setState(() {
          _lastLink = newLink;
        });
        _urlController.clear();
        _aliasController.clear();
        setState(() => _selectedDate = null);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL shortened and saved to history!')),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'System Error: Verification of technical integrity failed.';
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('400')) {
          msg = 'Alias Collision: This custom name is already reserved.';
        } else if (errStr.contains('410')) {
          msg = 'Security Error: This link has reached its expiry threshold.';
        } else if (errStr.contains('connection')) {
          msg = 'Connectivity Alert: Synchronization with the backend failed.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
 finally {
      if (mounted) setState(() => _isShortening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocalhost = html.window.location.hostname == 'localhost' || html.window.location.hostname == '127.0.0.1';

    return Column(
      children: [
        if (isLocalhost)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.amber.shade900, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'To scan QR codes from other devices (like mobile phones) on the same Wi-Fi, access this page using your computer\'s LAN IP or computer name on port 8081 (e.g. http://192.168.31.246:8081) instead of localhost.',
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'Enter long URL',
                    hintText: 'https://example.com/very-long-path',
                    prefixIcon: Icon(Icons.link),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _aliasController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Alias (optional)',
                          prefixIcon: Icon(Icons.alternate_email),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              23,
                              59,
                              59,
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_selectedDate == null 
                        ? 'Expiry' 
                        : DateFormat.yMd().format(_selectedDate!)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isShortening ? null : _handleShorten,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isShortening 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Text('Shorten Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
        if (_lastLink != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'URL Shortened Successfully!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                QrImageView(
                  data: _lastLink!.shortUrl,
                  version: QrVersions.auto,
                  size: 160.0,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 16),
                SelectableText(
                  _lastLink!.shortUrl,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _lastLink!.shortUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                         if (await canLaunchUrlString(_lastLink!.shortUrl)) {
                            await launchUrlString(_lastLink!.shortUrl, mode: LaunchMode.externalApplication);
                         }
                      },
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
