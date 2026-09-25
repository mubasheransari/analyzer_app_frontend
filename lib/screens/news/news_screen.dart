import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/news_article.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/news_card.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late final ApiService _api;
  late Future<List<NewsArticle>> _future;
  String? _category;

  final _categories = const [
    {'label': 'All', 'value': null},
    {'label': 'BTC', 'value': 'BTC'},
    {'label': 'ETH', 'value': 'ETH'},
    {'label': 'Trading', 'value': 'Trading'},
    {'label': 'Regulation', 'value': 'Regulation'},
    {'label': 'Mining', 'value': 'Mining'},
  ];

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    _future = _api.getNews();
  }

  void _selectCategory(String? value) {
    setState(() {
      _category = value;
      _future = _api.getNews(category: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('News', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final cat = _categories[i];
                  final selected = _category == cat['value'];
                  return ChoiceChip(
                    label: Text(cat['label'] as String),
                    selected: selected,
                    onSelected: (_) => _selectCategory(cat['value'] as String?),
                    selectedColor: AppColors.brandStart,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    side: BorderSide(color: selected ? Colors.transparent : AppColors.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: RefreshIndicator(
                color: AppColors.brandEnd,
                backgroundColor: AppColors.surface,
                onRefresh: () async {
                  setState(() => _future = _api.getNews(category: _category));
                  await _future;
                },
                child: FutureBuilder<List<NewsArticle>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator(color: AppColors.brandEnd));
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Could not load news',
                            style: const TextStyle(color: AppColors.textMuted)),
                      );
                    }
                    final articles = snapshot.data ?? [];
                    if (articles.isEmpty) {
                      return const Center(
                          child: Text('No articles found',
                              style: TextStyle(color: AppColors.textMuted)));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: articles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final a = articles[i];
                        return NewsCard(
                          article: a,
                          onTap: () async {
                            final uri = Uri.tryParse(a.url);
                            if (uri != null && await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
