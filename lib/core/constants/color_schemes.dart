import 'package:flutter/material.dart';

/// Alle verfügbaren Farbschemata für die App.
enum AppColorScheme {
  // ── kokomu Brand ─────────────────────────────────────────────────────
  kokomu('kokomu', Color(0xFF3D6B8F), Color(0xFF56B4A0), Icons.spa_outlined),

  // ── Neutral & Clean ──────────────────────────────────────────────────
  slate('Slate', Color(0xFF475569), Color(0xFF94A3B8), Icons.layers_outlined),
  charcoal('Charcoal', Color(0xFF374151), Color(0xFF6B7280), Icons.dark_mode_outlined),

  // ── Warm ─────────────────────────────────────────────────────────────
  amber('Amber', Color(0xFFD97706), Color(0xFF92400E), Icons.wb_sunny_outlined),
  terracotta('Terracotta', Color(0xFFC2410C), Color(0xFF7C2D12), Icons.local_fire_department_outlined),

  // ── Cool ─────────────────────────────────────────────────────────────
  indigo('Indigo', Color(0xFF4338CA), Color(0xFF312E81), Icons.nights_stay_outlined),
  sky('Sky', Color(0xFF0284C7), Color(0xFF075985), Icons.water_outlined),
  teal('Teal', Color(0xFF0D9488), Color(0xFF134E4A), Icons.water_drop_outlined),

  // ── Pop ──────────────────────────────────────────────────────────────
  purple('Lila', Color(0xFF7C3AED), Color(0xFF4C1D95), Icons.auto_awesome_outlined),
  rose('Rose', Color(0xFFE11D48), Color(0xFF881337), Icons.favorite_outline_rounded),
  emerald('Emerald', Color(0xFF059669), Color(0xFF064E3B), Icons.eco_outlined),
  ;

  const AppColorScheme(this.label, this.seedColor, this.accentColor, this.icon);

  final String label;
  final Color seedColor;
  final Color accentColor;
  final IconData icon;
}

