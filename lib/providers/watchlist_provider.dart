import 'package:flutter/foundation.dart';

import '../services/api_service.dart';

class WatchlistProvider extends ChangeNotifier {
  final ApiService api;
  final Set<String> _coinIds = {};
  bool _loaded = false;

  WatchlistProvider(this.api);

  bool isWatched(String coinId) => _coinIds.contains(coinId);

  Future<void> load() async {
    try {
      final items = await api.getWatchlist();
      _coinIds
        ..clear()
        ..addAll(items.map((e) => e['coin_id'] as String));
      _loaded = true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggle(String coinId, String symbol) async {
    if (_coinIds.contains(coinId)) {
      await api.removeFromWatchlist(coinId);
      _coinIds.remove(coinId);
    } else {
      await api.addToWatchlist(coinId, symbol);
      _coinIds.add(coinId);
    }
    notifyListeners();
  }

  void clear() {
    _coinIds.clear();
    _loaded = false;
    notifyListeners();
  }

  bool get isLoaded => _loaded;
}
