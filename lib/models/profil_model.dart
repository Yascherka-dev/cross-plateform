// Modèle représentant le profil d'un utilisateur authentifié.
// L'id correspond à auth.users.id côté Supabase (uuid).
class ProfilModel {
  final String id; // uuid, identique à auth.users.id
  final String email;
  final String? pseudo; // optionnel à l'inscription
  final DateTime? createdAt;

  const ProfilModel({
    required this.id,
    required this.email,
    this.pseudo,
    this.createdAt,
  });

  // Désérialisation depuis une ligne Supabase (table profils ou user metadata)
  factory ProfilModel.fromJson(Map<String, dynamic> json) {
    return ProfilModel(
      id: json['id'] as String,
      email: json['email'] as String,
      pseudo: json['pseudo'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
