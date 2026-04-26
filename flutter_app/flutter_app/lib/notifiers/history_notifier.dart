import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/link_model.dart';

final historyProvider = StateNotifierProvider<HistoryNotifier, List<LinkModel>>((ref) {
  return HistoryNotifier();
});

class HistoryNotifier extends StateNotifier<List<LinkModel>> {
  HistoryNotifier() : super([]) {
    _loadHistory();
  }

  static const _historyKey = 'shortened_links_history';

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getStringList(_historyKey);
    if (historyJson != null) {
      state = historyJson
          .map((data) => LinkModel.fromJson(jsonDecode(data)))
          .toList()
          .reversed
          .toList(); // Newest first
    }
  }

  Future<void> addLink(LinkModel link) async {
    final prefs = await SharedPreferences.getInstance();
    final List<LinkModel> updatedHistory = [link, ...state.where((l) => l.shortCode != link.shortCode)];
    
    // Limit history to 50 items for performance
    if (updatedHistory.length > 50) {
      updatedHistory.removeLast();
    }

    state = updatedHistory;
    
    final historyJson = state.map((l) => jsonEncode(l.toJson())).toList();
    await prefs.setStringList(_historyKey, historyJson);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    state = [];
  }
}
