import '../models/category_model.dart';

/// Helper for mapping civic categories to citizen-facing municipal departments.
class DepartmentHelper {
  DepartmentHelper._();

  /// Returns the responsible citizen-facing municipal department for a given category.
  static String getDepartmentName(CivicCategory? category) {
    if (category == null) return 'General Municipal Desk';

    switch (category.id) {
      case 'roads':
        return 'Roads Department';
      case 'water':
        return 'Water Department';
      case 'sanitation':
        return 'Sanitation Department';
      case 'waste':
        return 'Sanitation / Waste Department';
      case 'streetlights':
        return 'Electrical / Public Works';
      case 'drainage':
        return 'Drainage Department';
      case 'infrastructure':
        return 'Public Works';
      case 'traffic':
        return 'Traffic / Road Safety Department';
      case 'other':
      default:
        return 'Manual Review & Municipal Desk';
    }
  }
}
