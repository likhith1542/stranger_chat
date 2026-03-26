// lib/providers/app_providers.dart
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../services/encryption_service.dart';
import '../models/message_model.dart';
import '../services/identity_service.dart';
import '../services/p2p_service.dart';
import '../services/storage_service.dart';

// ─── Core Services ────────────────────────────────────────────────────────

final identityProvider = Provider<IdentityService>((ref) => IdentityService());

final storageProvider = Provider<StorageService>((ref) => StorageService());

final p2pServiceProvider = Provider<P2PService>((ref) {
  final identity = ref.watch(identityProvider);
  return P2PService(identity);
});

// ─── Identity State ───────────────────────────────────────────────────────

final identityStateProvider =
    StateNotifierProvider<IdentityNotifier, AsyncValue<String>>((ref) {
  return IdentityNotifier(ref.watch(identityProvider));
});

class IdentityNotifier extends StateNotifier<AsyncValue<String>> {
  final IdentityService _identity;
  final Completer<void> _initCompleter = Completer<void>();

  IdentityNotifier(this._identity) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    await _identity.initialize();
    state = AsyncValue.data(_identity.username);
    if (!_initCompleter.isCompleted) _initCompleter.complete();
  }

  /// Awaitable by the splash screen — resolves once identity is ready.
  Future<void> ensureInitialized() => _initCompleter.future;

  Future<void> regenerate() async {
    await _identity.regenerateIdentity();
    state = AsyncValue.data(_identity.username);
  }

  String get username => _identity.username;
  String get userId => _identity.userId;
}

// ─── Scanning State ───────────────────────────────────────────────────────

enum ScanningStatus { idle, scanning, error }

class ScanningState {
  final ScanningStatus status;
  final List<UserModel> peers;
  final String? error;

  const ScanningState({
    this.status = ScanningStatus.idle,
    this.peers = const [],
    this.error,
  });

  ScanningState copyWith({
    ScanningStatus? status,
    List<UserModel>? peers,
    String? error,
  }) {
    return ScanningState(
      status: status ?? this.status,
      peers: peers ?? this.peers,
      error: error,
    );
  }
}

final scanningProvider =
    StateNotifierProvider<ScanningNotifier, ScanningState>((ref) {
  return ScanningNotifier(ref.watch(p2pServiceProvider), ref);
});

class ScanningNotifier extends StateNotifier<ScanningState> {
  final P2PService _p2p;
  final Ref _ref;
  StreamSubscription? _sub;

  ScanningNotifier(this._p2p, this._ref) : super(const ScanningState());

  Future<void> startScanning() async {
    state = state.copyWith(status: ScanningStatus.scanning);

    await _p2p.start();

    _sub = _p2p.events.listen((event) {
      if (event.event == P2PEvent.peerDiscovered ||
          event.event == P2PEvent.peerLost) {
        state = state.copyWith(
          peers: _p2p.discoveredPeers.values.toList(),
        );
      } else if (event.event == P2PEvent.connectionRequest) {
        _ref
            .read(connectionRequestProvider.notifier)
            .addRequest(event.data as UserModel);
      } else if (event.event == P2PEvent.messageReceived) {
        final msg = event.data as MessageModel;
        // Route to the active session. The sessionId in the message is the
        // symmetric key (sorted userId pair) set by the sender — it matches
        // the receiver's active sessionId since both use the same algorithm.
        final activeSessionId = _ref.read(activeConnectionProvider).sessionId;
        final targetSessionId = activeSessionId ?? msg.sessionId;
        // Rewrite sessionId only if needed (no-op when they already match)
        final routedMsg = msg.sessionId == targetSessionId
            ? msg
            : MessageModel(
                id: msg.id,
                sessionId: targetSessionId,
                senderId: msg.senderId,
                content: msg.content,
                timestamp: msg.timestamp,
                type: msg.type,
                status: msg.status,
              );
        _ref
            .read(chatProvider(targetSessionId).notifier)
            .addIncoming(routedMsg);
      } else if (event.event == P2PEvent.peerTyping) {
        final peerId = event.data as String;
        // Reset the typing indicator using the peer's endpointId as key
        _ref.read(typingProvider(peerId).notifier).state = true;
      } else if (event.event == P2PEvent.peerConnected) {
        final peer = event.data as UserModel;
        _ref.read(activeConnectionProvider.notifier).onPeerConnected(peer.id);
      } else if (event.event == P2PEvent.encryptionReady) {
        final endpointId = event.data as String;
        _ref.read(encryptionReadyProvider(endpointId).notifier).state = true;
      } else if (event.event == P2PEvent.peerDisconnected) {
        final peerId = event.data as String;
        // Auto-delete chat history on disconnect
        final sessionId = _ref.read(activeConnectionProvider).sessionId;
        if (sessionId != null) {
          _ref.read(chatProvider(sessionId).notifier).clearChat();
        }
        _ref.read(activeConnectionProvider.notifier).onPeerDisconnected(peerId);
      }
    });
  }

