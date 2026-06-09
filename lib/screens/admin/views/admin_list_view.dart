import 'package:flutter/material.dart';
import '../../../providers/fleet_provider.dart';
import '../../../utils/status_theme.dart';

// ─── Ikon per jenis kendaraan ─────────────────────────────────────────────────

IconData _iconForType(String type) {
  // Toleran terhadap variasi huruf besar/kecil dan spasi
  final t = type.trim().toLowerCase();
  if (t.contains('truk') || t.contains('truck')) {
    return Icons.local_shipping;
  } else if (t.contains('pickup') || t.contains('pick up')) {
    return Icons.airport_shuttle;
  } else if (t.contains('van') || t.contains('minibus') || t.contains('bus')) {
    return Icons.directions_bus;
  } else if (t.contains('motor') || t.contains('sepeda motor') || t.contains('motorcycle')) {
    return Icons.two_wheeler;
  } else {
    // Default: Mobil / Car
    return Icons.directions_car;
  }
}

// ─── Warna ikon per jenis kendaraan ──────────────────────────────────────────

Color _iconColorForType(String type) {
  final t = type.trim().toLowerCase();
  if (t.contains('truk') || t.contains('truck')) {
    return Colors.orange[700]!;
  } else if (t.contains('pickup') || t.contains('pick up')) {
    return Colors.teal[600]!;
  } else if (t.contains('van') || t.contains('minibus') || t.contains('bus')) {
    return Colors.blue[600]!;
  } else if (t.contains('motor') || t.contains('motorcycle')) {
    return Colors.green[600]!;
  } else {
    return Colors.indigo[600]!;
  }
}

Color _iconBgForType(String type) {
  final t = type.trim().toLowerCase();
  if (t.contains('truk') || t.contains('truck')) {
    return Colors.orange[50]!;
  } else if (t.contains('pickup') || t.contains('pick up')) {
    return Colors.teal[50]!;
  } else if (t.contains('van') || t.contains('minibus') || t.contains('bus')) {
    return Colors.blue[50]!;
  } else if (t.contains('motor') || t.contains('motorcycle')) {
    return Colors.green[50]!;
  } else {
    return Colors.indigo[50]!;
  }
}

// ─── Admin List Tab ───────────────────────────────────────────────────────────

class AdminListTab extends StatelessWidget {
  final FleetProvider provider;
  const AdminListTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        if (provider.isLoadingVehicles) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.vehicles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car_outlined,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'Belum ada armada terdaftar.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.vehicles.length,
          itemBuilder: (context, index) {
            final v = provider.vehicles[index];
            final theme = statusThemes[v.status] ?? statusThemes['idle']!;
            final vehicleType = v.vehicleType.isNotEmpty ? v.vehicleType : 'Mobil';

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Ikon jenis kendaraan ──────────────
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _iconBgForType(vehicleType),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _iconForType(vehicleType),
                          color: _iconColorForType(vehicleType),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // ── Info kendaraan ────────────────────
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.plateNumber,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  fontFamily: 'monospace'),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              v.driverName,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            // Badge jenis kendaraan
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _iconBgForType(vehicleType),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: _iconColorForType(vehicleType)
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _iconForType(vehicleType),
                                        size: 10,
                                        color: _iconColorForType(vehicleType),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        vehicleType,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: _iconColorForType(vehicleType),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (v.vehicleBrand.isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    '${v.vehicleBrand} ${v.vehicleYear}',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500]),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Badge status ──────────────────────
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.bgColor,
                          border: Border.all(
                              color: theme.color.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          theme.label.toUpperCase(),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: theme.color),
                        ),
                      ),
                    ],
                  ),

                  // ── Log terkini ───────────────────────────
                  if (v.logs.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.history, size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text(
                          'LOG TERKINI',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[400],
                              letterSpacing: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...v.logs.take(3).map((log) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                      color: Colors.indigo[200],
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Text(log,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[700])),
                            ],
                          ),
                        )),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}