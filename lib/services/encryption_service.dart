// lib/services/encryption_service.dart
//
// E2E Encryption: X25519 Diffie-Hellman key exchange + AES-256-GCM
//
// Flow per session:
//   1. On connect, both devices generate a fresh X25519 keypair
//   2. Each sends their public key to the other via a "key_exchange" packet
//   3. Both derive the same shared secret using ECDH (never transmitted)
//   4. Shared secret → HKDF → 256-bit AES-GCM key
//   5. Every message payload is AES-256-GCM encrypted with a random 12-byte nonce
//   6. Nonce is prepended to ciphertext and sent as base64
//   7. Keys are ephemeral — not stored anywhere, lost when session ends
//
// Properties:
//   • Perfect forward secrecy — new keys every session
//   • Even if Nearby's transport layer is compromised, messages stay encrypted
//   • No PKI, no certificates, no servers — pure peer-to-peer key agreement

import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

class SessionCrypto {
  final String endpointId;
  final SimpleKeyPair _myKeyPair;
  SecretKey? _sharedKey;
  bool _ready = false;

  SessionCrypto._(this.endpointId, this._myKeyPair);

  bool get isReady => _ready;

  static Future<SessionCrypto> generate(String endpointId) async {
    final algorithm = X25519();
    final keyPair = await algorithm.newKeyPair();
    return SessionCrypto._(endpointId, keyPair);
  }

  /// Returns our public key as base64 to send to the peer.
  Future<String> getPublicKeyBase64() async {
    final pubKey = await _myKeyPair.extractPublicKey();
    return base64Encode(pubKey.bytes);
  }

  /// Called when we receive the peer's public key.
  /// Derives the shared AES-256-GCM key via ECDH + HKDF.
  Future<void> deriveSharedKey(String peerPublicKeyBase64) async {
    try {
      final algorithm = X25519();
      final peerPubKeyBytes = base64Decode(peerPublicKeyBase64);
      final peerPublicKey = SimplePublicKey(peerPubKeyBytes, type: KeyPairType.x25519);

      // ECDH: shared secret = our_private * peer_public
      final sharedSecret = await algorithm.sharedSecretKey(
        keyPair: _myKeyPair,
        remotePublicKey: peerPublicKey,
      );

      // HKDF to derive a proper 256-bit AES key from the raw shared secret
      final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
      _sharedKey = await hkdf.deriveKey(
        secretKey: sharedSecret,
        info: utf8.encode('stranger-chat-aes-key'),
      );

      _ready = true;
      debugPrint('[Crypto] Shared key derived for $endpointId');
    } catch (e) {
      debugPrint('[Crypto] Key derivation error: $e');
    }
  }

  /// Encrypts plaintext. Returns base64(nonce + ciphertext + mac).
  Future<String?> encrypt(String plaintext) async {
    if (!_ready || _sharedKey == null) return null;
    try {
      final aesGcm = AesGcm.with256bits();
      final nonce = aesGcm.newNonce();
      final secretBox = await aesGcm.encrypt(
        utf8.encode(plaintext),
        secretKey: _sharedKey!,
        nonce: nonce,
      );
      // Pack: nonce (12 bytes) + ciphertext + mac (16 bytes)
      final packed = Uint8List(nonce.length + secretBox.cipherText.length + secretBox.mac.bytes.length);
      packed.setRange(0, nonce.length, nonce);
      packed.setRange(nonce.length, nonce.length + secretBox.cipherText.length, secretBox.cipherText);
      packed.setRange(nonce.length + secretBox.cipherText.length, packed.length, secretBox.mac.bytes);
      return base64Encode(packed);
    } catch (e) {
      debugPrint('[Crypto] Encrypt error: $e');
      return null;
    }
  }

  /// Decrypts a base64(nonce + ciphertext + mac) string. Returns plaintext.
  Future<String?> decrypt(String encryptedBase64) async {
    if (!_ready || _sharedKey == null) return null;
    try {
      final packed = base64Decode(encryptedBase64);
      const nonceLength = 12;
      const macLength = 16;

      final nonce = packed.sublist(0, nonceLength);
      final cipherText = packed.sublist(nonceLength, packed.length - macLength);
      final mac = Mac(packed.sublist(packed.length - macLength));

      final aesGcm = AesGcm.with256bits();
      final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
      final decrypted = await aesGcm.decrypt(secretBox, secretKey: _sharedKey!);
      return utf8.decode(decrypted);
    } catch (e) {
      debugPrint('[Crypto] Decrypt error: $e');
      return null;
    }
  }
}

class EncryptionService {
  // endpointId → SessionCrypto
  final Map<String, SessionCrypto> _sessions = {};

  Future<SessionCrypto> createSession(String endpointId) async {
    final session = await SessionCrypto.generate(endpointId);
    _sessions[endpointId] = session;
    return session;
  }

  SessionCrypto? getSession(String endpointId) => _sessions[endpointId];

  void removeSession(String endpointId) {
    _sessions.remove(endpointId);
    debugPrint('[Crypto] Session removed for $endpointId');
  }

  void clearAll() {
    _sessions.clear();
  }
}
