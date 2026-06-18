import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';

// Écran d'inscription email/mot de passe (+ pseudo optionnel).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _pseudoCtrl = TextEditingController();

  bool _loading = false;
  String? _erreur;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _pseudoCtrl.dispose();
    super.dispose();
  }

  Future<void> _creerCompte() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _erreur = null;
    });

    try {
      await _authService.signUp(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        pseudo: _pseudoCtrl.text,
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
        title: Text('Inscription', style: AppTheme.titre(18)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthHeader(
                  title: 'Créer mon compte',
                  subtitle: 'Quelques secondes suffisent.',
                ),
                const SizedBox(height: AppTheme.spacingXxl),

                AuthField(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'vous@exemple.fr',
                  keyboardType: TextInputType.emailAddress,
                  validator: validerEmail,
                ),
                const SizedBox(height: AppTheme.spacingLg),

                AuthField(
                  controller: _passwordCtrl,
                  label: 'Mot de passe',
                  hint: '6 caractères minimum',
                  obscure: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mot de passe requis';
                    if (v.length < 6) return 'Au moins 6 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingLg),

                AuthField(
                  controller: _confirmCtrl,
                  label: 'Confirmer le mot de passe',
                  hint: '••••••',
                  obscure: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirmation requise';
                    if (v != _passwordCtrl.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppTheme.spacingLg),

                AuthField(
                  controller: _pseudoCtrl,
                  label: 'Pseudo (optionnel)',
                  hint: 'Votre pseudo',
                ),

                if (_erreur != null) ...[
                  const SizedBox(height: AppTheme.spacingLg),
                  AuthErrorBox(message: _erreur!),
                ],

                const SizedBox(height: AppTheme.spacingXxl),

                AuthSubmitButton(
                  label: 'Créer mon compte',
                  loading: _loading,
                  onPressed: _creerCompte,
                ),

                const SizedBox(height: AppTheme.spacingLg),

                AuthLink(
                  text: 'Déjà un compte ? Se connecter',
                  onPressed: _loading ? null : () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
