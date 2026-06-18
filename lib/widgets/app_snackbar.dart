import 'package:flutter/material.dart';

import '../config/app_theme.dart';

// SnackBar de confirmation discret, style DA (fond sombre, flottant).
void afficherSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: AppTheme.body(size: 13, color: Colors.white),
      ),
      backgroundColor: AppTheme.textePrincipal,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}
