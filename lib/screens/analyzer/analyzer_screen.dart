import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/education_topic.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AnalyzerScreen extends StatefulWidget {
  const AnalyzerScreen({super.key});

  @override
  State<AnalyzerScreen> createState() => _AnalyzerScreenState();
}

class _AnalyzerScreenState extends State<AnalyzerScreen> {
  late final ApiService _api;
  final _picker = ImagePicker();
  final _coinHintController = TextEditingController();
  final _noteController = TextEditingController();

  File? _imageFile;
  bool _loading = false;
  ChartAnalysisResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked != null) {
      setState(() {
        _imageFile = File(picked.path);
        _result = null;
        _error = null;
      });
    }
  }

  void _showSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.brandEnd),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.brandEnd),
                title: const Text('Take a screenshot / photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _analyze() async {
    if (_imageFile == null) return;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await _api.analyzeChart(
        imageFile: _imageFile!,
        coinHint: _coinHintController.text.trim(),
        note: _noteController.text.trim(),
      );
      setState(() => _result = ChartAnalysisResult.fromJson(result));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not analyze this image. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _coinHintController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chart Analyzer',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text(
                'Upload a chart screenshot and let AI break down the trend, patterns, and key levels.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _showSourceSheet,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.cardBorder, width: 1.2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _imageFile == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) =>
                                  AppColors.gradientBrand.createShader(bounds),
                              child: const Icon(Icons.add_photo_alternate_outlined,
                                  size: 42, color: Colors.white),
                            ),
                            const SizedBox(height: 10),
                            const Text('Tap to upload a chart screenshot',
                                style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        )
                      : Image.file(_imageFile!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _coinHintController,
                decoration: const InputDecoration(
                  hintText: 'Coin (optional), e.g. BTC/USDT',
                  prefixIcon: Icon(Icons.currency_bitcoin, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Anything specific to focus on? (optional)',
                  prefixIcon: Icon(Icons.edit_note, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: (_imageFile == null || _loading) ? null : _analyze,
                  icon: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(_loading ? 'Analyzing...' : 'Analyze Chart'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.negative.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.negative.withOpacity(0.3)),
                  ),
                  child: Text(_error!, style: const TextStyle(color: AppColors.negative)),
                ),
              ],
              if (_result != null) ...[
                const SizedBox(height: 24),
                _AnalysisResultCard(result: _result!),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the backend's structured analysis fields directly - trend,
/// pattern, price levels, indicators, scenarios, and an honest qualitative
/// risk read (deliberately never a numeric "success chance" or a binary
/// safe/unsafe verdict - see the backend's gemini_vision.py docstring for
/// why).
class _AnalysisResultCard extends StatelessWidget {
  final ChartAnalysisResult result;

  const _AnalysisResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.gradientCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => AppColors.gradientBrand.createShader(bounds),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Text('AI Chart Analysis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),

          // Is this safe right now? This IS the honest answer to that
          // question - a qualitative Low/Medium/High read with a real
          // reason, shown first and prominently, deliberately never a
          // fabricated percentage or yes/no verdict.
          _RiskLevelBadge(riskLevel: result.riskLevel),
          const SizedBox(height: 16),

          _Section(icon: Icons.trending_up_rounded, title: 'Trend', body: result.trend),
          const SizedBox(height: 14),
          _Section(icon: Icons.pattern_rounded, title: 'Key Pattern', body: result.keyPattern),
          const SizedBox(height: 16),

          // Current price - a plain readout, visually distinct from the
          // analyzed reference levels below so it's never confused with them.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.radio_button_checked, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 8),
                const Text('Current Price (read from chart)',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                const Spacer(),
                Text(
                  result.currentPrice,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          _Section(
            icon: Icons.my_location_rounded,
            title: 'Entry Zone (analyzed, not current price)',
            body: result.entryPrice,
            accentColor: AppColors.brandEnd,
          ),
          const SizedBox(height: 14),

          // Price-level reference row: stop-loss / target
          Row(
            children: [
              Expanded(
                child: _PriceLevelChip(
                  label: 'Stop-Loss Ref.',
                  value: result.stopLoss,
                  color: AppColors.negative,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PriceLevelChip(
                  label: 'Target Ref.',
                  value: result.targetPrice,
                  color: AppColors.positive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _Section(
            icon: Icons.block_rounded,
            title: 'Invalidation Level',
            body: result.invalidationLevel,
          ),
          const SizedBox(height: 14),
          _Section(icon: Icons.insights_rounded, title: 'Indicators', body: result.indicators),
          const SizedBox(height: 14),
          _Section(
            icon: Icons.trending_up_rounded,
            title: 'Bullish Scenario',
            body: result.bullishScenario,
            accentColor: AppColors.positive,
          ),
          const SizedBox(height: 14),
          _Section(
            icon: Icons.trending_down_rounded,
            title: 'Bearish Scenario',
            body: result.bearishScenario,
            accentColor: AppColors.negative,
          ),
          const SizedBox(height: 14),
          _Section(
            icon: Icons.show_chart_rounded,
            title: 'Volatility',
            body: result.volatilityRead,
          ),
          const SizedBox(height: 14),
          _Section(
            icon: Icons.visibility_outlined,
            title: 'Setup Clarity',
            body: result.setupClarity,
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
                    result.disclaimer,
                    style: TextStyle(color: AppColors.warning.withOpacity(0.9), fontSize: 12),
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

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color? accentColor;

  const _Section({
    required this.icon,
    required this.title,
    required this.body,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.brandEnd;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A small chip showing an approximate price-level reference. Shows the
/// value in a muted style when the model couldn't read it off the chart,
/// so it's visually clear this isn't a confident number.
class _PriceLevelChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PriceLevelChip({required this.label, required this.value, required this.color});

  bool get _isUnreadable =>
      value.toLowerCase().contains('not clearly readable') || value.trim().isEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (_isUnreadable ? AppColors.textMuted : color).withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            _isUnreadable ? 'N/A' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _isUnreadable ? AppColors.textMuted : color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontStyle: _isUnreadable ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the qualitative risk read (Low/Medium/High + reason) with color
/// coding by word - this is the direct, honest answer to "is this safe to
/// trade right now", deliberately never a numeric risk score or percentage.
class _RiskLevelBadge extends StatelessWidget {
  final String riskLevel;

  const _RiskLevelBadge({required this.riskLevel});

  Color get _color {
    final lower = riskLevel.toLowerCase();
    if (lower.startsWith('low')) return AppColors.positive;
    if (lower.startsWith('high')) return AppColors.negative;
    return AppColors.warning;
  }

  String get _word {
    final lower = riskLevel.toLowerCase();
    if (lower.startsWith('low')) return 'LOW RISK';
    if (lower.startsWith('high')) return 'HIGH RISK';
    return 'MEDIUM RISK';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: _color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _word,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  riskLevel,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
