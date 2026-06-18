import 'package:flutter/material.dart';

import '../config/app_theme.dart';

// Composants d'UI partagés entre les écrans Login et Register,
// stylés selon la DA (AppTheme, Hanken Grotesk, palette terre).

// Validateur email partagé par les formulaires d'authentification.
String? validerEmail(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return 'Email requis';
  if (!value.contains('@') || !value.contains('.')) {
    return 'Adresse email invalide';
  }
  return null;
}

// En-tête d'écran d'auth : titre + sous-titre.
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTheme.titre(24)),
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          subtitle,
          style: AppTheme.body(size: 13, color: AppTheme.texteSecondaire),
        ),
      ],
    );
  }
}

// Bouton principal d'auth pleine largeur, avec loader pendant l'appel réseau.
class AuthSubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onPressed;

  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading ? const AuthButtonLoader() : Text(label),
      ),
    );
  }
}

// Lien secondaire centré (bascule login/register).
class AuthLink extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const AuthLink({super.key, required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: AppTheme.body(
            size: 13,
            weight: FontWeight.w700,
            color: AppTheme.accent,
          ),
        ),
      ),
    );
  }
}

// Champ de formulaire stylé.
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTheme.label(size: 12, color: AppTheme.texteSurface),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: AppTheme.body(size: 14, color: AppTheme.textePrincipal),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTheme.body(size: 14, color: AppTheme.texteTertiaire),
            filled: true,
            fillColor: AppTheme.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLg,
              vertical: AppTheme.spacingMd,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusPetit),
              borderSide: const BorderSide(color: AppTheme.bordure),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusPetit),
              borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusPetit),
              borderSide: const BorderSide(color: AppTheme.rougeTexte),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusPetit),
              borderSide: const BorderSide(
                color: AppTheme.rougeTexte,
                width: 1.5,
              ),
            ),
            errorStyle: AppTheme.label(size: 11, color: AppTheme.rougeTexte),
          ),
        ),
      ],
    );
  }
}

// Encart d'erreur affiché sous le formulaire (pas de SnackBar agressif).
class AuthErrorBox extends StatelessWidget {
  final String message;
  const AuthErrorBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.rougeFond,
        borderRadius: BorderRadius.circular(AppTheme.radiusPetit),
        border: Border.all(color: AppTheme.urgenceBordure),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, size: 18, color: AppTheme.rougeTexte),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              message,
              style: AppTheme.body(size: 12.5, color: AppTheme.urgenceTexte),
            ),
          ),
        ],
      ),
    );
  }
}

// Loader affiché dans le bouton pendant l'appel réseau.
class AuthButtonLoader extends StatelessWidget {
  const AuthButtonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
    );
  }
}
