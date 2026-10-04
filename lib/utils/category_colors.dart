import 'package:flutter/material.dart';

class CategoryColors {
  // A predefined mapping of common categories to specific, consistent colors.
  static final Map<String, Color> _categoryColorMap = {
    'Food': const Color(0xFFFF9800), // Orange
    'Food/Dining': const Color(0xFFFF9800),
    'Groceries': const Color(0xFF4CAF50), // Green
    'Transport': const Color(0xFF2196F3), // Blue
    'Transfer': const Color(0xFF9C27B0), // Purple
    'Shopping': const Color(0xFFE91E63), // Pink
    'Entertainment': const Color(0xFFFF5252), // Red Accent
    'Utilities': const Color(0xFF00BCD4), // Cyan
    'Health': const Color(0xFFF44336), // Red
    'Education': const Color(0xFF3F51B5), // Indigo
    'Housing': const Color(0xFF795548), // Brown
    'Other': const Color(0xFF9E9E9E), // Grey
    'Unknown': const Color(0xFFB0BEC5), // Blue Grey
  };

  // Fallback palette for dynamically generated or unknown categories.
  static final List<Color> _fallbackPalette = [
    Colors.teal,
    Colors.amber,
    Colors.deepOrange,
    Colors.lightBlue,
    Colors.lime,
    Colors.indigoAccent,
  ];

  static Color getColorForCategory(String category) {
    // Exact match or standard alias matching
    for (var key in _categoryColorMap.keys) {
      if (category.toLowerCase().contains(key.toLowerCase())) {
        return _categoryColorMap[key]!;
      }
    }

    // Fallback: Generate a consistent color based on the string hash
    final int hash = category.hashCode;
    final int index = hash.abs() % _fallbackPalette.length;
    return _fallbackPalette[index];
  }
}
