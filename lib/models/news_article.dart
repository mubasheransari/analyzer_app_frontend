class NewsArticle {
  final String id;
  final String title;
  final String? body;
  final String url;
  final String? source;
  final String? imageUrl;
  final DateTime? publishedAt;
  final String? tags;

  NewsArticle({
    required this.id,
    required this.title,
    this.body,
    required this.url,
    this.source,
    this.imageUrl,
    this.publishedAt,
    this.tags,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      id: json['id'].toString(),
      title: json['title'] as String,
      body: json['body'] as String?,
      url: json['url'] as String,
      source: json['source'] as String?,
      imageUrl: json['image_url'] as String?,
      publishedAt: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      tags: json['tags'] as String?,
    );
  }
}
