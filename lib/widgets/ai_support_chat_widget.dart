import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../services/ai_support_agent_service.dart';
import '../services/site_settings_service.dart';

/// Wraps a routed screen so the AI chat lives under the Navigator [Overlay].
class AiSupportHost extends StatelessWidget {
  const AiSupportHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SiteSettingsService.instance,
      builder: (context, _) {
        final showChat =
            SiteSettingsService.instance.settings.flags.showAiChat;
        return Stack(
          fit: StackFit.expand,
          children: [
            child,
            if (showChat) const AiSupportChatOverlay(),
          ],
        );
      },
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

/// Floating AI Support Agent (button + panel). Must sit under a Navigator Overlay.
class AiSupportChatOverlay extends StatefulWidget {
  const AiSupportChatOverlay({super.key});

  @override
  State<AiSupportChatOverlay> createState() => _AiSupportChatOverlayState();
}

class _AiSupportChatOverlayState extends State<AiSupportChatOverlay> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _open = false;
  bool _typing = false;
  bool _seeded = false;
  String? _seededLocale;

  static const _quickKeys = [
    'aiSupport.chip.request',
    'aiSupport.chip.donate',
    'aiSupport.chip.reservation',
    'aiSupport.chip.shipping',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = Localizations.localeOf(context).languageCode;
    if (!_seeded || _seededLocale != code) {
      final loc = AppLocalizations.of(context);
      final welcome = loc.t('aiSupport.welcome');
      if (_messages.isEmpty) {
        _messages.add(_ChatMessage(text: welcome, isUser: false));
      } else if (_messages.length == 1 && !_messages.first.isUser) {
        _messages[0] = _ChatMessage(text: welcome, isUser: false);
      }
      _seeded = true;
      _seededLocale = code;
    }
  }

  Future<void> _send(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _typing) return;

    final loc = AppLocalizations.of(context);
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _typing = true;
      _controller.clear();
    });
    _scrollToEnd();

    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final reply = AiSupportAgentService.instance.reply(
      userMessage: text,
      loc: loc,
    );
    setState(() {
      _typing = false;
      _messages.add(_ChatMessage(text: reply, isUser: false));
    });
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.padding.bottom;
    final keyboard = media.viewInsets.bottom;
    final loc = AppLocalizations.of(context);

    // Only the FAB (and open panel) participate in hit-testing so AppBar
    // controls like the language picker remain tappable underneath.
    return Stack(
      children: [
        if (_open) ...[
          Positioned.fill(
            child: Semantics(
              label: loc.t('a11y.dismissOverlay'),
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _open = false),
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: 0.28),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            left: media.size.width < 440 ? 16 : null,
            bottom: math.max(72, 72 + bottomInset) + keyboard,
            child: Material(
              type: MaterialType.transparency,
              child: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: Semantics(
                  scopesRoute: true,
                  namesRoute: true,
                  explicitChildNodes: true,
                  label: loc.t('aiSupport.title'),
                  child: _ChatPanel(
                    messages: _messages,
                    typing: _typing,
                    controller: _controller,
                    scrollController: _scrollController,
                    quickKeys: _quickKeys,
                    onClose: () => setState(() => _open = false),
                    onSend: _send,
                  ),
                ),
              ),
            ),
          ),
        ],
        Positioned(
          right: 18,
          bottom: 18 + bottomInset,
          child: Semantics(
            button: true,
            label: _open
                ? loc.t('aiSupport.close')
                : loc.t('aiSupport.fabTooltip'),
            expanded: _open,
            child: Tooltip(
              message: _open
                  ? loc.t('aiSupport.close')
                  : loc.t('aiSupport.fabTooltip'),
              child: Material(
                elevation: 8,
                color: AppTheme.primaryDeepBlue,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => setState(() => _open = !_open),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: Icon(
                      _open ? Icons.close : Icons.support_agent,
                      color: Colors.white,
                      semanticLabel: _open
                          ? loc.t('aiSupport.close')
                          : loc.t('aiSupport.fabTooltip'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChatPanel extends StatelessWidget {
  const _ChatPanel({
    required this.messages,
    required this.typing,
    required this.controller,
    required this.scrollController,
    required this.quickKeys,
    required this.onClose,
    required this.onSend,
  });

  final List<_ChatMessage> messages;
  final bool typing;
  final TextEditingController controller;
  final ScrollController scrollController;
  final List<String> quickKeys;
  final VoidCallback onClose;
  final Future<void> Function(String) onSend;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final panelWidth = width < 440 ? width - 32 : 380.0;
    final maxPanelHeight = math.max(
      240.0,
      media.size.height -
          media.padding.vertical -
          media.viewInsets.bottom -
          100,
    );
    final panelHeight = math.min(480.0, maxPanelHeight);

    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: panelWidth,
          maxHeight: panelHeight,
          minWidth: math.min(panelWidth, 280),
        ),
        child: SizedBox(
          width: panelWidth,
          height: panelHeight,
          child: Column(
            children: [
              _Header(title: loc.t('aiSupport.title'), onClose: onClose),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: messages.length + (typing ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (typing && index == messages.length) {
                      return _Bubble(
                        text: loc.t('aiSupport.typing'),
                        isUser: false,
                        italic: true,
                        maxWidth: panelWidth * 0.82,
                      );
                    }
                    final msg = messages[index];
                    return _Bubble(
                      text: msg.text,
                      isUser: msg.isUser,
                      maxWidth: panelWidth * 0.82,
                    );
                  },
                ),
              ),
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  itemCount: quickKeys.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final key = quickKeys[index];
                    return ActionChip(
                      label: Text(loc.t(key)),
                      onPressed: typing ? null : () => onSend(loc.t(key)),
                      backgroundColor: AppTheme.skyBlue.withValues(alpha: 0.35),
                      side: BorderSide(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.25),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 2,
                        textInputAction: TextInputAction.send,
                        onSubmitted: typing ? null : onSend,
                        decoration: InputDecoration(
                          labelText: loc.t('aiSupport.inputHint'),
                          hintText: loc.t('aiSupport.inputHint'),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: loc.t('a11y.sendMessage'),
                      onPressed:
                          typing ? null : () => onSend(controller.text),
                      icon: const Icon(Icons.send_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryDeepBlue, AppTheme.primaryBlue],
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            child: Icon(Icons.smart_toy_outlined, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF69F0AE),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      loc.t('aiSupport.online'),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: loc.t('aiSupport.close'),
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.isUser,
    required this.maxWidth,
    this.italic = false,
  });

  final String text;
  final bool isUser;
  final double maxWidth;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.primaryBlue.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.4,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                color: italic ? Colors.grey.shade700 : null,
              ),
        ),
      ),
    );
  }
}
