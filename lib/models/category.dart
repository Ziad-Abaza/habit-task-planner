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

  // Create default categories
  static List<Category> getDefaultCategories() {
    return [
      Category.create(
        name: 'Work',
        color: const Color(0xFF6C63FF),
        icon: Icons.work_rounded,
        sortOrder: 0,
        isDefault: true,
      ),
      Category.create(
        name: 'Personal',
        color: const Color(0xFF00D4FF),
        icon: Icons.person_rounded,
        sortOrder: 1,
        isDefault: true,
      ),
      Category.create(
        name: 'Health',
        color: const Color(0xFF00E676),
        icon: Icons.favorite_rounded,
        sortOrder: 2,
        isDefault: true,
      ),
      Category.create(
        name: 'Finance',
        color: const Color(0xFFFFAB00),
        icon: Icons.account_balance_wallet_rounded,
        sortOrder: 3,
        isDefault: true,
      ),
      Category.create(
        name: 'Social',
        color: const Color(0xFFFF6B9D),
        icon: Icons.people_rounded,
        sortOrder: 4,
        isDefault: true,
      ),
      Category.create(
        name: 'Learning',
        color: const Color(0xFF7C4DFF),
        icon: Icons.school_rounded,
        sortOrder: 5,
        isDefault: true,
      ),
      Category.create(
        name: 'Hobbies',
        color: const Color(0xFFFF9100),
        icon: Icons.palette_rounded,
        sortOrder: 6,
        isDefault: true,
      ),
      Category.create(
        name: 'Other',
        color: const Color(0xFF78909C),
        icon: Icons.category_rounded,
        sortOrder: 7,
        isDefault: true,
      ),
    ];
  }
}
