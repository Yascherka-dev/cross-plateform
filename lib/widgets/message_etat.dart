import 'package:flutter/material.dart';

import '../config/app_theme.dart';

// Bloc "état" centré : icône + message + bouton d'action optionnel.
// Sert aux états vides, non connecté ou erreur.
class MessageEtat extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color iconColor;
  final Color messageColor;

  const MessageEtat({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor = AppTheme.texteTertiaire,
    this.messageColor = AppTheme.texteSecondaire,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 56, color: iconColor),
        const SizedBox(height: AppTheme.spacingLg),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTheme.body(size: 14, color: messageColor),
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppTheme.spacingXl),
          ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );
  }
}
