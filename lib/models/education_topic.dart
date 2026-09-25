class EducationTopic {
  final String slug;
  final String title;
  final String category;
  final String summary;
  final String? content;

  EducationTopic({
    required this.slug,
    required this.title,
    required this.category,
    required this.summary,
    this.content,
  });

  factory EducationTopic.fromJson(Map<String, dynamic> json) {
    return EducationTopic(
      slug: json['slug'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      summary: json['summary'] as String,
      content: json['content'] as String?,
    );
  }
}

/// The structured result from the chart analyzer. `currentPrice` is a
/// plain readout of what the chart shows; `entryPrice` is meant to reflect
/// real technical reasoning rather than just repeating currentPrice.
/// `riskLevel` is the honest, qualitative "is this safe to trade right now"
/// read (Low/Medium/High + a real reason) - deliberately never a numeric
/// success-probability or a binary safe/unsafe verdict, since no model can
/// honestly compute either from a chart screenshot.
class ChartAnalysisResult {
  final int id;
  final String? coinHint;
  final String trend;
  final String keyPattern;
  final String currentPrice;
  final String entryPrice;
  final String stopLoss;
  final String targetPrice;
  final String invalidationLevel;
  final String indicators;
  final String bullishScenario;
  final String bearishScenario;
  final String setupClarity;
  final String riskLevel;
  final String volatilityRead;
  final String disclaimer;
  final DateTime createdAt;

  ChartAnalysisResult({
    required this.id,
    this.coinHint,
    required this.trend,
    required this.keyPattern,
    required this.currentPrice,
    required this.entryPrice,
    required this.stopLoss,
    required this.targetPrice,
    required this.invalidationLevel,
    required this.indicators,
    required this.bullishScenario,
    required this.bearishScenario,
    required this.setupClarity,
    required this.riskLevel,
    required this.volatilityRead,
    required this.disclaimer,
    required this.createdAt,
  });

  factory ChartAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ChartAnalysisResult(
      id: json['id'] as int,
      coinHint: json['coin_hint'] as String?,
      trend: json['trend'] as String,
      keyPattern: json['key_pattern'] as String,
      currentPrice: json['current_price'] as String,
      entryPrice: json['entry_price'] as String,
      stopLoss: json['stop_loss'] as String,
      targetPrice: json['target_price'] as String,
      invalidationLevel: json['invalidation_level'] as String,
      indicators: json['indicators'] as String,
      bullishScenario: json['bullish_scenario'] as String,
      bearishScenario: json['bearish_scenario'] as String,
      setupClarity: json['setup_clarity'] as String,
      riskLevel: json['risk_level'] as String,
      volatilityRead: json['volatility_read'] as String,
      disclaimer: json['disclaimer'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
