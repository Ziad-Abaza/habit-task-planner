import 'package:hive/hive.dart';
import 'package:flutter/material.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class Category extends HiveObject {
  @HiveField(0)
  late String name;

  @HiveField(1)
  late int colorValue; // Store color as int

  @HiveField(2)
  late int iconCodePoint; // Store icon code point

  @HiveField(3)
  late int sortOrder;

  @HiveField(4, defaultValue: false)
  late bool isDefault; // Default categories can't be deleted

  // Default constructor for Hive
  Category();

  // Named constructor for creating categories
  Category.create({
    required this.name,
    required Color color,
    required IconData icon,
    this.sortOrder = 0,
    this.isDefault = false,
  }) {
    colorValue = color.value;
    iconCodePoint = icon.codePoint;
  }

  // Helper to get Color from colorValue
  Color get color => Color(colorValue);

  // Helper to set Color
  set color(Color value) => colorValue = value.value;

  // Helper to get IconData from iconCodePoint
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  // Helper to set IconData
  set icon(IconData value) => iconCodePoint = value.codePoint;

  // Create a default category
  static Category getDefaultCategory() {
    return Category.create(
      name: 'Default',
      color: const Color(0xFF6C63FF), // Primary purple color
      icon: Icons.category_rounded,
      sortOrder: 0,
      isDefault: true,
    );
  }
}
