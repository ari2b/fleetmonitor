import 'package:flutter/material.dart';
import '../../providers/fleet_provider.dart';
import 'driver_dashboard.dart';

class DriverSelectScreen extends StatelessWidget {
  final FleetProvider provider;
  const DriverSelectScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black12,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: Colors.grey[700], size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pilih Akun',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: provider,
        builder: (context, _) {
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.vehicles.length,
            itemBuilder: (context, index) {
              final v = provider.vehicles[index];
              return _DriverCard(
                vehicle: v,
                onTap: () {
                  provider.loginAsDriver(v.id);
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DriverDashboard(provider: provider)),
                    (route) => false,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  final dynamic vehicle;
  final VoidCallback onTap;

  const _DriverCard({required this.vehicle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Avatar huruf pertama
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                vehicle.driverName[0],
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[600],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Nama & plat
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.driverName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      vehicle.plateNumber,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Icon(Icons.chevron_right, color: Colors.grey[300], size: 24),
          ],
        ),
      ),
    );
  }
}