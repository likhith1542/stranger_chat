// lib/models/user_model.g.dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 0;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      id: fields[0] as String,
      name: fields[1] as String,
      ip: fields[2] as String,
      port: fields[3] as int,
      status: fields[4] as ConnectionStatus,
      discoveredAt: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.ip)
      ..writeByte(3)
      ..write(obj.port)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.discoveredAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ConnectionStatusAdapter extends TypeAdapter<ConnectionStatus> {
  @override
  final int typeId = 1;

  @override
  ConnectionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ConnectionStatus.discovered;
      case 1:
        return ConnectionStatus.connecting;
      case 2:
        return ConnectionStatus.connected;
      case 3:
        return ConnectionStatus.disconnected;
      case 4:
        return ConnectionStatus.blocked;
      default:
        return ConnectionStatus.discovered;
    }
  }

  @override
  void write(BinaryWriter writer, ConnectionStatus obj) {
    switch (obj) {
      case ConnectionStatus.discovered:
        writer.writeByte(0);
        break;
      case ConnectionStatus.connecting:
        writer.writeByte(1);
        break;
      case ConnectionStatus.connected:
        writer.writeByte(2);
        break;
      case ConnectionStatus.disconnected:
        writer.writeByte(3);
        break;
      case ConnectionStatus.blocked:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
