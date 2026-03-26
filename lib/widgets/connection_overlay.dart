// lib/widgets/connection_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';

class ConnectionOverlay extends StatefulWidget {
  final UserModel peer;
  final VoidCallback onCancel;

  const ConnectionOverlay({
    super.key,
    required this.peer,
    required this.onCancel,
  });

  @override
  State<ConnectionOverlay> createState() => _ConnectionOverlayState();
}

class _ConnectionOverlayState extends State<ConnectionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.bg.withValues(alpha: 0.92),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pulsing rings
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                return SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: List.generate(3, (i) {
                      final t = (_ctrl.value + i * 0.33) % 1.0;
                      return Opacity(
                        opacity: (1 - t) * 0.6,
                        child: Container(
                          width: 40 + t * 80,
                          height: 40 + t * 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.accent,
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    })
                      ..add(
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentGlow,
                            border:
                                Border.all(color: AppTheme.accent, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              widget.peer.name.substring(0, 2).toUpperCase(),
                              style: GoogleFonts.orbitron(
                                color: AppTheme.accent,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            Text(
              'CONNECTING',
              style: GoogleFonts.orbitron(
                color: AppTheme.accent,
                fontSize: 13,
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
              ),
            ).animate(onPlay: (c) => c.repeat()).shimmer(
                  duration: 1200.ms,
                  color: AppTheme.accentDim,
                ),

            const SizedBox(height: 8),

            Text(
              widget.peer.name,
              style: GoogleFonts.spaceMono(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 40),

            GestureDetector(
              onTap: widget.onCancel,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.divider),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'CANCEL',
                  style: GoogleFonts.orbitron(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}
