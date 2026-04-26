import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/link_model.dart';
import '../notifiers/link_notifier.dart';
import '../notifiers/history_notifier.dart';

class HistoryList extends ConsumerStatefulWidget {
  const HistoryList({super.key});

  @override
  ConsumerState<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends ConsumerState<HistoryList> {
  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);

    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ACTIVITY LOG',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.blueGrey[400],
                    ),
              ),
              TextButton.icon(
                onPressed: () => ref.read(historyProvider.notifier).clearHistory(),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('PURGE HISTORY'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final link = history[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: Colors.blueGrey.withOpacity(0.1)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                title: Text(
                  link.shortUrl,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.indigo,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      link.originalUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.blueGrey[400], fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'TIMESTAMP: ${DateFormat('yyyy-MM-dd HH:mm').format(link.createdAt)}',
                      style: TextStyle(color: Colors.blueGrey[300], fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.query_stats, color: Colors.blueAccent),
                      onPressed: () => _showStatsDialog(context, link),
                      tooltip: 'Analytical Data',
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code, color: Colors.blueGrey),
                      onPressed: () => _showQrDialog(context, link),
                      tooltip: 'Generate QR',
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_copy, color: Colors.blueGrey),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link.shortUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Abbreviated URL copied to clipboard.')),
                        );
                      },
                      tooltip: 'Copy to Clipboard',
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: (index * 50).ms).slideY(begin: 0.1, end: 0);
          },
        ),
      ],
    );
  }

  void _showStatsDialog(BuildContext context, LinkModel link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.analytics_outlined, color: Colors.blueAccent),
            const SizedBox(width: 12),
            const Text('Link Analytics'),
          ],
        ),
        content: FutureBuilder<Map<String, dynamic>>(
          future: ref.read(linksProvider.notifier).getStats(link.shortCode),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Engagement data currently unavailable.',
                    style: TextStyle(color: Colors.red[300], fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final stats = snapshot.data!;
            final totalClicks = stats['total_clicks'] as int? ?? 0;
            final distribution = (stats['device_distribution'] as List?) ?? [];

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Engagement',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalClicks Clicks',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Device Distribution',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (distribution.isEmpty)
                  const Text('No click data available yet.', style: TextStyle(fontStyle: FontStyle.italic)),
                ...distribution.map((item) {
                  final type = item['device_type'] as String? ?? "Other";
                  final count = item['count'] as int? ?? 0;
                  final percentage = totalClicks > 0 ? count / totalClicks : 0.0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(type, style: const TextStyle(fontSize: 13)),
                            Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage.toDouble(),
                            backgroundColor: Colors.grey[200],
                            color: _getDeviceColor(type),
                            minHeight: 8,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Color _getDeviceColor(String type) {
    switch (type.toLowerCase()) {
      case 'pc': return Colors.blue;
      case 'mobile': return Colors.green;
      case 'tablet': return Colors.orange;
      case 'bot': return Colors.redAccent;
      default: return Colors.blueGrey;
    }
  }

  void _showQrDialog(BuildContext context, LinkModel link) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 200,
              height: 200,
              child: QrImageView(
                data: link.shortUrl,
                version: QrVersions.auto,
                size: 200.0,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              link.shortUrl,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
