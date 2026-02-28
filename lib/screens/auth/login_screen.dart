import 'package:flutter/material.dart';
import '../../providers/fleet_provider.dart';
import '../admin/admin_dashboard.dart';
import '../driver/driver_select.dart';

class AuthScreen extends StatelessWidget {
  final FleetProvider provider;
  const AuthScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.indigo[600],
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.local_shipping, size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text('Fleet Monitor', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Manajemen Armada Real-time', style: TextStyle(color: Colors.indigo[100])),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.security, color: Colors.white,),
                        label: const Text('Masuk sebagai Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[600],
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminDashboard(provider: provider))),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: Icon(Icons.person, color: Colors.indigo[600]),
                        label: Text('Masuk sebagai Driver', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo[600])),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          side: BorderSide(color: Colors.indigo[100]!, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DriverSelectScreen(provider: provider))),
                      ),
                      const SizedBox(height: 24),
                      Text('Versi 2.0.4 • © 2024 Fleet System', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}