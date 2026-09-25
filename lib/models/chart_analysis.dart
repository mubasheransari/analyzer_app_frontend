class ChartAnalysis {
  final int id;
  final int? userId;
  final String? analystName;
  final String? analystEmail;
  final bool isMine;
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

  ChartAnalysis({
    required this.id, required this.userId, required this.analystName,
    required this.analystEmail, required this.isMine, required this.coinHint,
    required this.trend, required this.keyPattern, required this.currentPrice,
    required this.entryPrice, required this.stopLoss, required this.targetPrice,
    required this.invalidationLevel, required this.indicators,
    required this.bullishScenario, required this.bearishScenario,
    required this.setupClarity, required this.riskLevel,
    required this.volatilityRead, required this.disclaimer, required this.createdAt,
  });

  factory ChartAnalysis.fromJson(Map<String, dynamic> j) => ChartAnalysis(
    id: j['id'] as int,
    userId: j['user_id'] as int?,
    analystName: j['analyst_name'] as String?,
    analystEmail: j['analyst_email'] as String?,
    isMine: j['is_mine'] == true,
    coinHint: j['coin_hint'] as String?,
    trend: j['trend'] ?? '',
    keyPattern: j['key_pattern'] ?? '',
    currentPrice: j['current_price'] ?? '',
    entryPrice: j['entry_price'] ?? '',
    stopLoss: j['stop_loss'] ?? '',
    targetPrice: j['target_price'] ?? '',
    invalidationLevel: j['invalidation_level'] ?? '',
    indicators: j['indicators'] ?? '',
    bullishScenario: j['bullish_scenario'] ?? '',
    bearishScenario: j['bearish_scenario'] ?? '',
    setupClarity: j['setup_clarity'] ?? '',
    riskLevel: j['risk_level'] ?? '',
    volatilityRead: j['volatility_read'] ?? '',
    disclaimer: j['disclaimer'] ?? '',
    createdAt: DateTime.parse(j['created_at']),
  );
}
