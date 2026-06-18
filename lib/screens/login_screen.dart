import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'register_screen.dart';

// Écran de connexion email/mot de passe.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  String? _erreur; // message d'erreur affiché sous le formulaire

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _erreur = null;
    });

    try {
      await _authService.signIn(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (mounted) Navigator.pop(context); // retour à l'accueil
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.fond,
        surfaceTintColor: Colors.transparent,
        title: Text('Connexion', style: AppTheme.titre(18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Content de vous revoir', style: AppTheme.titre(24)),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  'Connectez-vous pour retrouver votre profil.',
                  style: AppTheme.body(
                    size: 13,
                    color: AppTheme.texteSecondaire,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXxl),

                AuthField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'vous@exemple.fr',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Email requis';
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Adresse email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingLg),

                AuthField(
                  controller: _passwordCtrl,
                  label: 'Mot de passe',
                  hint: '••••••',
                  obscure: true,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
                ),

                if (_erreur != null) ...[
                  const SizedBox(height: AppTheme.spacingLg),
                  AuthErrorBox(message: _erreur!),
                ],

                const SizedBox(height: AppTheme.spacingXxl),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _seConnecter,
                    child: _loading
                        ? const AuthButtonLoader()
                        : const Text('Se connecter'),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingLg),

                Center(
                  child: TextButton(
                    onPressed: _loading
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                    child: Text(
                      "Pas encore de compte ? S'inscrire",
                      style: AppTheme.body(
                        size: 13,
                        weight: FontWeight.w700,
                        color: AppTheme.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
