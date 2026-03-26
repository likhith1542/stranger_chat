// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../providers/app_providers.dart';
import '../utils/app_theme.dart';
import '../widgets/message_bubble.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final UserModel peer;
  final String sessionId;

  const ChatScreen({super.key, required this.peer, required this.sessionId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _isComposing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider(widget.sessionId));
    final connection = ref.watch(activeConnectionProvider);
    final isTyping = ref.watch(typingProvider(widget.peer.id));
    // Must use .userId (UUID), not .username — senderId is set to the UUID
    final localUserId = ref.read(identityProvider).userId;
    final peerId = widget.peer.id;
    final encryptionReady = ref.watch(encryptionReadyProvider(peerId));

    // Auto scroll when new messages arrive
    ref.listen(chatProvider(widget.sessionId), (_, __) => _scrollToBottom());

    final isDisconnected = connection.status == ConnectionStatus.disconnected;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: _buildAppBar(connection, isDisconnected,
          encryptionReady: encryptionReady),
      body: Column(
        children: [
          if (isDisconnected) _buildDisconnectedBanner(),
          Expanded(
            child: messages.isEmpty
                ? _buildEmptyChat()
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: messages.length + (isTyping ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (isTyping && i == messages.length) {
                        return const Padding(
                          padding: EdgeInsets.only(left: 16, bottom: 4),
                          child: TypingIndicator(),
                        );
                      }
                      return MessageBubble(
                          message: messages[i], localUserId: localUserId);
                    },
                  ),
          ),
          _buildEncryptionBadge(encryptionReady),
          _buildInputBar(isDisconnected, encryptionReady),
        ],
      ),
    );
  }

  AppBar _buildAppBar(ActiveConnection connection, bool isDisconnected,
      {bool encryptionReady = false}) {
    return AppBar(
      backgroundColor: AppTheme.surface,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios,
            color: AppTheme.textSecondary, size: 18),
        onPressed: () {
          ref.read(activeConnectionProvider.notifier).disconnect();
          Navigator.pop(context);
        },
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.stranger.withValues(alpha: 0.12),
              border: Border.all(
                color: isDisconnected
                    ? AppTheme.textMuted
                    : AppTheme.stranger.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                widget.peer.name.substring(0, 2).toUpperCase(),
                style: GoogleFonts.orbitron(
                  color:
                      isDisconnected ? AppTheme.textMuted : AppTheme.stranger,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.peer.name,
                  style: GoogleFonts.orbitron(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isDisconnected)
                      Icon(
                        encryptionReady
                            ? Icons.lock_rounded
                            : Icons.lock_open_rounded,
                        color: encryptionReady
                            ? AppTheme.accent
                            : AppTheme.textMuted,
                        size: 9,
                      ),
                    if (!isDisconnected) const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        isDisconnected
                            ? 'Disconnected'
                            : encryptionReady
                                ? 'Encrypted'
                                : 'Connected',
                        style: GoogleFonts.spaceMono(
                          color: isDisconnected
                              ? AppTheme.danger
                              : AppTheme.accent,
                          fontSize: 9,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          color: AppTheme.surface,
          icon: const Icon(Icons.more_vert,
              color: AppTheme.textSecondary, size: 20),
          onSelected: (val) => _handleMenuAction(val),
          itemBuilder: (_) => [
            _menuItem('clear', Icons.delete_outline, 'Clear Chat'),
            _menuItem('block', Icons.block, 'Block User'),
            _menuItem('next', Icons.skip_next, 'Next Stranger'),
          ],
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.divider),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String val, IconData icon, String label) {
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 16),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.spaceMono(
                  color: AppTheme.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildDisconnectedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppTheme.danger.withValues(alpha: 0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.link_off, color: AppTheme.danger, size: 14),
          const SizedBox(width: 8),
          Text(
            'Connection lost',
            style: GoogleFonts.spaceMono(color: AppTheme.danger, fontSize: 11),
          ),
        ],
      ),
    ).animate().slideY(begin: -1, end: 0, duration: 250.ms);
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, color: AppTheme.textMuted, size: 32),
          const SizedBox(height: 12),
          Text(
            'End-to-end encrypted',
            style: GoogleFonts.orbitron(
              color: AppTheme.textMuted,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Messages never leave your network',
            style: GoogleFonts.spaceMono(
              color: AppTheme.textMuted.withValues(alpha: 0.6),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(bool isDisconnected, bool encryptionReady) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(top: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceHigh,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isComposing
                      ? AppTheme.accent.withValues(alpha: 0.3)
                      : AppTheme.divider,
                ),
              ),
              child: TextField(
                controller: _ctrl,
                enabled: !isDisconnected && encryptionReady,
                maxLines: 4,
                minLines: 1,
                onChanged: (v) {
                  setState(() => _isComposing = v.trim().isNotEmpty);
                  if (v.isNotEmpty) {
                    ref
                        .read(chatProvider(widget.sessionId).notifier)
                        .sendTyping();
                  }
                },
                style: GoogleFonts.spaceMono(
                    color: AppTheme.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: isDisconnected
                      ? 'Disconnected...'
                      : !encryptionReady
                          ? 'Securing channel...'
                          : 'Message...',
                  hintStyle: GoogleFonts.spaceMono(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedScale(
            scale: _isComposing ? 1.0 : 0.85,
            duration: const Duration(milliseconds: 150),
            child: GestureDetector(
              onTap: (encryptionReady && !isDisconnected) ? _sendMessage : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isComposing && !isDisconnected
                      ? AppTheme.accent
                      : AppTheme.surfaceHigh,
                  boxShadow: _isComposing && !isDisconnected
                      ? [
                          BoxShadow(
                            color: AppTheme.accent.withValues(alpha: 0.3),
                            blurRadius: 16,
                          )
                        ]
                      : [],
                ),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: _isComposing && !isDisconnected
                      ? AppTheme.bg
                      : AppTheme.textMuted,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _ctrl.text;
    if (text.trim().isEmpty) return;
    _ctrl.clear();
    setState(() => _isComposing = false);
    ref.read(chatProvider(widget.sessionId).notifier).sendMessage(text);
  }

  Widget _buildEncryptionBadge(bool encryptionReady) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      height: encryptionReady ? 0 : 28,
      color: encryptionReady ? Colors.transparent : AppTheme.accentGlow,
      child: encryptionReady
          ? const SizedBox.shrink()
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(AppTheme.accent),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Establishing encrypted channel...',
                  style: GoogleFonts.spaceMono(
                      color: AppTheme.accent, fontSize: 10),
                ),
              ],
            ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear':
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text('Clear chat?',
                style: GoogleFonts.orbitron(
                    color: AppTheme.textPrimary, fontSize: 14)),
            content: Text('This will delete all messages locally.',
                style: GoogleFonts.spaceMono(
                    color: AppTheme.textSecondary, fontSize: 12)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('CANCEL',
                    style: GoogleFonts.orbitron(
                        color: AppTheme.textMuted, fontSize: 11)),
              ),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                onPressed: () {
                  ref.read(chatProvider(widget.sessionId).notifier).clearChat();
                  Navigator.pop(context);
                },
                child: Text('CLEAR',
                    style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
        break;

      case 'block':
        ref.read(blockedUsersProvider.notifier).block(widget.peer.id);
        ref.read(activeConnectionProvider.notifier).disconnect();
        Navigator.pop(context);
        break;

      case 'next':
        ref.read(activeConnectionProvider.notifier).disconnect();
        Navigator.pop(context);
        break;
    }
  }
}
