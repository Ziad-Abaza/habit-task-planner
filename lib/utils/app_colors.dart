import 'package:flutter/material.dart';

class AppColors {
  // Primary Brand Colors
  static const Color primaryPurple = Color(0xFF6C63FF);
  static const Color primaryPurpleLight = Color(0xFF9D97FF);
  static const Color primaryPurpleDark = Color(0xFF4B42E6);
  
  // Default Category Colors (for fallback)
  static const Color categoryWork = Color(0xFF6C63FF); // Purple
  static const Color categoryPersonal = Color(0xFF00D4FF); // Cyan
  static const Color categoryHealth = Color(0xFF00E676); // Green
  static const Color categoryFinance = Color(0xFFFFAB00); // Amber
  static const Color categorySocial = Color(0xFFFF6B9D); // Pink
  static const Color categoryLearning = Color(0xFF7C4DFF); // Deep Purple
  static const Color categoryHobbies = Color(0xFFFF9100); // Orange
  static const Color categoryOther = Color(0xFF78909C); // Blue Grey
  
  // Priority Colors
  static const Color priorityHigh = Color(0xFFFF5252);
  static const Color priorityMedium = Color(0xFFFFAB00);
  static const Color priorityLow = Color(0xFF00E676);
  
  // Status Colors
  static const Color statusCompleted = Color(0xFF00E676);
  static const Color statusOverdue = Color(0xFFFF5252);
  static const Color statusToday = Color(0xFF6C63FF);
  static const Color statusUpcoming = Color(0xFF78909C);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00E676), Color(0xFF00C853)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFFAB00), Color(0xFFFF6F00)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Background Colors
  static const Color lightBackground = Color(0xFFF8F9FE);
  static const Color darkBackground = Color(0xFF121212);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E);
  
  // Get category color by ID (fallback for backward compatibility)
  static Color getCategoryColor(int categoryId) {
    switch (categoryId) {
      case 0:
        return categoryWork;
      case 1:
        return categoryPersonal;
      case 2:
        return categoryHealth;
      case 3:
        return categoryFinance;
      case 4:
        return categorySocial;
      case 5:
        return categoryLearning;
      case 6:
        return categoryHobbies;
      default:
        return categoryOther;
    }
  }
  
  // Get category name by ID (fallback for backward compatibility)
  static String getCategoryName(int categoryId) {
    switch (categoryId) {
      case 0:
        return 'Work';
      case 1:
        return 'Personal';
      case 2:
        return 'Health';
      case 3:
        return 'Finance';
      case 4:
        return 'Social';
      case 5:
        return 'Learning';
      case 6:
        return 'Hobbies';
      default:
        return 'Other';
    }
  }
  
  // Get category icon by ID (fallback for backward compatibility)
  static IconData getCategoryIcon(int categoryId) {
    switch (categoryId) {
      case 0:
        return Icons.work_rounded;
      case 1:
        return Icons.person_rounded;
      case 2:
        return Icons.favorite_rounded;
      case 3:
        return Icons.account_balance_wallet_rounded;
      case 4:
        return Icons.people_rounded;
      case 5:
        return Icons.school_rounded;
      case 6:
        return Icons.palette_rounded;
      default:
        return Icons.category_rounded;
    }
  }
  
  // Get priority color
  static Color getPriorityColor(int priority) {
    switch (priority) {
      case 2:
        return priorityHigh;
      case 1:
        return priorityMedium;
      default:
        return priorityLow;
    }
  }
}
