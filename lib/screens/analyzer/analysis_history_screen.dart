import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../models/analysis_notification.dart';
import '../../models/chart_analysis.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AnalysisHistoryScreen extends StatefulWidget {
  const AnalysisHistoryScreen({super.key});

  @override
  State<AnalysisHistoryScreen> createState() => _AnalysisHistoryScreenState();
}

class _AnalysisHistoryScreenState extends State<AnalysisHistoryScreen>
    with SingleTickerProviderStateMixin {
  late final ApiService _api;
  late final TabController _tabs;
  Timer? _poller;
  List<ChartAnalysis> _mine = [];
  List<ChartAnalysis> _others = [];
  List<AnalysisNotification> _notifications = [];
  bool _loading = true;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
    _tabs = TabController(length: 2, vsync: this);
    _load();
    _poller = Timer.periodic(const Duration(seconds: 20), (_) => _load(silent: true));
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.getAnalysisHistory(scope: 'mine'),
        _api.getAnalysisHistory(scope: 'other'),
        _api.getAnalysisNotifications(),
      ]);
      if (!mounted) return;
      setState(() {
        _mine = results[0] as List<ChartAnalysis>;
        _others = results[1] as List<ChartAnalysis>;
        _notifications = results[2] as List<AnalysisNotification>;
        _unread = _notifications.where((n) => !n.isRead).length;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load analysis history: $e')),
        );
      }
    }
  }

  Future<void> _openPdf(ChartAnalysis item, {bool download = false}) async {
    try {
      final bytes = await _api.downloadAnalysisPdfBytes(item.id);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/analysis-${item.id}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      if (download) {
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          text: 'Crypto Insights chart analysis #${item.id}',
        );
      } else {
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open PDF: $e')),
        );
      }
    }
  }

  Future<void> _showNotifications() async {
    await _api.markAnalysisNotificationsRead();
    if (!mounted) return;
    setState(() => _unread = 0);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * .62,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Row(children: [
                  Icon(Icons.notifications_active_outlined, color: AppColors.brandEnd),
                  SizedBox(width: 10),
                  Text('Notifications', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: _notifications.isEmpty
                    ? const Center(child: Text('No analysis notifications yet.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final n = _notifications[i];
                          return ListTile(
                            tileColor: AppColors.surfaceElevated,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            leading: const CircleAvatar(
                              backgroundColor: AppColors.surfaceElevated,
                              child: Icon(Icons.auto_awesome, color: AppColors.brandEnd),
                            ),
                            title: Text(n.message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text(DateFormat('dd MMM, hh:mm a').format(n.createdAt)),
                            onTap: () {
                              Navigator.pop(context);
                              final index = _others.indexWhere((a) => a.id == n.analysisId);
                              if (index >= 0) _showAnalysis(_others[index]);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnalysis(ChartAnalysis a) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AnalysisDetails(
        analysis: a,
        onViewPdf: () => _openPdf(a),
        onDownloadPdf: () => _openPdf(a, download: true),
      ),
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analysis History', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          Stack(
            children: [
              IconButton(
                onPressed: _showNotifications,
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              if (_unread > 0)
                Positioned(
                  right: 7, top: 7,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppColors.negative, shape: BoxShape.circle),
                    child: Text('$_unread', style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
            ],
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'My'), Tab(text: 'Other')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _HistoryList(items: _mine, emptyText: 'You have not created an analysis yet.', onOpen: _showAnalysis),
                _HistoryList(items: _others, emptyText: 'No other users have published an analysis yet.', onOpen: _showAnalysis),
              ],
            ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<ChartAnalysis> items;
  final String emptyText;
  final ValueChanged<ChartAnalysis> onOpen;
  const _HistoryList({required this.items, required this.emptyText, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return Center(child: Text(emptyText));
    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _HistoryCard(analysis: items[i], onTap: () => onOpen(items[i])),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ChartAnalysis analysis;
  final VoidCallback onTap;
  const _HistoryCard({required this.analysis, required this.onTap});

  Color _riskColor() {
    final r = analysis.riskLevel.toLowerCase();
    if (r.startsWith('low')) return AppColors.positive;
    if (r.startsWith('high')) return AppColors.negative;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final analyst = analysis.isMine ? 'You' : (analysis.analystName ?? analysis.analystEmail ?? 'Another user');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(analysis.coinHint?.isNotEmpty == true ? analysis.coinHint! : 'Chart Analysis',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: (analysis.isMine ? AppColors.brandEnd : AppColors.textMuted).withOpacity(.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(analysis.isMine ? 'MY' : 'OTHER',
                style: TextStyle(color: analysis.isMine ? AppColors.brandEnd : AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ]),
          const SizedBox(height: 8),
          Text('$analyst • ${DateFormat('dd MMM yyyy, hh:mm a').format(analysis.createdAt)}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _Mini(label: 'Trend', value: analysis.trend)),
            Expanded(child: _Mini(label: 'Risk', value: analysis.riskLevel, color: _riskColor())),
            Expanded(child: _Mini(label: 'Target', value: analysis.targetPrice)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Icon(Icons.touch_app_outlined, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 5),
            const Text('Tap to view full analysis + PDF', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ]),
        ]),
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _Mini({required this.label, required this.value, this.color});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
    const SizedBox(height: 3),
    Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color ?? AppColors.textPrimary)),
  ]);
}

class _AnalysisDetails extends StatelessWidget {
  final ChartAnalysis analysis;
  final VoidCallback onViewPdf;
  final VoidCallback onDownloadPdf;
  const _AnalysisDetails({required this.analysis, required this.onViewPdf, required this.onDownloadPdf});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false, initialChildSize: .9, minChildSize: .55, maxChildSize: .96,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          children: [
            Row(children: [
              Expanded(child: Text(analysis.coinHint ?? 'Chart Analysis', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
              IconButton(onPressed: onViewPdf, tooltip: 'View PDF', icon: const Icon(Icons.picture_as_pdf_outlined)),
              IconButton(onPressed: onDownloadPdf, tooltip: 'Download PDF', icon: const Icon(Icons.download_rounded)),
            ]),
            Text('By ${analysis.isMine ? 'You' : (analysis.analystName ?? 'Another user')} • ${DateFormat('dd MMM yyyy, hh:mm a').format(analysis.createdAt)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 18),
            _DetailSection('Trend', analysis.trend),
            _DetailSection('Key Pattern', analysis.keyPattern),
            _DetailSection('Price Levels', 'Current: ${analysis.currentPrice}\nEntry: ${analysis.entryPrice}\nStop Loss: ${analysis.stopLoss}\nTarget: ${analysis.targetPrice}\nInvalidation: ${analysis.invalidationLevel}'),
            _DetailSection('Indicators', analysis.indicators),
            _DetailSection('Setup Clarity', analysis.setupClarity),
            _DetailSection('Risk Level', analysis.riskLevel),
            _DetailSection('Volatility', analysis.volatilityRead),
            _DetailSection('Bullish Scenario', analysis.bullishScenario),
            _DetailSection('Bearish Scenario', analysis.bearishScenario),
            _DetailSection('Disclaimer', analysis.disclaimer),
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title, body;
  const _DetailSection(this.title, this.body);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.cardBorder)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: AppColors.brandEnd, fontWeight: FontWeight.w800, fontSize: 12)),
      const SizedBox(height: 5),
      Text(body, style: const TextStyle(fontSize: 13, height: 1.45)),
    ]),
  );
}
