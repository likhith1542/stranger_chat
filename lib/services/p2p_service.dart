// lib/services/p2p_service.dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import 'identity_service.dart';
import 'encryption_service.dart';

const String _kServiceId = 'dev.stranger.chat';

enum P2PEvent {
  peerDiscovered,
  peerLost,
  connectionRequest,
  peerConnected,
  encryptionReady,
  messageReceived,
  peerTyping,
  peerDisconnected,
}

class P2PEventData {
  final P2PEvent event;
  final dynamic data;
  P2PEventData(this.event, this.data);
}

class P2PService {
  final IdentityService _identity;
  final EncryptionService _encryption = EncryptionService();

  P2PService(this._identity);

  final Set<String> _ownNames = {};
  final Map<String, UserModel> _discoveredPeers = {};
  final Map<String, UserModel> _pendingConnections = {};
  final Map<String, UserModel> _connectedPeers = {};

  // Guard: track which endpointIds have already had acceptConnection called
  // to prevent double-registration of the payload handler.
  final Set<String> _acceptedEndpoints = {};

  final StreamController<P2PEventData> _eventStream =
      StreamController.broadcast();

  Stream<P2PEventData> get events => _eventStream.stream;
  Map<String, UserModel> get discoveredPeers =>
      Map.unmodifiable(_discoveredPeers);

  bool _running = false;

  // ─── Lifecycle ─────────────────────────────────────────────────────────

  Future<void> start() async {
    if (_running) return;
    _running = true;
    await _startAdvertising();
    await _startDiscovery();
    _purgeOwnEndpoints();
    debugPrint('[P2P] Started as ${_identity.username}');
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    await Nearby().stopAllEndpoints();
    await Nearby().stopAdvertising();
    await Nearby().stopDiscovery();
    _discoveredPeers.clear();
    _pendingConnections.clear();
    _connectedPeers.clear();
    _acceptedEndpoints.clear();
    _encryption.clearAll();
    debugPrint('[P2P] Stopped');
  }

  // ─── Advertising / Discovery ───────────────────────────────────────────

  Future<void> _startAdvertising() async {
    try {
      _ownNames.add(_identity.username);
      await Nearby().startAdvertising(
        _identity.username,
        Strategy.P2P_STAR,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _kServiceId,
      );
    } catch (e) {
      debugPrint('[P2P] Advertising error: $e');
    }
  }

  Future<void> _startDiscovery() async {
    try {
      await Nearby().startDiscovery(
        _identity.username,
        Strategy.P2P_STAR,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
        serviceId: _kServiceId,
      );
    } catch (e) {
      debugPrint('[P2P] Discovery error: $e');
    }
  }

  void _purgeOwnEndpoints() {
    final selfKeys = _discoveredPeers.entries
        .where((e) => _ownNames.contains(e.value.name))
        .map((e) => e.key)
        .toList();
    for (final key in selfKeys) {
      final peer = _discoveredPeers.remove(key);
      if (peer != null) _eventStream.add(P2PEventData(P2PEvent.peerLost, peer));
    }
  }

  // ─── Discovery callbacks ───────────────────────────────────────────────

  void _onEndpointFound(
      String endpointId, String endpointName, String serviceId) {
    if (_ownNames.contains(endpointName)) return;
    final peer = UserModel(
      id: endpointId,
      name: endpointName,
      ip: endpointId,
      port: 0,
      status: ConnectionStatus.discovered,
    );
    _discoveredPeers[endpointId] = peer;
    _eventStream.add(P2PEventData(P2PEvent.peerDiscovered, peer));
  }

  void _onEndpointLost(String? endpointId) {
    if (endpointId == null) return;
    final peer = _discoveredPeers.remove(endpointId);
    if (peer != null) _eventStream.add(P2PEventData(P2PEvent.peerLost, peer));
  }

  // ─── Connection callbacks ──────────────────────────────────────────────

  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    debugPrint('[P2P] onConnectionInitiated: ${info.endpointName} '
        'incoming=${info.isIncomingConnection}');

    final peer = UserModel(
      id: endpointId,
      name: info.endpointName,
      ip: endpointId,
      port: 0,
      status: ConnectionStatus.connecting,
    );

