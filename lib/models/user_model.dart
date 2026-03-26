// lib/models/user_model.dart
import 'package:hive_flutter/hive_flutter.dart';

part 'user_model.g.dart';

@HiveType(typeId: 0)
class UserModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String ip;

  @HiveField(3)
  final int port;

  @HiveField(4)
  ConnectionStatus status;

  @HiveField(5)
  final int discoveredAt;

  UserModel({
    required this.id,
    required this.name,
    this.ip = '',
    this.port = 0,
    this.status = ConnectionStatus.discovered,
    int? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now().millisecondsSinceEpoch;

  UserModel copyWith({
    String? id,
    String? name,
    String? ip,
    int? port,
    ConnectionStatus? status,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      status: status ?? this.status,
      discoveredAt: discoveredAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'ip': ip,
        'port': port,
        'discoveredAt': discoveredAt,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        ip: (json['ip'] as String?) ?? '',
        port: (json['port'] as int?) ?? 0,
        discoveredAt: (json['discoveredAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      );
}

@HiveType(typeId: 1)
enum ConnectionStatus {
  @HiveField(0)
  discovered,

  @HiveField(1)
  connecting,

  @HiveField(2)
  connected,

  @HiveField(3)
  disconnected,

  @HiveField(4)
  blocked,
}
