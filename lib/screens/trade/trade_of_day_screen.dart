import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/trade_of_day.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../chat/chat_screen.dart';

class TradeOfDayScreen extends StatefulWidget {
  const TradeOfDayScreen({super.key});

  @override
  State<TradeOfDayScreen> createState() => _TradeOfDayScreenState();
}

class _TradeOfDayScreenState extends State<TradeOfDayScreen> {
  late final ApiService _api;
  late Future<TradeOfDay?> _future;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    _future = _api.getLatestTradeOfDay();
  }

  Future<void> _refresh() async {
    setState(() => _future = _api.getLatestTradeOfDay());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _ChatFab(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        ),
      ),
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
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppColors.gradientBrand.createShader(bounds),
                        child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Trade of the Day',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              FutureBuilder<TradeOfDay?>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(
                            child: CircularProgressIndicator(color: AppColors.brandEnd)),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: _ErrorOrEmptyState(
                        icon: Icons.cloud_off_rounded,
                        message: 'Could not load Trade of the Day',
                        detail: snapshot.error.toString(),
                      ),
                    );
                  }
                  final trade = snapshot.data;
                  if (trade == null) {
                    return const SliverToBoxAdapter(
                      child: _ErrorOrEmptyState(
                        icon: Icons.bolt_outlined,
                        message: 'No Trade of the Day yet',
                        detail: 'Check back soon — new picks are posted regularly.',
                      ),
                    );
                  }
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: _TradeCard(trade: trade, api: _api),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TradeCard extends StatelessWidget {
  final TradeOfDay trade;
  final ApiService api;

  const _TradeCard({required this.trade, required this.api});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Image.network(
              api.resolveImageUrl(trade.imageUrl),
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: AppColors.surfaceElevated,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.brandEnd),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.surfaceElevated,
                child: const Center(
                  child: Icon(Icons.image_not_supported_outlined,
                      color: AppColors.textMuted, size: 40),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientBrand,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormat('MMM d, yyyy · h:mm a').format(trade.tradeDatetime),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  trade.title,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                Text(
                  trade.description,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.warning.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Educational content only — not financial advice.',
                          style: TextStyle(color: AppColors.warning.withOpacity(0.9), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatFab extends StatelessWidget {
  final VoidCallback onTap;

  const _ChatFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.gradientBrand,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.brandStart.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_outlined, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Ask AI',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorOrEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String detail;

  const _ErrorOrEmptyState({
    required this.icon,
    required this.message,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 80),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.textMuted),
          const SizedBox(height: 14),
          Text(message,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
