import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/link_model.dart';
import '../notifiers/link_notifier.dart';
import '../notifiers/history_notifier.dart';
import 'glass_container.dart';

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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFE5C180), Color(0xFF9E7E45)],
              ).createShader(bounds),
              child: const Text(
                'Shortened URL History',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          GlassContainer(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            borderColor: Colors.white.withOpacity(0.08),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 32,
                    color: const Color(0xFFC5A059).withOpacity(0.25),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No links shortened in this session.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your shortened links and performance statistics will appear here.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFFE5C180), Color(0xFF9E7E45)],
                ).createShader(bounds),
                child: const Text(
                  'Shortened URL History',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => ref.read(historyProvider.notifier).clearHistory(),
                icon: const Icon(Icons.delete_outline, size: 16),
                label: const Text('Clear History'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent.shade100,
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final link = history[index];
            return GlassContainer(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(4),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: link.faviconUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            link.faviconUrl!,
                            errorBuilder: (c, e, s) => const Icon(Icons.link, color: Color(0xFFC5A059)),
                          ),
                        )
                      : const Icon(Icons.link, color: Color(0xFFC5A059)),
                ),
                title: Text(
                  link.title ?? link.shortUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (link.title != null) ...[
                      const SizedBox(height: 4),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFFE5C180), Color(0xFF9E7E45)],
                        ).createShader(bounds),
                        child: Text(
                          link.shortUrl,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                    if (link.description != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        link.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      'Original: ${link.originalUrl}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.bar_chart, color: Color(0xFFC5A059)),
                      onPressed: () => _showStatsDialog(context, link),
                      tooltip: 'Analytics',
                      splashRadius: 24,
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code, color: Color(0xFF8C6D31)),
                      onPressed: () => _showQrDialog(context, link),
                      tooltip: 'QR Code',
                      splashRadius: 24,
                    ),
                    IconButton(
                      icon: Icon(Icons.content_copy, color: Colors.white.withOpacity(0.4)),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link.shortUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied URL to clipboard.')),
                        );
                      },
                      tooltip: 'Copy Link',
                      splashRadius: 24,
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 350.ms, delay: (index * 40).ms).slideY(begin: 0.08, end: 0);
          },
        ),
      ],
    );
  }

  void _showStatsDialog(BuildContext context, LinkModel link) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          child: GlassContainer(
            borderColor: Colors.white.withOpacity(0.1),
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
                      child: const Icon(Icons.bar_chart, color: Color(0xFFC5A059), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Analytics',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FutureBuilder<Map<String, dynamic>>(
                  future: ref.read(linksProvider.notifier).getStats(link.shortCode),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 140,
                        child: Center(child: CircularProgressIndicator(color: Color(0xFFC5A059))),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32.0),
                          child: Text(
                            'Analytics data unavailable.',
                            style: TextStyle(color: Colors.redAccent, fontStyle: FontStyle.italic),
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
                          'Total Clicks',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFE5C180), Color(0xFF9E7E45)],
                          ).createShader(bounds),
                          child: Text(
                            '$totalClicks',
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Device Breakdown',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 14),
                        if (distribution.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text(
                              'No device data recorded yet.',
                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white.withOpacity(0.45)),
                            ),
                          ),
                        ...distribution.map((item) {
                          final type = item['device_type'] as String? ?? "Other";
                          final count = item['count'] as int? ?? 0;
                          final percentage = totalClicks > 0 ? count / totalClicks : 0.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(type, style: const TextStyle(fontSize: 14, color: Colors.white)),
                                    Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: percentage.toDouble(),
                                    backgroundColor: Colors.white.withOpacity(0.04),
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
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white60,
                      ),
                      child: const Text('Close'),
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

  Color _getDeviceColor(String type) {
    switch (type.toLowerCase()) {
      case 'pc': return const Color(0xFFC5A059);
      case 'mobile': return const Color(0xFF8C6D31);
      case 'tablet': return const Color(0xFF5D4037);
      default: return Colors.grey;
    }
  }

  void _showQrDialog(BuildContext context, LinkModel link) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          child: GlassContainer(
            borderColor: Colors.white.withOpacity(0.1),
            fillColor: const Color(0xFF131218).withOpacity(0.96),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC5A059).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.qr_code, color: Color(0xFFC5A059), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'QR Code',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: link.shortUrl,
                    version: QrVersions.auto,
                    size: 180.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFE5C180), Color(0xFF9E7E45)],
                  ).createShader(bounds),
                  child: SelectableText(
                    link.shortUrl,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
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
                      child: const Text('Close'),
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
}