  Future<void> stopScanning() async {
    await _sub?.cancel();
    await _p2p.stop();
    state = const ScanningState();
  }

  /// Called after identity regeneration — restarts advertising with the new name
  /// so the old endpoint disappears from neighbor lists and a fresh one appears.
  Future<void> restartIfScanning() async {
    if (state.status != ScanningStatus.scanning) return;
    await stopScanning();
    await Future.delayed(const Duration(milliseconds: 500));
    await startScanning();
  }
}

// ─── Connection Requests ──────────────────────────────────────────────────

final connectionRequestProvider =
    StateNotifierProvider<ConnectionRequestNotifier, List<UserModel>>((ref) {
  return ConnectionRequestNotifier();
});

class ConnectionRequestNotifier extends StateNotifier<List<UserModel>> {
  ConnectionRequestNotifier() : super([]);

  void addRequest(UserModel peer) {
    state = [...state, peer];
  }

  void removeRequest(String peerId) {
    state = state.where((p) => p.id != peerId).toList();
  }
}

// ─── Active Connection ────────────────────────────────────────────────────

class ActiveConnection {
  final UserModel? peer;
  final String? sessionId;
  final ConnectionStatus status;

  const ActiveConnection({
    this.peer,
    this.sessionId,
    this.status = ConnectionStatus.discovered,
  });

  ActiveConnection copyWith({
    UserModel? peer,
    String? sessionId,
    ConnectionStatus? status,
  }) {
    return ActiveConnection(
      peer: peer ?? this.peer,
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
    );
  }
}

final activeConnectionProvider =
    StateNotifierProvider<ActiveConnectionNotifier, ActiveConnection>((ref) {
  return ActiveConnectionNotifier(
      ref.watch(p2pServiceProvider), ref.watch(identityProvider), ref);
});

class ActiveConnectionNotifier extends StateNotifier<ActiveConnection> {
  final P2PService _p2p;
  final IdentityService _identity;
  final Ref _ref;

  ActiveConnectionNotifier(this._p2p, this._identity, this._ref)
      : super(const ActiveConnection());

  Completer<bool>? _connectCompleter;

  Future<bool> connectTo(UserModel peer) async {
    _connectCompleter = Completer<bool>();

    state = ActiveConnection(
      peer: peer,
      sessionId: _makeSessionId(peer.id),
      status: ConnectionStatus.connecting,
    );

    final ok = await _p2p.connectToPeer(peer);
    if (!ok) {
      state = state.copyWith(status: ConnectionStatus.disconnected);
      _connectCompleter?.complete(false);
      _connectCompleter = null;
      return false;
    }

    // Wait for Nearby to confirm the connection (onConnectionResult SUCCESS)
    // with a 10-second timeout.
    try {
      return await _connectCompleter!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          state = state.copyWith(status: ConnectionStatus.disconnected);
          return false;
        },
      );
    } finally {
      _connectCompleter = null;
    }
  }

  /// Called by ScanningNotifier when Nearby reports CONNECTED status.
  void onPeerConnected(String endpointId) {
    if (state.peer?.id == endpointId) {
      state = state.copyWith(status: ConnectionStatus.connected);
      _connectCompleter?.complete(true);
    }
  }

  void onPeerAccepted(UserModel peer) {
    _p2p.acceptConnection(peer.id);
    state = ActiveConnection(
      peer: peer,
      sessionId: _makeSessionId(peer.id),
      status: ConnectionStatus.connected,
    );
  }

  void onPeerDisconnected(String peerId) {
    if (state.peer?.id == peerId) {
      state = state.copyWith(status: ConnectionStatus.disconnected);
    }
  }

  void disconnect() {
    final peerId = state.peer?.id;
    final sessionId = state.sessionId;
    // Clear chat history on the INITIATING side before resetting state.
    // The remote side clears when it receives the peerDisconnected event.
    if (sessionId != null) {
      _ref.read(chatProvider(sessionId).notifier).clearChat();
    }
    if (peerId != null) {
      _p2p.disconnectFromPeer(peerId);
    }
    state = const ActiveConnection();
  }

  String _makeSessionId(String peerId) {
    // Sort both IDs so the session key is identical on both devices
    // regardless of who initiated the connection.
    final ids = [_identity.userId, peerId]..sort();
    return 'session_${ids[0]}_${ids[1]}';
  }
}

