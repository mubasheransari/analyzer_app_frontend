import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chat_message.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ApiService _api;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final List<ChatUiMessage> _messages = [];
  String? _sessionId;
  bool _sending = false;

  static const _suggestedPrompts = [
    'What is Bitcoin dominance?',
    "What's the current price of Ethereum?",
    'Explain what a bull flag pattern is',
    "How's the total crypto market doing today?",
  ];

  @override
  void initState() {
    super.initState();
    _api = context.read<ApiService>();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? presetText]) async {
    final text = (presetText ?? _messageController.text).trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _messages.add(ChatUiMessage(role: 'user', content: text));
      _messages.add(ChatUiMessage(role: 'assistant', content: '', isLoading: true));
      _sending = true;
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      final result = await _api.sendChatMessage(message: text, sessionId: _sessionId);
      _sessionId = result['session_id'] as String;
      final sources = (result['sources'] as List? ?? [])
          .map((e) => ChatSource.fromJson(e as Map<String, dynamic>))
          .toList();

      setState(() {
        _messages.removeLast();
        _messages.add(ChatUiMessage(
          role: 'assistant',
          content: result['reply'] as String,
          sources: sources,
          usedLiveData: result['used_live_data'] as bool? ?? false,
        ));
      });
    } on ApiException catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(ChatUiMessage(role: 'assistant', content: '⚠️ ${e.message}'));
      });
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add( ChatUiMessage(
          role: 'assistant',
          content: '⚠️ Something went wrong. Please try again.',
        ));
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
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
              child: Row(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => AppColors.gradientBrand.createShader(bounds),
                    child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 8),
                  const Text('Crypto AI Chat',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            Expanded(
              child: _messages.isEmpty ? _buildEmptyState() : _buildMessageList(),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          ShaderMask(
            shaderCallback: (bounds) => AppColors.gradientBrand.createShader(bounds),
            child: const Icon(Icons.smart_toy_outlined, size: 48, color: Colors.white),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ask me anything about crypto',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Live prices, market data, and general crypto knowledge.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _suggestedPrompts
                .map((p) => _SuggestionChip(text: p, onTap: () => _send(p)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _messages.length,
      itemBuilder: (context, i) => _MessageBubble(message: _messages[i]),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).viewInsets.bottom > 12
            ? 12
            : MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: const InputDecoration(
                hintText: 'Ask about crypto...',
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sending ? null : () => _send(),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: _sending ? null : AppColors.gradientBrand,
                color: _sending ? AppColors.surfaceElevated : null,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textMuted),
                    )
                  : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatUiMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: const BoxDecoration(
                gradient: AppColors.gradientBrand,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_outlined, color: Colors.white, size: 16),
            ),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    gradient: isUser ? AppColors.gradientBrand : null,
                    color: isUser ? null : AppColors.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    border: isUser ? null : Border.all(color: AppColors.cardBorder),
                  ),
                  child: message.isLoading
                      ? const _TypingIndicator()
                      : Text(
                          message.content,
                          style: TextStyle(
                            color: isUser ? Colors.white : AppColors.textPrimary,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                ),
                if (!message.isLoading && message.usedLiveData) ...[
                  const SizedBox(height: 6),
                  const _LiveDataTag(),
                ],
                if (!message.isLoading && message.sources.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: message.sources
                        .map((s) => _SourceChip(source: s))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveDataTag extends StatelessWidget {
  const _LiveDataTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.positive.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: AppColors.positive, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          const Text('Live market data used',
              style: TextStyle(color: AppColors.positive, fontSize: 10.5, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  final ChatSource source;

  const _SourceChip({required this.source});

  @override
  Widget build(BuildContext context) {
    final icon = source.sourceType == 'news' ? Icons.article_outlined : Icons.school_outlined;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.brandEnd),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              source.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 14,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(3, (i) {
              final t = (_controller.value - i * 0.2) % 1.0;
              final opacity = (0.3 + 0.7 * (1 - (t - 0.5).abs() * 2)).clamp(0.3, 1.0);
              return Opacity(
                opacity: opacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
