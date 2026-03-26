// lib/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/message_model.dart';
import '../utils/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final String localUserId;
  final bool showTimestamp;

  const MessageBubble({
    super.key,
    required this.message,
    required this.localUserId,
    this.showTimestamp = false,
  });

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return _buildSystemMessage();
    }

    final isMe = message.isMe(localUserId);
    return Padding(
      padding: EdgeInsets.only(
        left: isMe ? 64 : 16,
        right: isMe ? 16 : 64,
        top: 2,
        bottom: 2,
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.accentGlow : AppTheme.surfaceHigh,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: Border.all(
                color: isMe
                    ? AppTheme.accent.withValues(alpha: 0.3)
                    : AppTheme.divider,
                width: 1,
              ),
            ),
            child: Text(
              message.content,
              style: GoogleFonts.spaceMono(
                color: isMe ? AppTheme.accent : AppTheme.textPrimary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.timestamp),
                style: GoogleFonts.spaceMono(
                  color: AppTheme.textMuted,
                  fontSize: 9,
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                _buildStatusIcon(message.status),
              ],
            ],
          ),
        ],
      ),
    )
        .animate()
        .slideX(
          begin: isMe ? 0.1 : -0.1,
          end: 0,
          duration: 200.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(duration: 150.ms);
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceHigh,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Text(
            message.content,
            style: GoogleFonts.spaceMono(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation(AppTheme.textMuted),
          ),
        );
      case MessageStatus.sent:
        return const Icon(Icons.check, size: 11, color: AppTheme.textMuted);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all, size: 11, color: AppTheme.accent);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline,
            size: 11, color: AppTheme.danger);
    }
  }

  String _formatTime(int timestamp) {
    return DateFormat('HH:mm').format(
      DateTime.fromMillisecondsSinceEpoch(timestamp),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _anim,
            builder: (_, __) {
              final t = (_anim.value + i * 0.33) % 1.0;
              final scale = 0.6 + 0.4 * (sin(t * 3.14));
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.stranger.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

double sin(double x) => _sin(x);

double _sin(double x) {
  // simple sin approximation
  return (x < 0.5) ? 4 * x * (1 - 2 * x) : -4 * (x - 0.5) * (1 - 2 * (x - 0.5));
}
