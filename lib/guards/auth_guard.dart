import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/auth_service.dart';

// Widget garde : affiche `child` si un utilisateur est connecté,
// sinon `fallback` (typiquement l'écran de login).
// Réagit en temps réel via le flux authStateChanges.
class AuthGuard extends StatelessWidget {
  final Widget child;
  final Widget fallback;

  AuthGuard({super.key, required this.child, required this.fallback});

  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authService.authStateChanges,
      builder: (context, _) {
        // On relit currentUser à chaque émission pour refléter l'état courant
        return _authService.currentUser != null ? child : fallback;
      },
    );
  }
}
