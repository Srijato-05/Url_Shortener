import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../notifiers/link_notifier.dart';

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
  String? _lastShortenedUrl;

  @override
  void dispose() {
    _urlController.dispose();
    _aliasController.dispose();
    super.dispose();
  }

  Future<void> _handleShorten() async {
    if (_urlController.text.isEmpty) return;

    setState(() {
      _isShortening = true;
      _lastShortenedUrl = null;
    });
    try {
      final newLink = await ref.read(linksProvider.notifier).shortenUrl(
        _urlController.text,
        customAlias: _aliasController.text.isEmpty ? null : _aliasController.text,
        expiry: _selectedDate,
      );
      
      if (mounted) {
        setState(() {
          _lastShortenedUrl = newLink.shortUrl;
        });
        _urlController.clear();
        _aliasController.clear();
        setState(() => _selectedDate = null);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL shortened successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isShortening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                        if (date != null) setState(() => _selectedDate = date);
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
        if (_lastShortenedUrl != null) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                const Text(
                  'Your Shortened URL:',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  _lastShortenedUrl!,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _lastShortenedUrl!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard!')),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () async {
                         if (await canLaunchUrlString(_lastShortenedUrl!)) {
                            await launchUrlString(_lastShortenedUrl!, mode: LaunchMode.externalApplication);
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
