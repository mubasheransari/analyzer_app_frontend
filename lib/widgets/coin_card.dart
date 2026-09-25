import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/coin.dart';
import '../theme/app_theme.dart';

class CoinCard extends StatelessWidget {
  final Coin coin;
  final VoidCallback? onTap;

  const CoinCard({super.key, required this.coin, this.onTap});

  String _formatPrice(double? price) {
    if (price == null) return '--';
    if (price >= 1) return '\$${price.toStringAsFixed(2)}';
    return '\$${price.toStringAsFixed(6)}';
  }

  @override
  Widget build(BuildContext context) {
    final change = coin.priceChangePercentage24h;
    final positive = (change ?? 0) >= 0;
    final changeColor = AppColors.priceColor(change);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                coin.marketCapRank?.toString() ?? '',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
            const SizedBox(width: 8),
            ClipOval(
              child: coin.image != null
                  ? CachedNetworkImage(
                      imageUrl: coin.image!,
                      width: 36,
                      height: 36,
                      errorWidget: (_, __, ___) => _fallbackIcon(),
                    )
                  : _fallbackIcon(),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coin.symbol,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    coin.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (coin.sparkline7d != null && coin.sparkline7d!.length > 2)
              SizedBox(
                width: 52,
                height: 32,
                child: _Sparkline(data: coin.sparkline7d!, color: changeColor),
              ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPrice(coin.currentPrice),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        positive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: changeColor,
                        size: 16,
                      ),
                      Text(
                        change != null ? '${change.abs().toStringAsFixed(2)}%' : '--',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: changeColor, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (coin.activityLevel != ActivityLevel.normal) ...[
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: _ActivityBadge(level: coin.activityLevel),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        gradient: AppColors.gradientBrand,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        coin.symbol.isNotEmpty ? coin.symbol[0] : '?',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// Shows "Elevated" or "High" activity based purely on today's live
/// volume-to-market-cap ratio and price move size - describes current
/// trading activity, never a prediction of future direction.
class _ActivityBadge extends StatelessWidget {
  final ActivityLevel level;

  const _ActivityBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    final isHigh = level == ActivityLevel.high;
    final color = isHigh ? AppColors.warning : AppColors.brandEnd;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt_rounded, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            isHigh ? 'High activity' : 'Elevated',
            style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> data;
  final Color color;

  const _Sparkline({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (int i = 0; i < data.length; i++) FlSpot(i.toDouble(), data[i]),
    ];

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 1.6,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }
}
