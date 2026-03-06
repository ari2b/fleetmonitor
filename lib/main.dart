import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'providers/fleet_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/driver/driver_dashboard.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FleetMonitorApp());
}

class FleetMonitorApp extends StatefulWidget {
  const FleetMonitorApp({super.key});

  @override
  State<FleetMonitorApp> createState() => _FleetMonitorAppState();
}

class _FleetMonitorAppState extends State<FleetMonitorApp> {
  final FleetProvider fleetProvider = FleetProvider();

  @override
  Widget build(BuildContext context) {
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
          home: _AuthGate(provider: fleetProvider),
        );
      },
    );
  }
}

/// Cek apakah user sudah login atau belum.
/// Jika sudah, redirect langsung ke dashboard sesuai role.
class _AuthGate extends StatelessWidget {
  final FleetProvider provider;
  const _AuthGate({required this.provider});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.userStream,
      builder: (context, snapshot) {
        // Loading awal
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Belum login → halaman awal
        if (!snapshot.hasData || snapshot.data == null) {
          return AuthScreen(provider: provider);
        }

        // Sudah login → ambil role dari Firestore
        return FutureBuilder<Map<String, dynamic>?>(
          future: AuthService.getUserData(snapshot.data!.uid),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = userSnap.data;
            if (data == null) {
              // Data tidak ada, paksa logout
              AuthService.logout();
              return AuthScreen(provider: provider);
            }

            final role = data['role'] as String? ?? 'driver';

            if (role == 'admin') {
              return AdminDashboard(provider: provider);
            } else {
              provider.loginAsDriverFromFirebase(
                uid: snapshot.data!.uid,
                driverName: data['name'] ?? '',
                plateNumber: data['plateNumber'] ?? '',
                lat: (data['lat'] as num?)?.toDouble() ?? 0.5,
                lng: (data['lng'] as num?)?.toDouble() ?? 0.5,
              );
              return DriverDashboard(provider: provider);
            }
          },
        );
      },
    );
  }
}