// lib/widgets/radar_scanner.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class RadarScanner extends StatefulWidget {
  final bool isScanning;
  final int peerCount;

  const RadarScanner({
    super.key,
    required this.isScanning,
    required this.peerCount,
  });

  @override
  State<RadarScanner> createState() => _RadarScannerState();
}

class _RadarScannerState extends State<RadarScanner>
    with TickerProviderStateMixin {
  late AnimationController _sweepCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _sweepAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _sweepCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _sweepAnim = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _sweepCtrl, curve: Curves.linear),
    );
    _pulseAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    if (widget.isScanning) _startAnimations();
  }

  @override
  void didUpdateWidget(RadarScanner old) {
    super.didUpdateWidget(old);
    if (widget.isScanning && !old.isScanning) {
      _startAnimations();
    } else if (!widget.isScanning && old.isScanning) {
      _stopAnimations();
    }
  }

  void _startAnimations() {
    _sweepCtrl.repeat();
    _pulseCtrl.repeat(reverse: true);
  }

  void _stopAnimations() {
    _sweepCtrl.stop();
    _pulseCtrl.stop();
  }

  @override
  void dispose() {
    _sweepCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: AnimatedBuilder(
        animation: Listenable.merge([_sweepAnim, _pulseAnim]),
        builder: (context, _) {
          return CustomPaint(
            painter: _RadarPainter(
              sweepAngle: widget.isScanning ? _sweepAnim.value : 0,
              pulse: _pulseAnim.value,
              isScanning: widget.isScanning,
              peerCount: widget.peerCount,
            ),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double sweepAngle;
  final double pulse;
  final bool isScanning;
  final int peerCount;

  static final _rng = Random(42);
  static final List<_BlipPoint> _blips = List.generate(
    8,
    (i) => _BlipPoint(
      angle: _rng.nextDouble() * 2 * pi,
      dist: 0.2 + _rng.nextDouble() * 0.6,
    ),
  );

  _RadarPainter({
    required this.sweepAngle,
    required this.pulse,
    required this.isScanning,
    required this.peerCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // rings
    for (int i = 1; i <= 4; i++) {
      final r = radius * (i / 4);
      final ringPaint = Paint()
        ..color =
            AppTheme.accent.withValues(alpha: 0.08 + (isScanning ? 0.02 : 0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawCircle(center, r * (isScanning ? pulse : 1.0), ringPaint);
    }

    // crosshairs
    final linePaint = Paint()
      ..color = AppTheme.accent.withValues(alpha: 0.12)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(center.dx, center.dy - radius),
        Offset(center.dx, center.dy + radius), linePaint);
    canvas.drawLine(Offset(center.dx - radius, center.dy),
        Offset(center.dx + radius, center.dy), linePaint);

    if (!isScanning) {
      // static center dot
      canvas.drawCircle(
          center, 4, Paint()..color = AppTheme.accent.withValues(alpha: 0.4));
      return;
    }

    // sweep gradient
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          AppTheme.accent.withValues(alpha: 0),
          AppTheme.accent.withValues(alpha: 0.0),
          AppTheme.accent.withValues(alpha: 0.35),
          AppTheme.accent.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.6, 0.95, 1.0],
        startAngle: sweepAngle - 1.2,
        endAngle: sweepAngle + 0.05,
        transform: const GradientRotation(0),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sweepAngle);
    canvas.translate(-center.dx, -center.dy);

    final sweepPath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        pi * 2,
        false,
      );
    canvas.drawPath(sweepPath, sweepPaint);
    canvas.restore();

    // sweep line
    final lineEnd = Offset(
      center.dx + radius * cos(sweepAngle - pi / 2),
      center.dy + radius * sin(sweepAngle - pi / 2),
    );
    canvas.drawLine(
      center,
      lineEnd,
      Paint()
        ..color = AppTheme.accent.withValues(alpha: 0.7)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round,
    );

    // peer blips
    final blipsToShow = _blips.take(peerCount).toList();
    for (final blip in blipsToShow) {
      final angleDiff =
          ((sweepAngle - blip.angle) % (2 * pi) + 2 * pi) % (2 * pi);
      final fade = (1.0 - angleDiff / (2 * pi)).clamp(0.0, 1.0);
      if (fade < 0.05) continue;

      final blipPos = Offset(
        center.dx + radius * blip.dist * cos(blip.angle - pi / 2),
        center.dy + radius * blip.dist * sin(blip.angle - pi / 2),
      );

      canvas.drawCircle(
        blipPos,
        5 * fade,
        Paint()..color = AppTheme.stranger.withValues(alpha: fade * 0.9),
      );
      canvas.drawCircle(
        blipPos,
        10 * fade,
        Paint()
          ..color = AppTheme.stranger.withValues(alpha: fade * 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // center dot
    canvas.drawCircle(
        center,
        5,
        Paint()
          ..color = AppTheme.accent
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawCircle(center, 3, Paint()..color = AppTheme.accent);
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.sweepAngle != sweepAngle ||
      old.pulse != pulse ||
      old.isScanning != isScanning ||
      old.peerCount != peerCount;
}

class _BlipPoint {
  final double angle;
  final double dist;
  _BlipPoint({required this.angle, required this.dist});
}
