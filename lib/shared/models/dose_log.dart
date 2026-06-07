// ============================================
// FILE: dose_log.dart
// LAYER: model
// DOMAIN: dose_logging
// ============================================
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

enum DoseStatus { taken, skipped, later, dueNow, overdue, missed }

class DoseLog {
  const DoseLog({
    required this.id,
    required this.slotId,
    required this.scheduleId,
    required this.medicationId,
    required this.status,
    required this.scheduledTime,
    this.loggedAt,
    this.notes,
    required this.userId,
  });

  final String id;
  final String slotId;
  final String scheduleId;
  final String medicationId;
  final DoseStatus status;
  final DateTime scheduledTime;
  final DateTime? loggedAt;
  final String? notes;
  final String userId;

  factory DoseLog.fromMap(Map<String, dynamic> map) {
    return DoseLog(
      id: map['id'] as String,
      slotId: map['slotId'] as String,
      scheduleId: map['scheduleId'] as String,
      medicationId: map['medicationId'] as String,
      status: DoseStatus.values.byName(map['status'] as String),
      scheduledTime: (map['scheduledTime'] as Timestamp).toDate(),
      loggedAt: map['loggedAt'] != null
          ? (map['loggedAt'] as Timestamp).toDate()
          : null,
      notes: map['notes'] as String?,
      userId: map['userId'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'slotId': slotId,
      'scheduleId': scheduleId,
      'medicationId': medicationId,
      'status': status.name,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'loggedAt': loggedAt != null ? Timestamp.fromDate(loggedAt!) : null,
      'notes': notes,
      'userId': userId,
    };
  }
}

// --- Adapters ---

class DoseStatusAdapter extends TypeAdapter<DoseStatus> {
  @override
  final int typeId = 3;

  @override
  DoseStatus read(BinaryReader reader) {
    return DoseStatus.values.byName(reader.readString());
  }

  @override
  void write(BinaryWriter writer, DoseStatus obj) {
    writer.writeString(obj.name);
  }
}

class DoseLogAdapter extends TypeAdapter<DoseLog> {
  @override
  final int typeId = 4;

  @override
  DoseLog read(BinaryReader reader) {
    return DoseLog(
      id: reader.readString(),
      slotId: reader.readString(),
      scheduleId: reader.readString(),
      medicationId: reader.readString(),
      status: DoseStatus.values.byName(reader.readString()),
      scheduledTime: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      loggedAt: reader.readBool()
          ? DateTime.fromMillisecondsSinceEpoch(reader.readInt())
          : null,
      notes: reader.readBool() ? reader.readString() : null,
      userId: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, DoseLog obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.slotId);
    writer.writeString(obj.scheduleId);
    writer.writeString(obj.medicationId);
    writer.writeString(obj.status.name);
    writer.writeInt(obj.scheduledTime.millisecondsSinceEpoch);
    writer.writeBool(obj.loggedAt != null);
    if (obj.loggedAt != null)
      writer.writeInt(obj.loggedAt!.millisecondsSinceEpoch);
    writer.writeBool(obj.notes != null);
    if (obj.notes != null) writer.writeString(obj.notes!);
    writer.writeString(obj.userId);
  }
}
