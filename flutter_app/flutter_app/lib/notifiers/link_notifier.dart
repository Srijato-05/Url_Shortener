import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/link_model.dart';
import '../providers/api_provider.dart';

class LinkNotifier extends StateNotifier<AsyncValue<List<LinkModel>>> {
  final Ref ref;

  LinkNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchLinks();
  }

  Future<void> fetchLinks() async {
    state = const AsyncValue.loading();
    try {
      final client = ref.read(apiProvider);
      final response = await client.dio.get('/analytics'); // Assuming we want user's links
      final List data = response.data;
      state = AsyncValue.data(data.map((e) => LinkModel.fromJson(e)).toList());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<LinkModel> shortenUrl(String url, {String? customAlias, DateTime? expiry}) async {
    try {
      final client = ref.read(apiProvider);
      final response = await client.dio.post('/shorten', data: {
        'original_url': url,
        if (customAlias != null && customAlias.isNotEmpty) 'custom_alias': customAlias,
        if (expiry != null) 'expiry_time': expiry.toIso8601String(),
      });
      final newLink = LinkModel.fromJson(response.data);
      await fetchLinks();
      return newLink;
    } catch (e) {
      rethrow;
    }
  }
}

final linksProvider = StateNotifierProvider<LinkNotifier, AsyncValue<List<LinkModel>>>((ref) {
  return LinkNotifier(ref);
});
