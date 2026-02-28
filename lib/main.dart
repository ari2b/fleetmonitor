import 'package:flutter/material.dart';
import 'providers/fleet_provider.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(const FleetMonitorApp());
}

class FleetMonitorApp extends StatefulWidget {
  const FleetMonitorApp({super.key});

  @override
  State<FleetMonitorApp> createState() => _FleetMonitorAppState();
}

class _FleetMonitorAppState extends State<FleetMonitorApp> {
  // Inisialisasi provider utama disini
  final FleetProvider fleetProvider = FleetProvider();

  @override
  Widget build(BuildContext context) {
    // Membungkus app dengan ListenableBuilder agar seluruh app re-render ketika data provider berubah
    return ListenableBuilder(
      listenable: fleetProvider,
      builder: (context, child) {
        return MaterialApp(
          title: 'Fleet Monitor',
          theme: ThemeData(
            primaryColor: Colors.indigo[600],
            scaffoldBackgroundColor: Colors.grey[50],
            fontFamily: 'Roboto', 
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          ),
          debugShowCheckedModeBanner: false,
          home: AuthScreen(provider: fleetProvider),
        );
      }
    );
  }
}