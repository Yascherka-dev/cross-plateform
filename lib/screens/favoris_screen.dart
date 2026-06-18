import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import '../models/fresh_spot.dart';
import '../services/auth_service.dart';
import '../services/favoris_service.dart';
import '../widgets/fresh_spot_tile.dart';
import 'login_screen.dart';

// Écran listant les favoris de l'utilisateur connecté.
class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  final _authService = AuthService();
  final _favorisService = FavorisService();

  late Future<List<FreshSpot>> _future;

  @override
  void initState() {
    super.initState();
    _future = _charger();
  }

  Future<List<FreshSpot>> _charger() {
    if (_authService.currentUser == null) return Future.value([]);
    return _favorisService.fetchFavoris();
  }

  Future<void> _refresh() async {
    setState(() => _future = _charger());
    await _future;
  }

  Future<void> _retirer(FreshSpot spot) async {
    try {
      await _favorisService.retirerFavori(spot.id);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Retiré des favoris',
              style: AppTheme.body(size: 13, color: Colors.white),
            ),
            backgroundColor: AppTheme.textePrincipal,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      /* erreur silencieuse : la liste reste inchangée */
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.fond,
      appBar: AppBar(
        backgroundColor: AppTheme.fond,
        surfaceTintColor: Colors.transparent,
        title: Text('Mes favoris', style: AppTheme.titre(18)),
      ),
      body: _authService.currentUser == null
          ? _EtatNonConnecte()
          : RefreshIndicator(
              color: AppTheme.accent,
              backgroundColor: AppTheme.surface,
              onRefresh: _refresh,
              child: FutureBuilder<List<FreshSpot>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.accent),
                    );
                  }

                  final favoris = snapshot.data ?? [];
                  if (favoris.isEmpty) return const _EtatVide();

                  return ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.spacingLg),
                    itemCount: favoris.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppTheme.spacingSm),
                    itemBuilder: (context, i) {
                      final spot = favoris[i];
                      // Tap long pour retirer (raccourci) + bouton cœur dédié.
                      return GestureDetector(
                        // Tap : ouvrir sur la carte (renvoie le spot à HomeScreen).
                        onTap: () => Navigator.pop(context, spot),
                        // Tap long : retirer des favoris.
                        onLongPress: () => _retirer(spot),
                        child: Row(
                          children: [
                            Expanded(child: FreshSpotTile(spot: spot)),
                            const SizedBox(width: AppTheme.spacingSm),
                            _BoutonRetirer(onTap: () => _retirer(spot)),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
    );
  }
}

// Bouton cœur plein pour retirer un favori.
class _BoutonRetirer extends StatelessWidget {
  final VoidCallback onTap;
  const _BoutonRetirer({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
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
        child: const Icon(
          Icons.favorite_rounded,
          color: AppTheme.rougeTexte,
          size: 20,
        ),
      ),
    );
  }
}

// État : utilisateur non connecté.
class _EtatNonConnecte extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.favorite_border_rounded,
              size: 56,
              color: AppTheme.texteTertiaire,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              'Connectez-vous pour retrouver vos lieux favoris.',
              textAlign: TextAlign.center,
              style: AppTheme.body(size: 14, color: AppTheme.texteSecondaire),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
              child: const Text('Se connecter'),
            ),
          ],
        ),
      ),
    );
  }
}

// État : connecté mais aucun favori.
class _EtatVide extends StatelessWidget {
  const _EtatVide();

  @override
  Widget build(BuildContext context) {
    // ListView pour permettre le pull-to-refresh même quand c'est vide.
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingXxl),
      children: [
        const SizedBox(height: 80),
        const Icon(
          Icons.map_rounded,
          size: 56,
          color: AppTheme.texteTertiaire,
        ),
        const SizedBox(height: AppTheme.spacingLg),
        Text(
          'Aucun favori pour le moment.\n'
          'Explorez la carte et touchez le cœur pour en ajouter.',
          textAlign: TextAlign.center,
          style: AppTheme.body(size: 14, color: AppTheme.texteSecondaire),
        ),
      ],
    );
  }
}
