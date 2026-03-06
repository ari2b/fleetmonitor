import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Pastikan dokumen admin tersedia di Firestore
  await _ensureAdminExists();

  runApp(const FleetMonitorApp());
}

/// Buat dokumen admin di Firestore jika belum ada.
/// Menggunakan placeholder UID — akan di-migrate ke UID Google
/// secara otomatis saat admin pertama kali login via Google.
Future<void> _ensureAdminExists() async {
  const adminEmail = 'abhiramaarisatya@gmail.com';
  const placeholderUid = 'admin_abhiramaarisatya';

  try {
    final db = FirebaseFirestore.instance;

    // Cek apakah sudah ada dokumen dengan email ini
    final existing = await db
        .collection('users')
        .where('email', isEqualTo: adminEmail)
        .where('role', isEqualTo: 'admin')
        .limit(1)
        .get();

    if (existing.docs.isEmpty) {
      // Belum ada → buat dokumen admin
      await db.collection('users').doc(placeholderUid).set({
        'uid': placeholderUid,
        'name': 'Administrator',
        'email': adminEmail,
        'role': 'admin',
        'provider': 'google',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  } catch (_) {
    // Gagal → app tetap jalan normal
  }
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

class _AuthGate extends StatelessWidget {
  final FleetProvider provider;
  const _AuthGate({required this.provider});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return AuthScreen(provider: provider);
        }
        return _FirestoreUserGate(
          uid: snapshot.data!.uid,
          provider: provider,
        );
      },
    );
  }
}

class _FirestoreUserGate extends StatefulWidget {
  final String uid;
  final FleetProvider provider;
  const _FirestoreUserGate({required this.uid, required this.provider});

  @override
  State<_FirestoreUserGate> createState() => _FirestoreUserGateState();
}

class _FirestoreUserGateState extends State<_FirestoreUserGate> {
  Map<String, dynamic>? _userData;
  bool _notFound = false;
  int _retryCount = 0;
  static const int _maxRetry = 5;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await AuthService.getUserData(widget.uid);
    if (!mounted) return;
    if (data != null) {
      setState(() => _userData = data);
    } else if (_retryCount < _maxRetry) {
      _retryCount++;
      await Future.delayed(const Duration(milliseconds: 600));
      _loadUserData();
    } else {
      setState(() => _notFound = true);
      await AuthService.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_notFound) return AuthScreen(provider: widget.provider);
    if (_userData == null) return const _LoadingScreen();

    final role = _userData!['role'] as String? ?? 'driver';
    if (role == 'admin') {
      return AdminDashboard(provider: widget.provider);
    } else {
      widget.provider.loginAsDriverFromFirebase(
        uid: widget.uid,
        driverName: _userData!['name'] ?? '',
        plateNumber: _userData!['plateNumber'] ?? '',
        lat: (_userData!['lat'] as num?)?.toDouble() ?? 0.5,
        lng: (_userData!['lng'] as num?)?.toDouble() ?? 0.5,
      );
      return DriverDashboard(provider: widget.provider);
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}