import 'package:flutter/widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../theme/app_colors.dart';

class CategoryStyle {
  final Color background;
  final Color foreground;
  final IconData icon;

  const CategoryStyle({
    required this.background,
    required this.foreground,
    required this.icon,
  });
}

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
    if (value == 'transport' ||
        value == 'travel & transport' ||
        value == 'transportation' ||
        value == 'fuel' ||
        value == 'petrol') {
      return 'Transport';
    }
    if (value == 'health' ||
        value == 'medical' ||
        value == 'medicine' ||
        value == 'hospital') {
      return 'Health';
    }
    if (value == 'shopping' || value == 'shop') {
      return 'Shopping';
    }
    if (value == 'entertainment' ||
        value == 'entmnt' ||
        value == 'movies' ||
        value == 'games') {
      return 'Entertainment';
    }
    if (value == 'bills' ||
        value == 'utilities' ||
        value == 'bills & utilities' ||
        value == 'electricity' ||
        value == 'gas' ||
        value == 'internet') {
      return 'Utilities';
    }
    if (value == 'education' || value == 'books' || value == 'school') {
      return 'Education';
    }
    if (value == 'groceries' || value == 'grocery' || value == 'ration') {
      return 'Groceries';
    }
    if (value == 'travel') {
      return 'Travel';
    }
    if (value == 'income' || value == 'salary') {
      return 'Income';
    }
    return category.trim().isEmpty ? 'Other' : category.trim();
  }

  static bool matchesFilter(String category, String filter) {
    if (filter == 'All') return true;
    return group(category).toLowerCase() == filter.trim().toLowerCase();
  }

  static CategoryStyle style(String category) {
    switch (group(category)) {
      case 'Food':
        return CategoryStyle(
          background: AppColors.catFoodBg,
          foreground: AppColors.catFoodFg,
          icon: PhosphorIcons.forkKnife(PhosphorIconsStyle.fill),
        );
      case 'Transport':
        return CategoryStyle(
          background: AppColors.catTransportBg,
          foreground: AppColors.catTransportFg,
          icon: PhosphorIcons.carSimple(PhosphorIconsStyle.fill),
        );
      case 'Shopping':
        return CategoryStyle(
          background: AppColors.catShoppingBg,
          foreground: AppColors.catShoppingFg,
          icon: PhosphorIcons.tote(PhosphorIconsStyle.fill),
        );
      case 'Utilities':
        return CategoryStyle(
          background: AppColors.catUtilitiesBg,
          foreground: AppColors.catUtilitiesFg,
          icon: PhosphorIcons.receipt(PhosphorIconsStyle.fill),
        );
      case 'Entertainment':
        return CategoryStyle(
          background: AppColors.catEntertainmentBg,
          foreground: AppColors.catEntertainmentFg,
          icon: PhosphorIcons.ticket(PhosphorIconsStyle.fill),
        );
      case 'Health':
        return CategoryStyle(
          background: AppColors.catHealthBg,
          foreground: AppColors.catHealthFg,
          icon: PhosphorIcons.firstAidKit(PhosphorIconsStyle.fill),
        );
      case 'Education':
        return CategoryStyle(
          background: AppColors.catEducationBg,
          foreground: AppColors.catEducationFg,
          icon: PhosphorIcons.bookOpen(PhosphorIconsStyle.fill),
        );
      case 'Groceries':
        return CategoryStyle(
          background: AppColors.catGroceriesBg,
          foreground: AppColors.catGroceriesFg,
          icon: PhosphorIcons.basket(PhosphorIconsStyle.fill),
        );
      case 'Travel':
        return CategoryStyle(
          background: AppColors.catTravelBg,
          foreground: AppColors.catTravelFg,
          icon: PhosphorIcons.airplaneTilt(PhosphorIconsStyle.fill),
        );
      case 'Income':
        return CategoryStyle(
          background: AppColors.catUtilitiesBg,
          foreground: AppColors.catUtilitiesFg,
          icon: PhosphorIcons.trendUp(PhosphorIconsStyle.bold),
        );
      default:
        return CategoryStyle(
          background: AppColors.catOtherBg,
          foreground: AppColors.catOtherFg,
          icon: PhosphorIcons.tag(PhosphorIconsStyle.fill),
        );
    }
  }

  static IconData icon(String category) {
    return style(category).icon;
  }
}
