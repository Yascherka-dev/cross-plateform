import 'package:flutter/material.dart';
import '../models/fresh_spot.dart';

// Écran carte — reçoit les fresh spots déjà chargés depuis HomeScreen
// pour ne pas refaire un appel API inutile
class MapScreen extends StatelessWidget {
  final List<FreshSpot> freshSpots;

  const MapScreen({super.key, required this.freshSpots});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('${freshSpots.length} spots — carte à venir'),
      ),
    );
  }
}