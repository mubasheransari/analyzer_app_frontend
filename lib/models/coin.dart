class Coin {
  final String id;
  final String symbol;
  final String name;
  final String? image;
  final double? currentPrice;
  final double? marketCap;
  final int? marketCapRank;
  final double? priceChangePercentage24h;
  final double? totalVolume;
  final List<double>? sparkline7d;

  Coin({
    required this.id,
    required this.symbol,
    required this.name,
    this.image,
    this.currentPrice,
    this.marketCap,
    this.marketCapRank,
    this.priceChangePercentage24h,
    this.totalVolume,
    this.sparkline7d,
  });

  factory Coin.fromJson(Map<String, dynamic> json) {
    List<double>? sparkline;
    final sparklineData = json['sparkline_in_7d'];
    if (sparklineData != null && sparklineData['price'] != null) {
      sparkline = (sparklineData['price'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }

    return Coin(
      id: json['id'] as String,
      symbol: (json['symbol'] as String).toUpperCase(),
      name: json['name'] as String,
      image: json['image'] as String?,
      currentPrice: (json['current_price'] as num?)?.toDouble(),
      marketCap: (json['market_cap'] as num?)?.toDouble(),
      marketCapRank: json['market_cap_rank'] as int?,
      priceChangePercentage24h:
          (json['price_change_percentage_24h'] as num?)?.toDouble(),
      totalVolume: (json['total_volume'] as num?)?.toDouble(),
      sparkline7d: sparkline,
    );
  }

  /// Volume-to-market-cap ratio: what fraction of a coin's total value
  /// changed hands in the last 24h. A standard, honest measure of *current*
  /// trading interest - describes what's happening right now, not a
  /// prediction of what will happen next. Returns null if either figure
  /// is unavailable.
  double? get volumeToMarketCapRatio {
    if (totalVolume == null || marketCap == null || marketCap == 0) return null;
    return totalVolume! / marketCap!;
  }

  /// A plain-language activity read based only on live data: how much of
  /// the coin traded today, and how far the price moved. "High" means
  /// unusually active *right now* - it is not, and should never be
  /// presented as, a signal about future price direction.
  ActivityLevel get activityLevel {
    final ratio = volumeToMarketCapRatio;
    final change = priceChangePercentage24h?.abs() ?? 0;

    if ((ratio != null && ratio > 0.5) || change > 20) return ActivityLevel.high;
    if ((ratio != null && ratio > 0.15) || change > 8) return ActivityLevel.elevated;
    return ActivityLevel.normal;
  }
}

enum ActivityLevel { normal, elevated, high }

class GlobalMarketData {
  final double? totalMarketCapUsd;
  final double? totalVolumeUsd;
  final double? marketCapChangePercentage24h;
  final double? btcDominance;
  final double? ethDominance;
  final int? activeCryptocurrencies;

  GlobalMarketData({
    this.totalMarketCapUsd,
    this.totalVolumeUsd,
    this.marketCapChangePercentage24h,
    this.btcDominance,
    this.ethDominance,
    this.activeCryptocurrencies,
  });

  factory GlobalMarketData.fromJson(Map<String, dynamic> json) {
    return GlobalMarketData(
      totalMarketCapUsd: (json['total_market_cap_usd'] as num?)?.toDouble(),
      totalVolumeUsd: (json['total_volume_usd'] as num?)?.toDouble(),
      marketCapChangePercentage24h:
          (json['market_cap_change_percentage_24h'] as num?)?.toDouble(),
      btcDominance: (json['btc_dominance'] as num?)?.toDouble(),
      ethDominance: (json['eth_dominance'] as num?)?.toDouble(),
      activeCryptocurrencies: json['active_cryptocurrencies'] as int?,
    );
  }
}

class CoinDetail {
  final String id;
  final String symbol;
  final String name;
  final String? image;
  final String? description;
  final double? currentPrice;
  final double? marketCap;
  final double? priceChangePercentage24h;
  final double? priceChangePercentage7d;
  final double? ath;
  final double? atl;
  final String? homepage;

  CoinDetail({
    required this.id,
    required this.symbol,
    required this.name,
    this.image,
    this.description,
    this.currentPrice,
    this.marketCap,
    this.priceChangePercentage24h,
    this.priceChangePercentage7d,
    this.ath,
    this.atl,
    this.homepage,
  });

  factory CoinDetail.fromJson(Map<String, dynamic> json) {
    return CoinDetail(
      id: json['id'] as String,
      symbol: (json['symbol'] as String).toUpperCase(),
      name: json['name'] as String,
      image: json['image'] as String?,
      description: json['description'] as String?,
      currentPrice: (json['current_price'] as num?)?.toDouble(),
      marketCap: (json['market_cap'] as num?)?.toDouble(),
      priceChangePercentage24h:
          (json['price_change_percentage_24h'] as num?)?.toDouble(),
      priceChangePercentage7d:
          (json['price_change_percentage_7d'] as num?)?.toDouble(),
      ath: (json['ath'] as num?)?.toDouble(),
      atl: (json['atl'] as num?)?.toDouble(),
      homepage: json['homepage'] as String?,
    );
  }
}