// ─── Chat ─────────────────────────────────────────────────────────────────

final chatProvider =
    StateNotifierProvider.family<ChatNotifier, List<MessageModel>, String>(
        (ref, sessionId) {
  return ChatNotifier(
    sessionId,
    ref.watch(p2pServiceProvider),
    ref.watch(storageProvider),
    ref.watch(identityProvider),
    ref.watch(activeConnectionProvider).peer?.id ?? '',
  );
});

class ChatNotifier extends StateNotifier<List<MessageModel>> {
  final String sessionId;
  final P2PService _p2p;
  final StorageService _storage;
  final IdentityService _identity;
  final String _peerId;

  ChatNotifier(
      this.sessionId, this._p2p, this._storage, this._identity, this._peerId)
      : super([]) {
    _loadHistory();
  }

  void _loadHistory() {
    final msgs = _storage.getMessagesForSession(sessionId);
    state = msgs;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final msg = MessageModel(
      id: const Uuid().v4(),
      sessionId: sessionId,
      senderId:
          _identity.userId, // real ID so receiver can tell it's not theirs
      content: text.trim(),
      status: MessageStatus.sending,
    );

    state = [...state, msg];
    await _storage.saveMessage(msg);

    final sent = await _p2p.sendMessage(_peerId, msg);
    final newStatus = sent ? MessageStatus.sent : MessageStatus.failed;

    state = state
        .map((m) => m.id == msg.id ? m.copyWith(status: newStatus) : m)
        .toList();
    await _storage.updateMessageStatus(msg.id, newStatus);
  }

  void addIncoming(MessageModel msg) {
    // Dedup guard — Nearby can deliver the same payload twice on some devices
    if (state.any((m) => m.id == msg.id)) return;
    state = [...state, msg];
    _storage.saveMessage(msg);
  }

  void sendTyping() {
    _p2p.sendTyping(_peerId);
  }

  Future<void> clearChat() async {
    await _storage.deleteSession(sessionId);
    state = [];
  }
}

// ─── Typing Indicator ─────────────────────────────────────────────────────

final typingProvider =
    StateNotifierProvider.family<TypingNotifier, bool, String>((ref, peerId) {
  return TypingNotifier();
});

class TypingNotifier extends StateNotifier<bool> {
  Timer? _timer;
  TypingNotifier() : super(false);

  @override
  set state(bool value) {
    super.state = value;
    if (value) {
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 3), () => super.state = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

// ─── Blocked Users ────────────────────────────────────────────────────────

final blockedUsersProvider =
    StateNotifierProvider<BlockedUsersNotifier, Set<String>>((ref) {
  return BlockedUsersNotifier();
});

class BlockedUsersNotifier extends StateNotifier<Set<String>> {
  BlockedUsersNotifier() : super({});

  void block(String userId) => state = {...state, userId};
  void unblock(String userId) =>
      state = state.where((id) => id != userId).toSet();
  bool isBlocked(String userId) => state.contains(userId);
}

// ─── Encryption Ready ─────────────────────────────────────────────────────

/// Per-endpoint flag that flips to true once key exchange completes.
/// Chat UI listens to this before allowing sends.
final encryptionReadyProvider =
    StateProvider.family<bool, String>((ref, endpointId) => false);
