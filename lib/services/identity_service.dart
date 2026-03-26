// lib/services/identity_service.dart
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

const _kUserId = 'user_id';
const _kUsername = 'username';

const List<String> _adjectives = [
  'Silent', 'Cosmic', 'Neon', 'Shadow', 'Crystal',
  'Lunar', 'Storm', 'Phantom', 'Velvet', 'Acid',
  'Blazing', 'Frozen', 'Electric', 'Midnight', 'Toxic',
  'Glitch', 'Vapor', 'Hyper', 'Ghost', 'Turbo',
];

const List<String> _nouns = [
  'Fox', 'Wolf', 'Raven', 'Sphinx', 'Viper',
  'Hawk', 'Lynx', 'Drake', 'Nomad', 'Cipher',
  'Specter', 'Comet', 'Nexus', 'Pulse', 'Echo',
  'Drift', 'Wraith', 'Signal', 'Vector', 'Quark',
];

class IdentityService {
  late String _userId;
  late String _username;

  String get userId => _userId;
  String get username => _username;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString(_kUserId) ?? _generateId(prefs);
    _username = prefs.getString(_kUsername) ?? _generateName(prefs);
  }

  String _generateId(SharedPreferences prefs) {
    final id = const Uuid().v4();
    prefs.setString(_kUserId, id);
    return id;
  }

  String _generateName(SharedPreferences prefs) {
    final rng = Random();
    final adj = _adjectives[rng.nextInt(_adjectives.length)];
    final noun = _nouns[rng.nextInt(_nouns.length)];
    final num = 1000 + rng.nextInt(8999);
    final name = '${adj}_${noun}_$num';
    prefs.setString(_kUsername, name);
    return name;
  }

  Future<void> regenerateIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = _generateId(prefs);
    _username = _generateName(prefs);
  }
}
