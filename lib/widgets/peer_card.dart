// lib/widgets/peer_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';

class PeerCard extends StatelessWidget {
  final UserModel peer;
  final VoidCallback onTap;
  final int index;

  const PeerCard({
    super.key,
    required this.peer,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: peer.status == ConnectionStatus.connected
                ? AppTheme.accent.withValues(alpha: 0.4)
                : AppTheme.divider,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: AppTheme.accent.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.stranger.withValues(alpha: 0.3),
                          AppTheme.stranger.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: AppTheme.stranger.withValues(alpha: 0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        peer.name.substring(0, 2).toUpperCase(),
                        style: GoogleFonts.orbitron(
                          color: AppTheme.stranger,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          peer.name,
                          style: GoogleFonts.orbitron(
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Anonymous · Nearby',
                          style: GoogleFonts.spaceMono(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // status / action
                  _buildStatusBadge(peer.status),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: (index * 80).ms)
        .slideX(begin: 0.15, end: 0, duration: 300.ms, curve: Curves.easeOut)
        .fadeIn(duration: 250.ms);
  }

  Widget _buildStatusBadge(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connecting:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppTheme.accent),
          ),
        );
      case ConnectionStatus.connected:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.accentGlow,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.4)),
          ),
          child: Text(
            'LIVE',
            style: GoogleFonts.orbitron(
              color: AppTheme.accent,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      default:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.stranger.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppTheme.stranger.withValues(alpha: 0.3)),
          ),
          child: Text(
            'TAP',
            style: GoogleFonts.orbitron(
              color: AppTheme.stranger,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
    }
  }
}
