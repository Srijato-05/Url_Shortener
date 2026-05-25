import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/link_model.dart';
import '../providers/api_provider.dart';

class LinkNotifier extends StateNotifier<AsyncValue<List<LinkModel>>> {
  final Ref ref;

  LinkNotifier(this.ref) : super(const AsyncValue.data([]));

  Future<void> fetchLinks() async {
    // No-op: Auth-protected analytics removed
    state = const AsyncValue.data([]);
  }

  Future<LinkModel> shortenUrl(String url, {String? customAlias, DateTime? expiry}) async {
    try {
      final client = ref.read(apiProvider);
      final response = await client.dio.post('/shorten', data: {
        'original_url': url,
        if (customAlias != null && customAlias.isNotEmpty) 'custom_alias': customAlias,
        if (expiry != null) 'expiry_time': expiry.toUtc().toIso8601String(),
      });
      final newLink = LinkModel.fromJson(response.data);
      return newLink;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getStats(String shortCode) async {
    return await ref.read(apiProvider).fetchStats(shortCode);
  }
}

final linksProvider = StateNotifierProvider<LinkNotifier, AsyncValue<List<LinkModel>>>((ref) {
  return LinkNotifier(ref);
});
