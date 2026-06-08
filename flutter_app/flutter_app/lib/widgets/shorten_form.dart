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
import 'glass_container.dart';

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
        const SnackBar(content: Text('Please enter a valid destination URL.')),
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
        await ref.read(historyProvider.notifier).addLink(newLink);
        
        setState(() {
          _lastLink = newLink;
        });
        _urlController.clear();
        _aliasController.clear();
        setState(() => _selectedDate = null);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL shortened successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        String msg = 'An unexpected error occurred. Please try again.';
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('400')) {
          msg = 'This custom alias is already taken.';
        } else if (errStr.contains('410')) {
          msg = 'The link has expired.';
        } else if (errStr.contains('connection')) {
          msg = 'Could not connect to the server.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isShortening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocalhost = html.window.location.hostname == 'localhost' || html.window.location.hostname == '127.0.0.1';

    return Column(
      children: [
        if (isLocalhost)
          GlassContainer(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            borderColor: const Color(0xFFC5A059).withOpacity(0.25),
            fillColor: const Color(0xFFC5A059).withOpacity(0.02),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFC5A059), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'To test mobile redirection on the same Wi-Fi, open this page using your local network IP (configured in start.ps1) instead of localhost.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        GlassContainer(
          padding: const EdgeInsets.all(28.0),
          borderColor: Colors.white.withOpacity(0.09),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _urlController,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                cursorColor: const Color(0xFFC5A059),
                decoration: InputDecoration(
                  labelText: 'Destination URL',
                  hintText: 'https://example.com/long-link-to-shorten',
                  prefixIcon: const Icon(Icons.link, color: Colors.white54),
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFC5A059)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _aliasController,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      cursorColor: const Color(0xFFC5A059),
                      decoration: InputDecoration(
                        labelText: 'Custom Alias (Optional)',
                        prefixIcon: const Icon(Icons.alternate_email, color: Colors.white54),
                        labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFC5A059)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFFC5A059),
                                onPrimary: Colors.black,
                                surface: Color(0xFF131218),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
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
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.white54, size: 18),
                          const SizedBox(width: 10),
                          Text(
                            _selectedDate == null 
                              ? 'No Expiry' 
                              : DateFormat.yMd().format(_selectedDate!),
                            style: TextStyle(
                              color: _selectedDate == null 
                                ? Colors.white.withOpacity(0.5) 
                                : Colors.white,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE5C180), Color(0xFF9E7E45)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE5C180).withOpacity(0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isShortening ? null : _handleShorten,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isShortening 
                    ? const SizedBox(
                        height: 20, 
                        width: 20, 
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)
                      ) 
                    : const Text(
                        'Shorten URL', 
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black, letterSpacing: 0.2)
                      ),
                ),
              ),
            ],
          ),
        ),
        if (_lastLink != null) ...[
          const SizedBox(height: 24),
          GlassContainer(
            borderColor: const Color(0xFFC5A059).withOpacity(0.35),
            glowColor: const Color(0xFFC5A059),
            glowRadius: 16,
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFE5C180), Color(0xFF9E7E45)],
                  ).createShader(bounds),
                  child: const Text(
                    'URL Shortened Successfully',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: _lastLink!.shortUrl,
                    version: QrVersions.auto,
                    size: 140.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFE5C180), Color(0xFF9E7E45)],
                  ).createShader(bounds),
                  child: Text(
                    _lastLink!.shortUrl,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE5C180), Color(0xFF9E7E45)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE5C180).withOpacity(0.15),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _lastLink!.shortUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Copied URL to clipboard.')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16, color: Colors.black),
                        label: const Text('Copy URL', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                         if (await canLaunchUrlString(_lastLink!.shortUrl)) {
                            await launchUrlString(_lastLink!.shortUrl, mode: LaunchMode.externalApplication);
                         }
                      },
                      icon: const Icon(Icons.open_in_new, size: 16, color: Color(0xFFC5A059)),
                      label: const Text('Open Link', style: TextStyle(color: Color(0xFFC5A059), fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFC5A059)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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
