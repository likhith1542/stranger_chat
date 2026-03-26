// lib/screens/home_screen.dart  (final version)
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';
import '../providers/app_providers.dart';
import '../utils/app_theme.dart';
import '../widgets/connection_overlay.dart';
import '../widgets/interest_tags.dart';
import '../widgets/peer_card.dart';
import '../widgets/radar_scanner.dart';
import 'chat_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _showOverlay = false;
  UserModel? _connectingTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenForRequests();
    });
  }

  void _listenForRequests() {
    ref.listenManual(connectionRequestProvider, (prev, next) {
      if (next.isNotEmpty && (prev?.isEmpty ?? true)) {
        _showConnectionRequestDialog(next.first);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanning = ref.watch(scanningProvider);
    final identity = ref.watch(identityStateProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(identity),
              SliverToBoxAdapter(child: _buildRadarSection(scanning)),
              SliverToBoxAdapter(child: _buildSectionHeader(scanning)),
              if (scanning.peers.isEmpty)
                SliverToBoxAdapter(child: _buildEmptyState(scanning.status))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final peer = scanning.peers[i];
                      final isBlocked =
                          ref.watch(blockedUsersProvider).contains(peer.id);
                      if (isBlocked) return const SizedBox.shrink();
                      return PeerCard(
                        peer: peer,
                        index: i,
                        onTap: () => _onPeerTap(peer),
                      );
                    },
                    childCount: scanning.peers.length,
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          if (_showOverlay && _connectingTo != null)
            ConnectionOverlay(
              peer: _connectingTo!,
              onCancel: () {
                setState(() {
                  _showOverlay = false;
                  _connectingTo = null;
                });
                ref.read(activeConnectionProvider.notifier).disconnect();
              },
            ),
        ],
      ),
      floatingActionButton: _buildFab(scanning.status),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildAppBar(AsyncValue<String> identity) {
    return SliverAppBar(
      backgroundColor: AppTheme.bg,
      pinned: true,
      title: Row(
        children: [
          _buildStatusDot(),
          const SizedBox(width: 10),
          Text(
            'STRANGER',
            style: GoogleFonts.orbitron(
              color: AppTheme.accent,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 4,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tag, color: AppTheme.textSecondary, size: 19),
          tooltip: 'Interests',
          onPressed: _showInterestTags,
        ),
        IconButton(
          icon: const Icon(Icons.person_outline,
              color: AppTheme.textSecondary, size: 19),
          tooltip: 'New identity',
          onPressed: () => _regenerate(identity),
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppTheme.divider),
      ),
    );
  }

  Widget _buildStatusDot() {
    final scanning = ref.watch(scanningProvider);
    final isScanning = scanning.status == ScanningStatus.scanning;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isScanning ? AppTheme.accent : AppTheme.textMuted,
        boxShadow: isScanning
            ? [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                )
              ]
            : [],
      ),
    );
  }

  Widget _buildRadarSection(ScanningState scanning) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          RadarScanner(
            isScanning: scanning.status == ScanningStatus.scanning,
            peerCount: scanning.peers.length,
          ),
          const SizedBox(height: 16),
          _buildIdentityBadge(),
        ],
      ),
    );
  }

  Widget _buildIdentityBadge() {
    final identity = ref.watch(identityStateProvider);
    return identity.when(
      data: (name) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_outlined,
                color: AppTheme.textMuted, size: 12),
            const SizedBox(width: 6),
            Text(
              name,
              style: GoogleFonts.spaceMono(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ).animate().fadeIn(),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSectionHeader(ScanningState scanning) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: [
          Text(
            'NEARBY',
            style: GoogleFonts.orbitron(
              color: AppTheme.textMuted,
              fontSize: 9,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(width: 8),
          if (scanning.peers.isNotEmpty)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(scanning.peers.length),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.stranger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${scanning.peers.length}',
                  style: GoogleFonts.orbitron(
                    color: AppTheme.stranger,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          const Spacer(),
          if (scanning.status == ScanningStatus.scanning)
            Text(
              'LIVE',
              style: GoogleFonts.orbitron(
                color: AppTheme.accent,
                fontSize: 9,
                letterSpacing: 2,
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .fadeIn(duration: 700.ms)
                .then()
                .fadeOut(duration: 700.ms),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ScanningStatus status) {
    final isScanning = status == ScanningStatus.scanning;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        children: [
          Icon(
            isScanning ? Icons.sensors : Icons.sensors_off,
            color: AppTheme.textMuted,
            size: 36,
          ),
          const SizedBox(height: 16),
          Text(
            isScanning ? 'Scanning...' : 'No active scan',
            style: GoogleFonts.orbitron(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isScanning
                ? 'Waiting for nearby devices.\nMake sure others are on the same WiFi with STRANGER open.'
                : 'Tap SCAN to start discovering nearby strangers.',
            style: GoogleFonts.spaceMono(
              color: AppTheme.textMuted,
              fontSize: 11,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFab(ScanningStatus status) {
    final isScanning = status == ScanningStatus.scanning;
    return GestureDetector(
      onTap: () {
        if (isScanning) {
          ref.read(scanningProvider.notifier).stopScanning();
        } else {
          ref.read(scanningProvider.notifier).startScanning();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        decoration: BoxDecoration(
          color: isScanning ? AppTheme.surface : AppTheme.accent,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isScanning ? AppTheme.accent : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withValues(alpha: isScanning ? 0.15 : 0.4),
              blurRadius: 24,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isScanning ? Icons.stop_rounded : Icons.radar_rounded,
              color: isScanning ? AppTheme.accent : AppTheme.bg,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              isScanning ? 'STOP' : 'SCAN',
              style: GoogleFonts.orbitron(
                color: isScanning ? AppTheme.accent : AppTheme.bg,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onPeerTap(UserModel peer) async {
    setState(() {
      _showOverlay = true;
      _connectingTo = peer;
    });

    final ok =
        await ref.read(activeConnectionProvider.notifier).connectTo(peer);

    if (!mounted) return;
    setState(() => _showOverlay = false);

    if (ok) {
      final conn = ref.read(activeConnectionProvider);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            peer: peer,
            sessionId: conn.sessionId!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not reach ${peer.name}',
            style: GoogleFonts.spaceMono(fontSize: 12),
          ),
          backgroundColor: AppTheme.surfaceHigh,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showConnectionRequestDialog(UserModel peer) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ConnectionRequestDialog(
        peer: peer,
        onAccept: () {
          ref.read(connectionRequestProvider.notifier).removeRequest(peer.id);
          ref.read(activeConnectionProvider.notifier).onPeerAccepted(peer);
          Navigator.pop(context);
          final conn = ref.read(activeConnectionProvider);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                peer: peer,
                sessionId: conn.sessionId!,
              ),
            ),
          );
        },
        onReject: () {
          ref.read(connectionRequestProvider.notifier).removeRequest(peer.id);
          ref.read(p2pServiceProvider).rejectConnection(peer.id);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showInterestTags() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const InterestTagsSheet(),
    );
  }

  void _regenerate(AsyncValue<String> identity) async {
    await ref.read(identityStateProvider.notifier).regenerate();
    // Restart Nearby advertising with the new identity name so the old
    // BLE endpoint disappears from neighbor lists and no duplicates appear.
    await ref.read(scanningProvider.notifier).restartIfScanning();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New identity generated  ✓',
              style: GoogleFonts.spaceMono(fontSize: 12)),
          backgroundColor: AppTheme.surfaceHigh,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}

// ─── Connection Request Dialog ─────────────────────────────────────────────

class _ConnectionRequestDialog extends StatelessWidget {
  final UserModel peer;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _ConnectionRequestDialog({
    required this.peer,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: AppTheme.accent.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.06), blurRadius: 48)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.stranger.withValues(alpha: 0.1),
                border: Border.all(
                    color: AppTheme.stranger.withValues(alpha: 0.4),
                    width: 1.5),
              ),
              child: Center(
                child: Text(
                  peer.name.substring(0, 2).toUpperCase(),
                  style: GoogleFonts.orbitron(
                    color: AppTheme.stranger,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ).animate().scale(
                begin: const Offset(0.7, 0.7),
                duration: 350.ms,
                curve: Curves.elasticOut),
            const SizedBox(height: 20),
            Text(
              'INCOMING',
              style: GoogleFonts.orbitron(
                color: AppTheme.textMuted,
                fontSize: 9,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              peer.name,
              style: GoogleFonts.orbitron(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'wants to chat anonymously',
              style: GoogleFonts.spaceMono(
                  color: AppTheme.textMuted, fontSize: 11),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textMuted,
                      side: const BorderSide(color: AppTheme.divider),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('IGNORE',
                        style: GoogleFonts.orbitron(
                            fontSize: 11, letterSpacing: 1)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                      foregroundColor: AppTheme.bg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: Text('ACCEPT',
                        style: GoogleFonts.orbitron(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).scale(
        begin: const Offset(0.92, 0.92),
        duration: 300.ms,
        curve: Curves.easeOut);
  }
}
