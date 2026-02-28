import 'package:flutter/material.dart';
import '../../providers/fleet_provider.dart';
import 'driver_dashboard.dart';

class DriverSelectScreen extends StatelessWidget {
  final FleetProvider provider;
  const DriverSelectScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey[800]),
        title: Text('Pilih Akun', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.vehicles.length,
        itemBuilder: (context, index) {
          final v = provider.vehicles[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.center,
                child: Text(v.driverName[0], style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo[600])),
              ),
              title: Text(v.driverName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(v.plateNumber, style: TextStyle(fontFamily: 'monospace', color: Colors.grey[600])),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                provider.loginAsDriver(v.id);
                // Hapus stack halaman sebelumnya, masuk ke dashboard driver
                Navigator.pushAndRemoveUntil(
                  context, 
                  MaterialPageRoute(builder: (_) => DriverDashboard(provider: provider)),
                  (route) => false
                );
              },
            ),
          );
        },
      ),
    );
  }
}