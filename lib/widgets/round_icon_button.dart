import 'package:flutter/material.dart';

import '../config/app_theme.dart';

// Bouton rond à icône (surface + bordure), utilisé pour les actions
// rapides (favori, partage, retrait...). Le tooltip est optionnel.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? tooltip;
  final VoidCallback? onTap;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.color,
    this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bouton = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.bordure),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );

    return tooltip == null ? bouton : Tooltip(message: tooltip!, child: bouton);
  }
}
