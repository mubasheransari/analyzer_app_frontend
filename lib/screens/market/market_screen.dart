import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/coin.dart';
import '../../providers/watchlist_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/coin_card.dart';
import '../../widgets/section_header.dart';
import 'coin_detail_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

enum _ViewMode { marketCap, gainers, watchlist }

class _MarketScreenState extends State<MarketScreen> {
  late final ApiService _api;
  late Future<List<Coin>> _coinsFuture;
  late Future<GlobalMarketData> _globalFuture;
  final _searchController = TextEditingController();
  String _query = '';
  _ViewMode _viewMode = _ViewMode.marketCap;
  bool _sortByActivity = false;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    _coinsFuture = _api.getCoins(perPage: 100);
    _globalFuture = _api.getGlobalMarketData();
  }

  Future<void> _refresh() async {
    setState(() {
      _coinsFuture = _api.getCoins(perPage: 100);
      _globalFuture = _api.getGlobalMarketData();
    });
    await _coinsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final watchlist = context.watch<WatchlistProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.brandEnd,
          backgroundColor: AppColors.surface,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Market',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        onPressed: () => setState(() {
                          _viewMode = _viewMode == _ViewMode.watchlist
                              ? _ViewMode.marketCap
                              : _ViewMode.watchlist;
                        }),
                        icon: Icon(
                          _viewMode == _ViewMode.watchlist
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: _viewMode == _ViewMode.watchlist
                              ? AppColors.warning
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: FutureBuilder<GlobalMarketData>(
                    future: _globalFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const _GlobalCapCardSkeleton();
                      }
                      return _GlobalCapCard(data: snapshot.data!);
                    },
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v.toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search coins...',
                      prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              if (_viewMode != _ViewMode.watchlist)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
                    child: Row(
                      children: [
                        _ModeChip(
                          label: 'Market Cap',
                          selected: _viewMode == _ViewMode.marketCap,
                          onTap: () => setState(() => _viewMode = _ViewMode.marketCap),
                        ),
                        const SizedBox(width: 8),
                        _ModeChip(
                          label: 'Top Gainers',
                          selected: _viewMode == _ViewMode.gainers,
                          onTap: () => setState(() => _viewMode = _ViewMode.gainers),
                        ),
                      ],
                    ),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (_viewMode == _ViewMode.watchlist)
                            Padding(
                              padding: const EdgeInsets.only(right: 6, bottom: 12),
                              child: GestureDetector(
                                onTap: () => setState(() => _viewMode = _ViewMode.marketCap),
                                child: const Icon(Icons.arrow_back_ios_new_rounded,
                                    size: 16, color: AppColors.textSecondary),
                              ),
                            ),
                          SectionHeader(
                            title: switch (_viewMode) {
                              _ViewMode.watchlist => 'Your Watchlist',
                              _ViewMode.gainers => 'Top Gainers (24h)',
                              _ViewMode.marketCap => 'All Coins',
                            },
                          ),
                        ],
                      ),
                      if (_viewMode == _ViewMode.watchlist)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () => setState(() => _sortByActivity = !_sortByActivity),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _sortByActivity
                                    ? AppColors.brandStart.withOpacity(0.15)
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _sortByActivity
                                      ? AppColors.brandStart
                                      : AppColors.cardBorder,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt_rounded,
                                      size: 14,
                                      color: _sortByActivity
                                          ? AppColors.brandEnd
                                          : AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Most Active',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _sortByActivity
                                          ? AppColors.brandEnd
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: FutureBuilder<List<Coin>>(
                  future: _coinsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 60),
                          child: Center(
                              child: CircularProgressIndicator(color: AppColors.brandEnd)),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: _ErrorState(onRetry: _refresh, error: snapshot.error.toString()),
                      );
                    }

                    var coins = snapshot.data ?? [];
                    if (_query.isNotEmpty) {
                      coins = coins
                          .where((c) =>
                              c.name.toLowerCase().contains(_query) ||
                              c.symbol.toLowerCase().contains(_query))
                          .toList();
                    }

                    switch (_viewMode) {
                      case _ViewMode.watchlist:
                        coins = coins.where((c) => watchlist.isWatched(c.id)).toList();
                        if (_sortByActivity) {
                          // Ranks by current volume-to-market-cap ratio,
                          // falling back to 24h price-move size - both are
                          // live-data facts about right now, never a forecast.
                          coins.sort((a, b) {
                            final aScore = (a.volumeToMarketCapRatio ?? 0) +
                                (a.priceChangePercentage24h?.abs() ?? 0) / 100;
                            final bScore = (b.volumeToMarketCapRatio ?? 0) +
                                (b.priceChangePercentage24h?.abs() ?? 0) / 100;
                            return bScore.compareTo(aScore);
                          });
                        }
                        break;
                      case _ViewMode.gainers:
                        // "Gainers" = coins currently up, ranked by how much -
                        // a plain sort of live 24h data, not a prediction.
                        coins = coins
                            .where((c) => (c.priceChangePercentage24h ?? 0) > 0)
                            .toList()
                          ..sort((a, b) => (b.priceChangePercentage24h ?? 0)
                              .compareTo(a.priceChangePercentage24h ?? 0));
                        break;
                      case _ViewMode.marketCap:
                        // Already returned in market-cap-descending order by
                        // the API - no extra sort needed.
                        break;
                    }

                    if (coins.isEmpty) {
                      final emptyMessage = _viewMode == _ViewMode.gainers
                          ? 'No coins currently up in the last 24h'
                          : 'No coins found';
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Center(
                            child: Text(emptyMessage,
                                style: const TextStyle(color: AppColors.textMuted)),
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CoinCard(
                            coin: coins[index],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CoinDetailScreen(coinId: coins[index].id),
                              ),
                            ),
                          ),
                        ),
                        childCount: coins.length,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandStart : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.transparent : AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  final String error;

  const _ErrorState({required this.onRetry, required this.error});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text('Could not load market data', style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

/// Attractive gradient header card showing total crypto market cap, 24h
/// change, and BTC/ETH dominance. Free CoinGecko data via the backend -
/// never touches Gemini, so refreshing this costs nothing extra.
class _GlobalCapCard extends StatelessWidget {
  final GlobalMarketData data;

  const _GlobalCapCard({required this.data});

  String _formatLarge(double? v) {
    if (v == null) return '--';
    if (v >= 1e12) return '\$${(v / 1e12).toStringAsFixed(2)}T';
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(2)}M';
    return '\$${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final change = data.marketCapChangePercentage24h;
    final positive = (change ?? 0) >= 0;

    return GradientContainer(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Total Market Cap',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (change != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        positive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: Colors.white,
                        size: 16,
                      ),
                      Text(
                        '${change.abs().toStringAsFixed(2)}%',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatLarge(data.totalMarketCapUsd),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MiniStat(label: '24h Volume', value: _formatLarge(data.totalVolumeUsd)),
              const SizedBox(width: 20),
              _MiniStat(
                label: 'BTC Dom.',
                value: data.btcDominance != null
                    ? '${data.btcDominance!.toStringAsFixed(1)}%'
                    : '--',
              ),
              const SizedBox(width: 20),
              _MiniStat(
                label: 'ETH Dom.',
                value: data.ethDominance != null
                    ? '${data.ethDominance!.toStringAsFixed(1)}%'
                    : '--',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _GlobalCapCardSkeleton extends StatelessWidget {
  const _GlobalCapCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandEnd),
      ),
    );
  }
}