    if (info.isIncomingConnection) {
      // RECEIVER: store as pending, let UI decide accept/reject
      _pendingConnections[endpointId] = peer;
      _eventStream.add(P2PEventData(P2PEvent.connectionRequest, peer));
    } else {
      // INITIATOR: auto-accept our own outgoing request.
      // Use the guard to ensure we only register the payload handler ONCE.
      _doAccept(endpointId);
    }
  }

  void _onConnectionResult(String endpointId, Status status) {
    debugPrint('[P2P] onConnectionResult: $endpointId → $status');
    if (status == Status.CONNECTED) {
      final peer = _pendingConnections.remove(endpointId) ??
          _discoveredPeers[endpointId] ??
          UserModel(id: endpointId, name: endpointId, ip: endpointId, port: 0);

      final connected = peer.copyWith(status: ConnectionStatus.connected);
      _connectedPeers[endpointId] = connected;
      _discoveredPeers.remove(endpointId);

      _eventStream.add(P2PEventData(P2PEvent.peerConnected, connected));
      _initiateKeyExchange(endpointId);
    } else {
      _pendingConnections.remove(endpointId);
      _acceptedEndpoints.remove(endpointId);
      _eventStream.add(P2PEventData(P2PEvent.peerDisconnected, endpointId));
    }
  }

  void _onDisconnected(String endpointId) {
    debugPrint('[P2P] onDisconnected: $endpointId');
    _connectedPeers.remove(endpointId);
    _acceptedEndpoints.remove(endpointId);
    _encryption.removeSession(endpointId);
    _eventStream.add(P2PEventData(P2PEvent.peerDisconnected, endpointId));
  }

  /// Single guarded acceptConnection — ensures onPayLoadRecieved is only
  /// registered ONCE per endpoint regardless of how many times Nearby fires
  /// the connection initiation callbacks.
  void _doAccept(String endpointId) {
    if (_acceptedEndpoints.contains(endpointId)) {
      debugPrint(
          '[P2P] acceptConnection already called for $endpointId — skipping duplicate');
      return;
    }
    _acceptedEndpoints.add(endpointId);
    Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: _onPayloadReceived,
      onPayloadTransferUpdate: _onPayloadTransferUpdate,
    );
  }

  // ─── Encryption ────────────────────────────────────────────────────────

  Future<void> _initiateKeyExchange(String endpointId) async {
    final session = await _encryption.createSession(endpointId);
    final pubKeyBase64 = await session.getPublicKeyBase64();
    _sendRawPacket(
        endpointId, {'type': 'key_exchange', 'pubKey': pubKeyBase64});
    debugPrint('[Crypto] Sent public key to $endpointId');
  }

  Future<void> _handleKeyExchange(
      String endpointId, String peerPubKeyBase64) async {
    var session = _encryption.getSession(endpointId);
    if (session == null) {
      session = await _encryption.createSession(endpointId);
      final ourPubKeyBase64 = await session.getPublicKeyBase64();
      _sendRawPacket(
          endpointId, {'type': 'key_exchange', 'pubKey': ourPubKeyBase64});
    }
    await session.deriveSharedKey(peerPubKeyBase64);
    if (session.isReady) {
      debugPrint('[Crypto] Encryption ready with $endpointId');
      _eventStream.add(P2PEventData(P2PEvent.encryptionReady, endpointId));
    }
  }

  // ─── Payload handler ───────────────────────────────────────────────────

  void _onPayloadReceived(String endpointId, Payload payload) async {
    if (payload.type != PayloadType.BYTES) return;
    final bytes = payload.bytes;
    if (bytes == null) return;

    try {
      final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      final type = json['type'] as String;

      switch (type) {
        case 'key_exchange':
          await _handleKeyExchange(endpointId, json['pubKey'] as String);
          break;

        case 'message':
          final encryptedPayload = json['payload'] as String?;
          if (encryptedPayload == null) break;
          final session = _encryption.getSession(endpointId);
          final decrypted =
              session != null ? await session.decrypt(encryptedPayload) : null;
          if (decrypted == null) {
            debugPrint('[Crypto] Failed to decrypt from $endpointId');
            break;
          }
          final msg = MessageModel.fromJson(
              jsonDecode(decrypted) as Map<String, dynamic>);
          _eventStream.add(P2PEventData(P2PEvent.messageReceived, msg));
          _sendRawPacket(endpointId, {'type': 'ack', 'id': msg.id});
          break;

        case 'typing':
          _eventStream.add(P2PEventData(P2PEvent.peerTyping, endpointId));
          break;

        case 'ack':
          break;
      }
    } catch (e) {
      debugPrint('[P2P] Payload parse error: $e');
    }
  }

  void _onPayloadTransferUpdate(
      String endpointId, PayloadTransferUpdate update) {}

  // ─── Public API ────────────────────────────────────────────────────────

  Future<bool> connectToPeer(UserModel peer) async {
    try {
      await Nearby().requestConnection(
        _identity.username,
        peer.id,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
      if (_discoveredPeers.containsKey(peer.id)) {
        _discoveredPeers[peer.id] =
            peer.copyWith(status: ConnectionStatus.connecting);
      }
      return true;
    } catch (e) {
      debugPrint('[P2P] requestConnection error: $e');
      return false;
    }
  }

  /// Called by the receiver when they tap Accept.
  void acceptConnection(String endpointId) => _doAccept(endpointId);

  void rejectConnection(String endpointId) {
    Nearby().rejectConnection(endpointId);
    _pendingConnections.remove(endpointId);
    _acceptedEndpoints.remove(endpointId);
  }

  Future<bool> sendMessage(String endpointId, MessageModel message) async {
    final session = _encryption.getSession(endpointId);
    if (session == null || !session.isReady) {
      debugPrint('[P2P] Cannot send — encryption not ready');
      return false;
    }
    final encrypted = await session.encrypt(jsonEncode(message.toJson()));
    if (encrypted == null) return false;
    return _sendRawPacket(
        endpointId, {'type': 'message', 'payload': encrypted});
  }

  void sendTyping(String endpointId) =>
      _sendRawPacket(endpointId, {'type': 'typing'});

  void disconnectFromPeer(String endpointId) {
    Nearby().disconnectFromEndpoint(endpointId);
    _acceptedEndpoints.remove(endpointId);
    _encryption.removeSession(endpointId);
    _connectedPeers.remove(endpointId);
  }

  bool isEncryptionReady(String endpointId) =>
      _encryption.getSession(endpointId)?.isReady ?? false;

  bool _sendRawPacket(String endpointId, Map<String, dynamic> data) {
    try {
      Nearby().sendBytesPayload(
          endpointId, Uint8List.fromList(utf8.encode(jsonEncode(data))));
      return true;
    } catch (e) {
      debugPrint('[P2P] send error: $e');
      return false;
    }
  }
}
