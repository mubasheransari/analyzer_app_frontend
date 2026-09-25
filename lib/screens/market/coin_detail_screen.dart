import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/coin.dart';
import '../../providers/watchlist_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CoinDetailScreen extends StatefulWidget {
  final String coinId;
  const CoinDetailScreen({super.key, required this.coinId});

  @override
  State<CoinDetailScreen> createState() => _CoinDetailScreenState();
}

class _CoinDetailScreenState extends State<CoinDetailScreen> {
  late final ApiService _api;
  late Future<CoinDetail> _future;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    _future = _api.getCoinDetail(widget.coinId);
  }

  String _fmt(double? v) {
    if (v == null) return '--';
    if (v >= 1e12) return '\$${(v / 1e12).toStringAsFixed(2)}T';
    if (v >= 1e9) return '\$${(v / 1e9).toStringAsFixed(2)}B';
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(2)}M';
    if (v >= 1) return '\$${v.toStringAsFixed(2)}';
    return '\$${v.toStringAsFixed(6)}';
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    final watchlist = context.watch<WatchlistProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<CoinDetail>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.brandEnd));
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Failed to load: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.textMuted)),
              );
            }
            final coin = snapshot.data!;
            final change = coin.priceChangePercentage24h;
            final changeColor = AppColors.priceColor(change);
            final watched = watchlist.isWatched(coin.id);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () async {
                          try {
                            await watchlist.toggle(coin.id, coin.symbol);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Log in to use your watchlist')),
                              );
                            }
                          }
                        },
                        icon: Icon(
                          watched ? Icons.star_rounded : Icons.star_border_rounded,
                          color: watched ? AppColors.warning : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      ClipOval(
                        child: coin.image != null
                            ? CachedNetworkImage(imageUrl: coin.image!, width: 48, height: 48)
                            : Container(width: 48, height: 48, color: AppColors.surfaceElevated),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(coin.name,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                          Text(coin.symbol,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(_fmt(coin.currentPrice),
                      style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        (change ?? 0) >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: changeColor,
                      ),
                      Text(
                        change != null ? '${change.toStringAsFixed(2)}% (24h)' : '--',
                        style: TextStyle(color: changeColor, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 2.4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    children: [
                      _StatCard(label: 'Market Cap', value: _fmt(coin.marketCap)),
                      _StatCard(
                        label: '7d Change',
                        value: coin.priceChangePercentage7d != null
                            ? '${coin.priceChangePercentage7d!.toStringAsFixed(2)}%'
                            : '--',
                        valueColor: AppColors.priceColor(coin.priceChangePercentage7d),
                      ),
                      _StatCard(label: 'All-Time High', value: _fmt(coin.ath)),
                      _StatCard(label: 'All-Time Low', value: _fmt(coin.atl)),
                    ],
                  ),
                  if (coin.description != null && coin.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 28),
                    const Text('About',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      _stripHtml(coin.description!).split('\n').first,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _StatCard({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
