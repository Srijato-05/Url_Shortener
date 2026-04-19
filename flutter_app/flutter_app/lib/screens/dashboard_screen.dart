import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:flutter/services.dart';
import '../notifiers/link_notifier.dart';
import '../widgets/shorten_form.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linksAsync = ref.watch(linksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(linksProvider.notifier).fetchLinks(),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: ShortenForm(),
          ),
          const Divider(),
          Expanded(
            child: linksAsync.when(
              data: (links) => links.isEmpty
                  ? const Center(child: Text('No links shortened yet.'))
                  : ListView.builder(
                      itemCount: links.length,
                      itemBuilder: (context, index) {
                        final link = links[index];
                        return ListTile(
                          title: Text(link.title ?? link.shortUrl),
                          subtitle: Text(link.originalUrl),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.copy),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: link.shortUrl));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('URL copied to clipboard')),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () async {
                                  if (await canLaunchUrlString(link.shortUrl)) {
                                    await launchUrlString(link.shortUrl, mode: LaunchMode.externalApplication);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
