# SOS Canicule

Application mobile Flutter d'alerte canicule et de recherche de points de fraîcheur à Paris.

## Fonctionnalités

- **Niveau de risque** — calcul automatique (vert / orange / rouge) basé sur la météo en temps réel
- **Météo actuelle** — température, ressenti, UV, humidité, pic journalier via Open-Meteo
- **Points de fraîcheur** — fontaines à boire, espaces verts, équipements frais (données OpenData Paris)
- **Conseils canicule** — fiches adaptées au niveau de risque via Supabase
- **Numéros d'urgence** — 15, 18, 112, 3114 cliquables directement depuis l'app

## Stack technique

- Flutter / Dart
- Supabase (fiches conseils + seuils de risque dynamiques)
- Open-Meteo API (météo)
- OpenData Paris API (points de fraîcheur)
- Geolocator (GPS)
- url_launcher (appels téléphoniques)

## Lancer le projet

```bash
# Copier le fichier de config Supabase
cp lib/config/secrets.example.dart lib/config/secrets.dart
# Remplir supabaseUrl et supabaseAnonKey dans secrets.dart

flutter pub get
flutter run
```

## Structure

```
lib/
├── config/       # Thème, couleurs, credentials Supabase
├── logic/        # Calcul du niveau de risque
├── models/       # WeatherData, FreshSpot, AdviceCard
├── screens/      # HomeScreen, MapScreen, AdviceScreen
├── services/     # Weather, Location, FreshSpot, Supabase
└── widgets/      # RiskBanner, FreshSpotTile, AdviceTile, EmergencyTile
```
