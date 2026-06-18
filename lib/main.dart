import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url:            dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const SosCaniculeApp());
}

class SosCaniculeApp extends StatelessWidget {
  const SosCaniculeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOS Canicule',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      // Déjà connecté → HomeScreen directement ; sinon → écran d'accueil.
      // L'accès reste libre : "Continuer sans compte" mène à une app complète.
      home: AuthService().currentUser != null
          ? const HomeScreen()
          : const WelcomeScreen(),
    );
  }
}
