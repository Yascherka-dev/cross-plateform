import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/fresh_spot.dart';
import 'auth_service.dart';

// Exception levée quand une action favori nécessite une connexion.
class FavoriNonConnecteException implements Exception {
  final String message;
  const FavoriNonConnecteException([
    this.message = 'Connectez-vous pour gérer vos favoris.',
  ]);

  @override
  String toString() => message;
}

// Service gérant les favoris de l'utilisateur connecté (table `favoris`).
// Les colonnes spot sont dénormalisées pour reconstruire un FreshSpot
// sans refaire d'appel aux datasets d'origine.
class FavorisService {
  final _client = Supabase.instance.client;
  final _authService = AuthService();

  // Identifiant de l'utilisateur connecté ou exception si déconnecté.
  String get _userId {
    final user = _authService.currentUser;
    if (user == null) throw const FavoriNonConnecteException();
    return user.id;
  }

  // Ajoute un spot aux favoris de l'utilisateur connecté.
  Future<void> ajouterFavori(FreshSpot spot) async {
    await _client.from('favoris').insert({
      'user_id': _userId,
      'spot_id': spot.id,
      'spot_nom': spot.nom,
      'spot_type': spot.type.name,
      'spot_latitude': spot.latitude,
      'spot_longitude': spot.longitude,
    });
  }

  // Retire un spot des favoris de l'utilisateur connecté.
  Future<void> retirerFavori(String spotId) async {
    await _client
        .from('favoris')
        .delete()
        .eq('user_id', _userId)
        .eq('spot_id', spotId);
  }

  // Indique si un spot est déjà en favori.
  Future<bool> estFavori(String spotId) async {
    final data = await _client
        .from('favoris')
        .select('id')
        .eq('user_id', _userId)
        .eq('spot_id', spotId)
        .limit(1);
    return (data as List).isNotEmpty;
  }

  // Récupère les favoris et reconstruit des FreshSpot depuis les colonnes
  // dénormalisées (les champs non stockés prennent des valeurs neutres).
  Future<List<FreshSpot>> fetchFavoris() async {
    final data = await _client
        .from('favoris')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);

    return (data as List).map((row) {
      final json = row as Map<String, dynamic>;
      return FreshSpot(
        id: json['spot_id'] as String,
        nom: json['spot_nom'] as String? ?? 'Lieu',
        type: freshSpotTypeFromString(json['spot_type'] as String? ?? ''),
        latitude: (json['spot_latitude'] as num).toDouble(),
        longitude: (json['spot_longitude'] as num).toDouble(),
        description: '',
        adresse: '',
        estOuvert: true,
      );
    }).toList();
  }
}
