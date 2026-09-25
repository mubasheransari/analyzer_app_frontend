class TradeOfDay {
  final int id;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime tradeDatetime;
  final DateTime createdAt;

  TradeOfDay({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.tradeDatetime,
    required this.createdAt,
  });

  factory TradeOfDay.fromJson(Map<String, dynamic> json) {
    return TradeOfDay(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['image_url'] as String,
      tradeDatetime: DateTime.parse(json['trade_datetime'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
