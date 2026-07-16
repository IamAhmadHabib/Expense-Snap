import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CategoryUtils {
  const CategoryUtils._();

  static String group(String category) {
    final value = category.trim().toLowerCase();
    if (value == 'dining' ||
        value == 'food' ||
        value == 'food & dining' ||
        value == 'restaurant' ||
        value == 'restaurants') {
      return 'Food';
    }
    if (value == 'transport' || value == 'travel & transport') {
      return 'Transport';
    }
    if (value == 'health' || value == 'medical' || value == 'medicine') {
      return 'Health';
    }
    if (value == 'shopping' || value == 'shop') {
      return 'Shopping';
    }
    if (value == 'travel') {
      return 'Travel';
    }
    if (value == 'income') {
      return 'Income';
    }
    return category.trim().isEmpty ? 'Other' : category.trim();
  }

  static bool matchesFilter(String category, String filter) {
    if (filter == 'All') return true;
    return group(category).toLowerCase() == filter.trim().toLowerCase();
  }

  static IconData icon(String category) {
    switch (group(category)) {
      case 'Food':
        return PhosphorIcons.hamburger();
      case 'Transport':
        return PhosphorIcons.car();
      case 'Shopping':
        return PhosphorIcons.shoppingBag();
      case 'Health':
        return PhosphorIcons.firstAid();
      case 'Travel':
        return PhosphorIcons.airplane();
      case 'Income':
        return PhosphorIcons.trendUp();
      default:
        return PhosphorIcons.dotsThree();
    }
  }
}
