import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/education_topic.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late final ApiService _api;
  late Future<List<EducationTopic>> _future;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    _future = _api.getEducationTopics();
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Basics':
        return Icons.school_outlined;
      case 'Patterns':
        return Icons.timeline_rounded;
      case 'Indicators':
        return Icons.insights_rounded;
      default:
        return Icons.shield_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<List<EducationTopic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.brandEnd));
            }
            if (snapshot.hasError) {
              return const Center(
                  child: Text('Could not load lessons', style: TextStyle(color: AppColors.textMuted)));
            }
            final topics = snapshot.data ?? [];
            final categories = <String, List<EducationTopic>>{};
            for (final t in topics) {
              categories.putIfAbsent(t.category, () => []).add(t);
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Learn', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                const Text(
                  'Technical analysis knowledge, explained simply.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 20),
                for (final entry in categories.entries) ...[
                  Row(
                    children: [
                      Icon(_categoryIcon(entry.key), color: AppColors.brandEnd, size: 18),
                      const SizedBox(width: 8),
                      Text(entry.key,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...entry.value.map(
                    (topic) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _TopicCard(topic: topic),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopicCard extends StatelessWidget {
  final EducationTopic topic;
  const _TopicCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TopicDetailScreen(slug: topic.slug)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(topic.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(topic.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class TopicDetailScreen extends StatefulWidget {
  final String slug;
  const TopicDetailScreen({super.key, required this.slug});

  @override
  State<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends State<TopicDetailScreen> {
  late final ApiService _api;
  late Future<EducationTopic> _future;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    _future = _api.getEducationTopic(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(),
      body: SafeArea(
        child: FutureBuilder<EducationTopic>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.brandEnd));
            }
            if (snapshot.hasError) {
              return const Center(
                  child: Text('Could not load lesson', style: TextStyle(color: AppColors.textMuted)));
            }
            final topic = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandStart.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(topic.category,
                        style: const TextStyle(color: AppColors.brandEnd, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 12),
                  Text(topic.title,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Text(
                    topic.content ?? topic.summary,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, height: 1.6),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
