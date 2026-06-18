import 'package:flutter/material.dart';

import '../config/app_theme.dart';

// Pastille carrée arrondie avec un fond coloré et une icône centrée.
// Motif récurrent des tuiles, cartes et en-têtes de l'app.
class IconPastille extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;
  final double radius;
  final double iconSize;

  const IconPastille({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    this.size = 38,
    this.radius = AppTheme.radiusPetit,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}
