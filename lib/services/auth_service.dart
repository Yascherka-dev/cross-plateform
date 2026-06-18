import 'package:supabase_flutter/supabase_flutter.dart';

// Exception métier portant un message d'erreur déjà traduit en français,
// prête à être affichée telle quelle dans l'UI.
class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);

  @override
  String toString() => message;
}

// Service centralisant tous les appels à Supabase Auth.
// Les erreurs Supabase (AuthException) sont converties en AuthFailure
// avec un message français clair pour l'utilisateur.
class AuthService {
  final _auth = Supabase.instance.client.auth;

  // Utilisateur actuellement connecté, null si déconnecté
  User? get currentUser => _auth.currentUser;

  // Flux des changements d'état d'authentification (connexion/déconnexion)
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  // Inscription email/mot de passe.
  // Le pseudo (optionnel) est stocké dans les métadonnées utilisateur.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? pseudo,
  }) async {
    try {
      return await _auth.signUp(
        email: email,
        password: password,
        data: (pseudo != null && pseudo.trim().isNotEmpty)
            ? {'pseudo': pseudo.trim()}
            : null,
      );
    } on AuthException catch (e) {
      throw AuthFailure(_messageFr(e));
    } catch (_) {
      throw const AuthFailure('Une erreur est survenue. Réessayez.');
    }
  }

  // Connexion email/mot de passe.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      throw AuthFailure(_messageFr(e));
    } catch (_) {
      throw const AuthFailure('Une erreur est survenue. Réessayez.');
    }
  }

  // Déconnexion.
  Future<void> signOut() => _auth.signOut();

  // Traduit les erreurs Supabase en messages français lisibles.
  String _messageFr(AuthException e) {
    final m = e.message.toLowerCase();

    if (m.contains('already registered') || m.contains('already exists')) {
      return 'Cet email est déjà utilisé.';
    }
    if (m.contains('invalid login credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (m.contains('password') && m.contains('6')) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    if (m.contains('unable to validate email') || m.contains('invalid email')) {
      return 'Adresse email invalide.';
    }
    if (m.contains('email not confirmed')) {
      return 'Confirmez votre email avant de vous connecter.';
    }
    return 'Une erreur est survenue. Réessayez.';
  }
}
