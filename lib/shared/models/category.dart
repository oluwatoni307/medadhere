// ============================================
// FILE: category.dart
// LAYER: model
// DOMAIN: medications
// ============================================
import 'package:hive/hive.dart';

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.color,
    required this.userId,
  });

  final String id;
  final String name;
  final String color;
  final String userId;

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      color: map['color'] as String,
      userId: map['userId'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'color': color, 'userId': userId};
  }
}

class CategoryAdapter extends TypeAdapter<Category> {
  @override
  final int typeId = 2; // must match your original @HiveType(typeId: 2)

  @override
  Category read(BinaryReader reader) {
    return Category(
      id: reader.readString(),
      name: reader.readString(),
      color: reader.readString(),
      userId: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, Category obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.color);
    writer.writeString(obj.userId);
  }
}
