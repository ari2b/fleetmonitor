import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/fleet_provider.dart';
import '../../../models/schedule_model.dart';
import '../../../models/vehicle_model.dart';
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

            return InkWell(
              onTap: () => _showVehicleHistorySheet(context, v),
              borderRadius: BorderRadius.circular(20),
              child: Container(
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

                  // ── Footer: jumlah jadwal & histori ────────
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('schedules')
                        .where('vehicleId', isEqualTo: v.id)
                        .snapshots(),
                    builder: (context, snap) {
                      final count = snap.data?.docs.length ?? 0;
                      return Row(
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              size: 14, color: Colors.orange[400]),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$count Jadwal • Ketuk untuk lihat histori',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 11, color: Colors.orange[300]),
                        ],
                      );
                    },
                  ),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Bottom Sheet: Histori & Jadwal Armada ────────────────────────────────────

void _showVehicleHistorySheet(BuildContext context, Vehicle vehicle) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _VehicleHistorySheet(vehicle: vehicle),
  );
}

Color _scheduleStatusColor(String status) {
  switch (status) {
    case 'confirmed':
      return Colors.blue[600]!;
    case 'completed':
      return Colors.green[600]!;
    case 'cancelled':
      return Colors.red[600]!;
    default:
      return Colors.orange[600]!;
  }
}

String _scheduleStatusLabel(String status) {
  switch (status) {
    case 'confirmed':
      return 'Dikonfirmasi';
    case 'completed':
      return 'Selesai';
    case 'cancelled':
      return 'Dibatalkan';
    default:
      return 'Menunggu';
  }
}

String _formatScheduleDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class _VehicleHistorySheet extends StatelessWidget {
  final Vehicle vehicle;
  const _VehicleHistorySheet({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ── Handle & Header ──────────────────────────
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.directions_car_rounded,
                          color: Colors.indigo[600], size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.plateNumber,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                fontFamily: 'monospace'),
                          ),
                          Text(
                            '${vehicle.vehicleBrand} ${vehicle.vehicleModel} • ${vehicle.driverName}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ── List Jadwal (histori & mendatang) ─────────
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('schedules')
                      .where('vehicleId', isEqualTo: vehicle.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Gagal memuat jadwal: ${snapshot.error}',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    final schedules = (snapshot.data?.docs ?? [])
                        .map((d) => Schedule.fromMap(
                            d.id, d.data() as Map<String, dynamic>))
                        .toList()
                      ..sort((a, b) =>
                          b.scheduleDate.compareTo(a.scheduleDate));

                    if (schedules.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy_rounded,
                                  size: 56, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada jadwal untuk armada ini.',
                                style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: schedules.length,
                      itemBuilder: (context, i) {
                        final s = schedules[i];
                        final color = _scheduleStatusColor(s.status);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 5),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _formatScheduleDate(s.scheduleDate),
                                      style: TextStyle(
                                          fontSize: 11.5,
                                          color: Colors.grey[500]),
                                    ),
                                    if (s.location.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        s.location,
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.grey[500]),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: color.withOpacity(0.3)),
                                ),
                                child: Text(
                                  _scheduleStatusLabel(s.status),
                                  style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      color: color),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}