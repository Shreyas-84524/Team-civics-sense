import 'package:flutter/material.dart';

/// Civic issue categories (e.g. Roads, Sanitation, Streetlights, Water Supply).
class CivicCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color? color;

  const CivicCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.color,
  });

  static const List<CivicCategory> defaultCategories = [
    CivicCategory(
      id: 'roads',
      name: 'Roads',
      description: 'Road damage, potholes and unsafe road surfaces.',
      icon: Icons.add_road_rounded,
    ),
    CivicCategory(
      id: 'water',
      name: 'Water',
      description: 'Water supply issues, leakage or contamination.',
      icon: Icons.water_drop_outlined,
    ),
    CivicCategory(
      id: 'sanitation',
      name: 'Sanitation',
      description: 'Public hygiene, public toilets and street cleanliness.',
      icon: Icons.cleaning_services_rounded,
    ),
    CivicCategory(
      id: 'waste',
      name: 'Waste Management',
      description: 'Garbage accumulation and waste collection issues.',
      icon: Icons.delete_outline_rounded,
    ),
    CivicCategory(
      id: 'streetlights',
      name: 'Street Lights',
      description: 'Broken or non-functioning street lights.',
      icon: Icons.lightbulb_outline_rounded,
    ),
    CivicCategory(
      id: 'drainage',
      name: 'Drainage',
      description: 'Blocked drains, water logging, open manholes.',
      icon: Icons.waves_rounded,
    ),
    CivicCategory(
      id: 'infrastructure',
      name: 'Public Infrastructure',
      description: 'Damaged footpaths, bridges, bus shelters.',
      icon: Icons.account_balance_outlined,
    ),
    CivicCategory(
      id: 'traffic',
      name: 'Traffic / Road Safety',
      description: 'Damaged signs, missing signals, hazardous intersections.',
      icon: Icons.traffic_outlined,
    ),
    CivicCategory(
      id: 'other',
      name: 'Other',
      description: 'Other public infrastructure or municipal maintenance issues.',
      icon: Icons.category_outlined,
    ),
  ];
}
