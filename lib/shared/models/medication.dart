// ============================================
// FILE: medication.dart
// LAYER: model
// DOMAIN: medications
// ============================================
import 'package:hive/hive.dart';

class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    this.categoryId,
    this.frequency = 'Once daily',
    required this.times,
    this.notes,
    this.purpose,
    required this.userId,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String dosage;
  final String? categoryId;
  final String frequency;
  final List<String> times;
  final String? notes;
  final String? purpose;
  final String userId;
  final DateTime createdAt;

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? categoryId,
    String? frequency,
    List<String>? times,
    String? notes,
    String? purpose,
    String? userId,
    DateTime? createdAt,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      times: times ?? this.times,
      notes: notes ?? this.notes,
      purpose: purpose ?? this.purpose,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as String,
      name: map['name'] as String,
      dosage: map['dosage'] as String,
      categoryId: map['categoryId'] as String?,
      frequency: map['frequency'] as String? ?? 'Once daily',
      times: (map['times'] as List<dynamic>).cast<String>(),
      notes: map['notes'] as String?,
      purpose: map['purpose'] as String?,
      userId: map['userId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'categoryId': categoryId,
      'frequency': frequency,
      'times': times,
      'notes': notes,
      'purpose': purpose,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class MedicationAdapter extends TypeAdapter<Medication> {
  @override
  final int typeId = 1; // pick a unique typeId not used elsewhere

  @override
  Medication read(BinaryReader reader) {
    return Medication(
      id: reader.readString(),
      name: reader.readString(),
      dosage: reader.readString(),
      categoryId: reader.readBool() ? reader.readString() : null,
      frequency: reader.readString(),
      times: reader.readStringList(),
      notes: reader.readBool() ? reader.readString() : null,
      purpose: reader.readBool() ? reader.readString() : null,
      userId: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, Medication obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.dosage);
    // nullable categoryId
    writer.writeBool(obj.categoryId != null);
    if (obj.categoryId != null) writer.writeString(obj.categoryId!);
    writer.writeString(obj.frequency);
    writer.writeStringList(obj.times);
    // nullable notes
    writer.writeBool(obj.notes != null);
    if (obj.notes != null) writer.writeString(obj.notes!);
    // nullable purpose
    writer.writeBool(obj.purpose != null);
    if (obj.purpose != null) writer.writeString(obj.purpose!);
    writer.writeString(obj.userId);
    writer.writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}
