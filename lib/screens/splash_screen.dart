// lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/app_providers.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glitchCtrl;
  String _statusText = 'INITIALIZING...';
  bool _ready = false;

  final List<String> _bootLines = [
    'LOADING KERNEL...',
    'SCANNING INTERFACES...',
    'GENERATING IDENTITY...',
    'BINDING UDP:45000...',
    'TCP SERVER READY...',
    'SYSTEM ONLINE ✓',
  ];

  int _lineIndex = 0;

  @override
  void initState() {
    super.initState();
    _glitchCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _runBootSequence();
  }

  @override
  void dispose() {
    _glitchCtrl.dispose();
    super.dispose();
  }

  Future<void> _runBootSequence() async {
    // Initialize identity — StateNotifierProvider has no .future;
    // wait on the notifier's public ensureInitialized() instead.
    await ref.read(identityStateProvider.notifier).ensureInitialized();

    // Step through boot lines
    for (final line in _bootLines) {
      await Future.delayed(const Duration(milliseconds: 320));
      if (!mounted) return;
      setState(() {
        _statusText = line;
        _lineIndex++;
      });
    }

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() => _ready = true);
  }

  Future<void> _requestPermissionsAndContinue() async {
    // Nearby Connections needs Bluetooth + Location + NearbyWifi.
    // On Android 12+, BLUETOOTH_SCAN/ADVERTISE/CONNECT are separate grants.
    // On Android <=11, the legacy BLUETOOTH permission covers it.
    final statuses = await [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.nearbyWifiDevices,
      Permission.microphone, // audio calls
      Permission.camera, // video calls (future)
    ].request();

    final denied = statuses.values.any(
      (s) => s == PermissionStatus.permanentlyDenied,
    );

    if (denied && mounted) {
      _showPermissionDialog();
      return;
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.divider),
        ),
        title: Text(
          'PERMISSIONS NEEDED',
          style: GoogleFonts.orbitron(
            color: AppTheme.accent,
            fontSize: 12,
            letterSpacing: 2,
          ),
        ),
        content: Text(
          'STRANGER needs Bluetooth and Location permission to discover nearby peers without internet or a router.\n\nNo location data is ever collected or stored.',
          style: GoogleFonts.spaceMono(
            color: AppTheme.textSecondary,
            fontSize: 11,
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('SKIP',
                style: GoogleFonts.orbitron(
                    color: AppTheme.textMuted, fontSize: 11)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGlow,
              foregroundColor: AppTheme.accent,
            ),
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('OPEN SETTINGS',
                style: GoogleFonts.orbitron(
                    fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          // Background grid
          Positioned.fill(child: _GridBackground()),

          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),

                  // Logo mark
                  _buildLogo(),

                  const SizedBox(height: 48),

                  // Boot log
                  _buildBootLog(),

                  const Spacer(flex: 3),

                  // CTA
                  if (_ready) _buildEnterButton(),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Glitch mark
        Stack(
          children: [
            Text(
              'STR',
              style: GoogleFonts.orbitron(
                color: AppTheme.accent.withValues(alpha: 0.15),
                fontSize: 72,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                height: 1,
              ),
            )
                .animate(onPlay: (c) => c.repeat(period: 4.seconds))
                .then(delay: 2.seconds)
                .shimmer(
                  duration: 200.ms,
                  color: AppTheme.stranger.withValues(alpha: 0.6),
                ),
            Text(
              'STR',
              style: GoogleFonts.orbitron(
                color: AppTheme.accent,
                fontSize: 72,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                height: 1,
              ),
            ),
          ],
        ).animate().fadeIn(duration: 600.ms).slideY(
            begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut),

        Text(
          'ANGER',
          style: GoogleFonts.orbitron(
            color: AppTheme.stranger,
            fontSize: 72,
            fontWeight: FontWeight.w900,
            letterSpacing: -2,
            height: 0.85,
          ),
        ).animate().fadeIn(duration: 600.ms, delay: 150.ms).slideY(
            begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut),

        const SizedBox(height: 16),

        Text(
          'OFFLINE · ANONYMOUS · P2P',
          style: GoogleFonts.spaceMono(
            color: AppTheme.textMuted,
            fontSize: 10,
            letterSpacing: 3,
          ),
        ).animate().fadeIn(duration: 400.ms, delay: 500.ms),
      ],
    );
  }

  Widget _buildBootLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _ready ? AppTheme.accent : AppTheme.stranger,
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat())
                      .fadeIn(duration: 400.ms)
                      .then()
                      .fadeOut(duration: 400.ms),
                  const SizedBox(width: 8),
                  Text(
                    'SYSTEM LOG',
                    style: GoogleFonts.spaceMono(
                      color: AppTheme.textMuted,
                      fontSize: 9,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...List.generate(_lineIndex, (i) {
                final isLast = i == _lineIndex - 1;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(
                        '> ',
                        style: GoogleFonts.spaceMono(
                          color: AppTheme.accent.withValues(alpha: 0.4),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        _bootLines[i],
                        style: GoogleFonts.spaceMono(
                          color: isLast ? AppTheme.accent : AppTheme.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(duration: 200.ms).slideX(
                        begin: -0.05,
                        end: 0,
                        duration: 200.ms,
                      ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnterButton() {
    return GestureDetector(
      onTap: _requestPermissionsAndContinue,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(color: AppTheme.accent, width: 1.5),
          borderRadius: BorderRadius.circular(4),
          color: AppTheme.accentGlow,
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: 0.15),
              blurRadius: 24,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Center(
          child: Text(
            'ENTER THE GRID  →',
            style: GoogleFonts.orbitron(
              color: AppTheme.accent,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }
}

// ─── Grid Background ──────────────────────────────────────────────────────

class _GridBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GridPainter());
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.025)
      ..strokeWidth = 0.5;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Corner accent
    final cornerPaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.15),
      120,
      cornerPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.8),
      80,
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}
