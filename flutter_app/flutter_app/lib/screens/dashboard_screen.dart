import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/services.dart';
import '../notifiers/link_notifier.dart';
import '../widgets/shorten_form.dart';
import '../widgets/glass_container.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final linksAsync = ref.watch(linksProvider);

    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFF080911)),
          // Glowing Background Blur
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.08),
                    blurRadius: 180,
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Column(
                children: [
                  // App Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Analytical Dashboard',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Color(0xFF06B6D4)),
                          onPressed: () => ref.read(linksProvider.notifier).fetchLinks(),
                          splashRadius: 24,
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ShortenForm(),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Divider(color: Colors.white10),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: linksAsync.when(
                        data: (links) => links.isEmpty
                            ? Center(
                                child: Text(
                                  'No historical data located.',
                                  style: TextStyle(color: Colors.white.withOpacity(0.4)),
                                ),
                              )
                            : ListView.builder(
                                itemCount: links.length,
                                itemBuilder: (context, index) {
                                  final link = links[index];
                                  return GlassContainer(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(4),
                                    child: ListTile(
                                      title: Text(
                                        link.title ?? link.shortUrl,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      subtitle: Text(
                                        link.originalUrl,
                                        style: TextStyle(color: Colors.white.withOpacity(0.45)),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.copy, color: Color(0xFF06B6D4)),
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: link.shortUrl));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('URL copied to clipboard.')),
                                              );
                                            },
                                            splashRadius: 20,
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.open_in_new, color: Color(0xFF8B5CF6)),
                                            onPressed: () async {
                                              if (await canLaunchUrlString(link.shortUrl)) {
                                                await launchUrlString(link.shortUrl, mode: LaunchMode.externalApplication);
                                              }
                                            },
                                            splashRadius: 20,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6))),
                        error: (err, stack) => Center(
                          child: Text(
                            'System Error: $err',
                            style: const TextStyle(color: Colors.redAccent),
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
}
