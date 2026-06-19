# SOS Canicule Paris

Application mobile **Flutter** (iOS & Android) qui aide à traverser les épisodes
de forte chaleur à Paris : elle évalue le niveau de risque à partir de la météo
en temps réel, cartographie les points de fraîcheur officiels, et regroupe
conseils de prévention et numéros d'urgence.

> Une seule base de code pour iOS et Android. L'application reste pleinement
> fonctionnelle **sans compte** ; la connexion ne sert qu'à enregistrer et
> partager ses lieux favoris.

---

## Fonctionnalités

- **Niveau de risque** — calcul automatique `vert` / `orange` / `rouge` à partir
  de la météo de l'instant (température, ressenti, humidité, UV). Seuils
  configurables côté serveur (Supabase) sans redéployer l'app.
- **Météo temps réel** — température, ressenti, humidité, indice UV et pic
  journalier à la position GPS de l'utilisateur (Open-Meteo).
- **Carte des points de fraîcheur** — parcs & jardins, fontaines à boire, lieux
  climatisés et piscines (OpenData Paris), avec filtres par type, fiche
  détaillée, calcul de distance et lien itinéraire.
- **Conseils de prévention** — fiches par niveau de risque, repli sur des fiches
  embarquées si le réseau est indisponible.
- **Numéros d'urgence** — appel direct depuis l'app, avec confirmation.
- **Favoris & partage** — enregistrement de lieux (compte requis) et partage via
  la feuille de partage native du téléphone.

---

## Stack technique

| Domaine | Outil |
|---|---|
| Framework | Flutter 3.44.1 (stable) · Dart SDK `^3.12.1` |
| Backend / Auth | `supabase_flutter` ^2.14.2 |
| Réseau | `http` ^1.2.0 |
| Géolocalisation | `geolocator` ^11.0.0 |
| Carte | `flutter_map` ^6.1.0 + `latlong2` ^0.9.0 |
| Liens externes | `url_launcher` ^6.3.2 (itinéraires, `tel:`) |
| Partage | `share_plus` ^13.1.0 |
| Configuration | `flutter_dotenv` ^6.0.1 |
| Typographie | `google_fonts` ^8.1.0 (Hanken Grotesk) |

### Sources de données

- **Open-Meteo** — météo (gratuit, sans clé).
- **OpenData Paris** — 3 datasets « îlots de fraîcheur » (gratuit, sans clé) :
  `ilots-de-fraicheur-espaces-verts-frais`,
  `ilots-de-fraicheur-equipements-activites`,
  `fontaines-a-boire`.
- **Supabase** — tables de contenu (`heat_thresholds`, `advice_cards`,
  `emergency_numbers`), favoris (`favoris`), authentification et stockage des
  images de conseils.

---

## Architecture

Organisation en couches, avec une règle simple : **un service = une source de
données**, et la logique métier isolée du réseau et de l'UI.

```
lib/
├── main.dart      # Bootstrap : chargement .env + initialisation Supabase
├── config/        # AppTheme (thème, couleurs, typo) · AppConfig (URLs OpenData, cache)
├── guards/        # AuthGuard (affichage conditionnel selon l'état de connexion)
├── logic/         # calculateHeatRisk — logique métier pure et testable
├── models/        # WeatherData, FreshSpot, AdviceCard, ProfilModel
├── screens/       # Welcome, Login, Register, Home, Map, Advice, Emergency, Favoris
├── services/      # weather, location, fresh_spot, supabase, auth, favoris, share
└── widgets/       # Composants réutilisables (RiskBanner, FreshSpotTile, ...)
```

Flux principal :

```
GPS (LocationService)
  ├─► WeatherService (Open-Meteo) ───────────────┐
  ├─► FreshSpotService (OpenData Paris ×3) ──┐    │
  └─► SupabaseService (heat_thresholds) ─────┼────┤
                                             │    ▼
                                             │  calculateHeatRisk()  →  HeatRiskLevel
                                             ▼            ▼
                                          Carte        RiskBanner (UI colorée)
```

---

## Démarrage

### Prérequis

- Flutter (canal stable, 3.44.x) — vérifier avec `flutter doctor`.
- Un projet Supabase (URL + clé publique « anon »).

### Installation

```bash
# 1. Configuration : copier le modèle puis renseigner les valeurs
cp .env.example .env

# .env attendu :
#   SUPABASE_URL=https://votre-projet.supabase.co
#   SUPABASE_ANON_KEY=votre_cle_anon

# 2. Dépendances
flutter pub get

# 3. Lancer (un appareil/émulateur doit être connecté)
flutter run
```

> Le fichier `.env` est ignoré par Git et déclaré comme asset dans `pubspec.yaml`.
> Ne jamais committer de clés.

### Schéma Supabase attendu

Les tables suivantes doivent exister pour un fonctionnement complet (l'app
prévoit des replis locaux pour les conseils et les numéros d'urgence) :

- **`heat_thresholds`** — `niveau` (`orange`/`rouge`), `seuil_temp`, `seuil_uv`,
  `humidite_boost_1`, `humidite_boost_2`.
- **`advice_cards`** — `id`, `titre`, `niveau`, `conseils`, `numeros_urgence`,
  `image_url`, `ordre`.
- **`emergency_numbers`** — `numero`, `label`, `description`, `ordre`.
- **`favoris`** — `id`, `user_id` (→ `auth.users.id`), `spot_id`, `spot_nom`,
  `spot_type`, `spot_latitude`, `spot_longitude`, `created_at`.

La table `favoris` est protégée par **RLS** (`auth.uid() = user_id`) : chaque
utilisateur n'accède qu'à ses propres favoris.

---

## Qualité

- `flutter analyze` : 0 issue (avec `flutter_lints`).
- Aucune couleur codée en dur dans les écrans : tout passe par `AppTheme`.
- Dégradation gracieuse : une source OpenData indisponible n'empêche pas
  l'affichage des autres ; Supabase hors-ligne bascule sur des données locales.
- Secrets hors du dépôt (`.env`).

---

## Plateformes

- **Android** : `compileSdk` / `targetSdk` 36.
- **iOS** : Bundle ID `com.yascherka.soscanicule` (signature développeur requise
  pour un déploiement sur appareil physique).
