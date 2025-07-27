// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserStatusAdapter extends TypeAdapter<UserStatus> {
  @override
  final int typeId = 2;

  @override
  UserStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return UserStatus.online;
      case 1:
        return UserStatus.offline;
      case 2:
        return UserStatus.away;
      case 3:
        return UserStatus.busy;
      default:
        return UserStatus.online;
    }
  }

  @override
  void write(BinaryWriter writer, UserStatus obj) {
    switch (obj) {
      case UserStatus.online:
        writer.writeByte(0);
        break;
      case UserStatus.offline:
        writer.writeByte(1);
        break;
      case UserStatus.away:
        writer.writeByte(2);
        break;
      case UserStatus.busy:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
