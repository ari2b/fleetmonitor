import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../providers/fleet_provider.dart';
import '../auth/login_screen.dart';
import '../../models/schedule_model.dart';
import 'views/driver_jadwal_view.dart';

// Jenis kendaraan — sinkron dengan konstanta di register_screen & admin
const List<String> _kVehicleTypes = [
  'Mobil',
  'Truk',
  'Pickup',
  'Van/Minibus',
  'Motor',
];

class DriverDashboard extends StatelessWidget {
  final FleetProvider provider;
  const DriverDashboard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        final curV = provider.currentVehicle;
        if (curV == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.black.withOpacity(0.06),
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.indigo[600],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: const Icon(Icons.directions_car,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        curV.driverName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        curV.plateNumber,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.logout, color: Colors.grey[500]),
                onPressed: () {
                  provider.logout();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => AuthScreen(provider: provider)),
                  );
                },
              )
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── GPS Card ────────────────────────────────────
                _GpsCard(provider: provider, vehicle: curV),
                const SizedBox(height: 16),

                // ─── Mini Map ─────────────────────────────────────
                _DriverMiniMap(vehicle: curV),
                const SizedBox(height: 24),

                // ─── Ringkasan Jadwal ────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'JADWAL SAYA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        letterSpacing: 1.2,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverJadwalView(
                            driverId: curV.id,
                            driverName: curV.driverName,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Lihat Semua',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo[600],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 11, color: Colors.indigo[600]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _JadwalSummaryCard(
                  driverId: curV.id,
                  driverName: curV.driverName,
                ),

                const SizedBox(height: 24),

                // ─── Status Grid ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'UPDATE STATUS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (!provider.isGpsActive)
                      Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.red, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'GPS OFF',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.red[600],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.15,
                  children: [
                    _StatusAction(
                      active: curV.status == 'berangkat',
                      icon: Icons.play_circle_outline_rounded,
                      label: 'Berangkat',
                      color: Colors.blue,
                      disabled: !provider.isGpsActive,
                      onTap: () =>
                          provider.updateStatus(curV.id, 'berangkat'),
                    ),
                    _StatusAction(
                      active: curV.status == 'perjalanan',
                      icon: Icons.navigation_rounded,
                      label: 'Jalan',
                      color: Colors.teal,
                      disabled: !provider.isGpsActive,
                      onTap: () =>
                          provider.updateStatus(curV.id, 'perjalanan'),
                    ),
                    _StatusAction(
                      active: curV.status == 'sampai',
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Sampai',
                      color: Colors.orange,
                      disabled: false,
                      onTap: () =>
                          provider.updateStatus(curV.id, 'sampai'),
                    ),
                    _StatusAction(
                      active: curV.status == 'idle',
                      icon: Icons.local_cafe_outlined,
                      label: 'Selesai',
                      color: Colors.blueGrey,
                      disabled: false,
                      onTap: () =>
                          provider.updateStatus(curV.id, 'idle'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          bottomNavigationBar: _BottomNav(
            provider: provider,
            vehicleId: curV.id,
            driverName: curV.driverName,
          ),
        );
      },
    );
  }
}

// ─── Mini Map untuk Driver ────────────────────────────────────────────────────

class _DriverMiniMap extends StatelessWidget {
  final dynamic vehicle;
  const _DriverMiniMap({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: FlutterMap(
        options: MapOptions(
          initialCenter: ll.LatLng(vehicle.lat, vehicle.lng),
          initialZoom: 15,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.none,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.fleetmonitor',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: ll.LatLng(vehicle.lat, vehicle.lng),
                width: 48,
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.indigo[600],
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: const Icon(Icons.navigation,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Ringkasan Jadwal (mini list di dashboard) ───────────────────────────────

class _JadwalSummaryCard extends StatefulWidget {
  final String driverId;
  final String driverName;

  const _JadwalSummaryCard({
    required this.driverId,
    required this.driverName,
  });

  @override
  State<_JadwalSummaryCard> createState() => _JadwalSummaryCardState();
}

class _JadwalSummaryCardState extends State<_JadwalSummaryCard> {
  final _db = FirebaseFirestore.instance;

  List<Schedule> _byId = [];
  List<Schedule> _byName = [];
  bool _gotId = false;
  bool _gotName = false;

  @override
  void initState() {
    super.initState();
    _db
        .collection('schedules')
        .where('driverId', isEqualTo: widget.driverId)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() {
        _byId = snap.docs
            .map((d) => Schedule.fromMap(d.id, d.data()))
            .toList();
        _gotId = true;
      });
    });

    _db
        .collection('schedules')
        .where('driverName', isEqualTo: widget.driverName)
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      setState(() {
        _byName = snap.docs
            .map((d) => Schedule.fromMap(d.id, d.data()))
            .toList();
        _gotName = true;
      });
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed': return Colors.blue[600]!;
      case 'completed': return Colors.green[600]!;
      case 'cancelled': return Colors.red[600]!;
      default:          return Colors.orange[600]!;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'confirmed': return 'Dikonfirmasi';
      case 'completed': return 'Selesai';
      case 'cancelled': return 'Dibatalkan';
      default:          return 'Menunggu';
    }
  }

  String _formatDate(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  List<Schedule> get _merged {
    final seen = <String>{};
    final list = <Schedule>[];
    for (final s in [..._byId, ..._byName]) {
      if (seen.add(s.id)) list.add(s);
    }
    list.sort((a, b) => a.scheduleDate.compareTo(b.scheduleDate));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (!_gotId || !_gotName) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
            child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    final schedules = _merged;
    final pendingCount =
        schedules.where((s) => s.status == 'pending').length;
    final upcoming = schedules
        .where((s) => s.status == 'pending' || s.status == 'confirmed')
        .take(3)
        .toList();

    if (schedules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 36, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              'Belum ada jadwal.\nAdmin akan menambahkan jadwal untuk Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey[400], fontSize: 12, height: 1.5),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        children: [
          if (pendingCount > 0)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                    bottom: BorderSide(color: Colors.orange[100]!)),
              ),
              child: Row(
                children: [
                  Icon(Icons.notifications_active_rounded,
                      color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$pendingCount jadwal menunggu konfirmasi Anda',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),

          ...upcoming.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final color = _statusColor(s.status);
            final isLast = i == upcoming.length - 1;

            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DriverJadwalView(
                    driverId: widget.driverId,
                    driverName: widget.driverName,
                  ),
                ),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  border: isLast
                      ? null
                      : Border(
                          bottom: BorderSide(color: Colors.grey[100]!)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.event_rounded,
                          color: color, size: 17),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800]),
                          ),
                          Text(
                            _formatDate(s.scheduleDate),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        _statusLabel(s.status),
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: color),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DriverJadwalView(
                  driverId: widget.driverId,
                  driverName: widget.driverName,
                ),
              ),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Lihat Semua Jadwal (${schedules.length})',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[600]),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14, color: Colors.indigo[600]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── GPS Card ─────────────────────────────────────────────────────────────────

class _GpsCard extends StatefulWidget {
  final FleetProvider provider;
  final dynamic vehicle;

  const _GpsCard({required this.provider, required this.vehicle});

  @override
  State<_GpsCard> createState() => _GpsCardState();
}

class _GpsCardState extends State<_GpsCard> {
  bool _requestingPermission = false;

  Future<void> _handleGpsToggle() async {
    if (widget.provider.isGpsActive) {
      widget.provider.toggleGps();
      return;
    }

    setState(() => _requestingPermission = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          _showSnackbar('Layanan GPS tidak aktif. Aktifkan di Pengaturan.');
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) _showSnackbar('Izin lokasi ditolak.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showSnackbar(
              'Izin lokasi ditolak permanen. Buka Pengaturan untuk mengizinkan.');
        }
        return;
      }

      widget.provider.toggleGps();
      _startRealGpsTracking();
    } catch (e) {
      if (mounted) {
        _showSnackbar(
          'GPS tidak dapat diaktifkan. Pastikan izin lokasi sudah ditambahkan.',
        );
      }
    } finally {
      if (mounted) setState(() => _requestingPermission = false);
    }
  }

  void _startRealGpsTracking() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      if (!widget.provider.isGpsActive) return;
      widget.provider.updateGpsPosition(
        id: widget.vehicle.id,
        lat: position.latitude,
        lng: position.longitude,
        heading: position.heading,
      );
    });
  }

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[600]!, Colors.blue[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.map_outlined,
              size: 150,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          color: Colors.indigo[100], size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Pelacakan GPS',
                        style: TextStyle(
                          color: Colors.indigo[100],
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.provider.isGpsActive
                          ? Colors.greenAccent.withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.provider.isGpsActive ? 'AKTIF' : 'NON-AKTIF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: widget.provider.isGpsActive
                            ? Colors.greenAccent
                            : Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Posisi Saat Ini',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.indigo[200],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.vehicle.lat.toStringAsFixed(5)}, '
                        '${widget.vehicle.lng.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: _requestingPermission ? null : _handleGpsToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: widget.provider.isGpsActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: widget.provider.isGpsActive ? 0 : 2,
                        ),
                      ),
                      child: _requestingPermission
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Icon(
                              widget.provider.isGpsActive
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_arrow_rounded,
                              color: widget.provider.isGpsActive
                                  ? Colors.indigo[600]
                                  : Colors.white,
                              size: 36,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Status Action Button ─────────────────────────────────────────────────────

class _StatusAction extends StatelessWidget {
  final bool active;
  final bool disabled;
  final IconData icon;
  final String label;
  final MaterialColor color;
  final VoidCallback onTap;

  const _StatusAction({
    required this.active,
    required this.disabled,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: active ? color[600] : color[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? color[600]! : color[100]!,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  )
                ]
              : [],
        ),
        child: Opacity(
          opacity: disabled ? 0.3 : 1.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 36,
                color: active ? Colors.white : color[600],
              ),
              const SizedBox(height: 8),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.5,
                  color: active ? Colors.white : color[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────

class _BottomNav extends StatefulWidget {
  final FleetProvider provider;
  final String vehicleId;
  final String driverName;

  const _BottomNav({
    required this.provider,
    required this.vehicleId,
    required this.driverName,
  });

  @override
  State<_BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<_BottomNav> {
  int _current = 0;

  void _onTap(int index) {
    if (index == 0) {
      setState(() => _current = 0);
      return;
    }
    if (index == 1) {
      setState(() => _current = 1);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverJadwalView(
            driverId: widget.vehicleId,
            driverName: widget.driverName,
          ),
        ),
      ).then((_) => setState(() => _current = 0));
      return;
    }
    if (index == 2) {
      setState(() => _current = 2);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverProfileView(
            provider: widget.provider,
            vehicleId: widget.vehicleId,
          ),
        ),
      ).then((_) => setState(() => _current = 0));
      return;
    }
    setState(() => _current = index);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.directions_car,
            label: 'Driver',
            active: _current == 0,
            onTap: () => _onTap(0),
          ),
          _NavItem(
            icon: Icons.calendar_month_rounded,
            label: 'Jadwal',
            active: _current == 1,
            onTap: () => _onTap(1),
          ),
          _NavItem(
            icon: Icons.person_rounded,
            label: 'Profil',
            active: _current == 2,
            onTap: () => _onTap(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.indigo[600]! : Colors.grey[400]!;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
// ════════════════════════════════════════════════════════════════════════════
// Halaman Profil Driver
// Menampilkan data dari Firestore (collection: users + vehicles) agar driver
// bisa memverifikasi apakah datanya sesuai dengan yang tercatat oleh admin.
// ════════════════════════════════════════════════════════════════════════════

class DriverProfileView extends StatefulWidget {
  final FleetProvider provider;
  final String vehicleId;

  const DriverProfileView({
    super.key,
    required this.provider,
    required this.vehicleId,
  });

  @override
  State<DriverProfileView> createState() => _DriverProfileViewState();
}

class _DriverProfileViewState extends State<DriverProfileView> {
  final _db = FirebaseFirestore.instance;

  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _vehicles = [];
  bool _loading = true;
  String? _error;

  // Status chip admin — dipetakan dari field 'status' di collection drivers
  static const Map<String, _ChipMeta> _statusMeta = {
    'aktif': _ChipMeta(label: 'AKTIF', color: Colors.green),
    'nonaktif': _ChipMeta(label: 'NON-AKTIF', color: Colors.red),
    'idle': _ChipMeta(label: 'STANDBY', color: Colors.blueGrey),
    'berangkat': _ChipMeta(label: 'BERANGKAT', color: Colors.blue),
    'perjalanan': _ChipMeta(label: 'DALAM PERJALANAN', color: Colors.teal),
    'sampai': _ChipMeta(label: 'SAMPAI', color: Colors.orange),
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // ── Ambil data user dari collection 'users' (Firebase Auth UID) ──
      final uid = widget.provider.currentUserId;
      if (uid == null) throw Exception('Sesi tidak ditemukan.');

      final userDoc = await _db.collection('users').doc(uid).get();
      final userData = userDoc.data();

      // ── Ambil kendaraan yang terkait dengan driver ini ──
      // Coba lewat driverId dulu, fallback ke driverName
      final vById = await _db
          .collection('vehicles')
          .where('driverId', isEqualTo: uid)
          .get();

      List<Map<String, dynamic>> vehicles =
          vById.docs.map((d) => {'id': d.id, ...d.data()}).toList();

      // Fallback: cari by driverName kalau belum ada yang cocok
      if (vehicles.isEmpty && userData != null) {
        final vByName = await _db
            .collection('vehicles')
            .where('driverName', isEqualTo: userData['name'])
            .get();
        vehicles =
            vByName.docs.map((d) => {'id': d.id, ...d.data()}).toList();
      }

      if (!mounted) return;
      setState(() {
        _userData = userData;
        _vehicles = vehicles;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat profil: $e';
        _loading = false;
      });
    }
  }

  String _formatTs(dynamic ts) {
    if (ts == null) return '-';
    try {
      final dt = (ts as dynamic).toDate() as DateTime;
      const months = [
        'Jan','Feb','Mar','Apr','Mei','Jun',
        'Jul','Agu','Sep','Okt','Nov','Des'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return '-';
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Truk': return Icons.local_shipping;
      case 'Pickup': return Icons.airport_shuttle;
      case 'Van/Minibus': return Icons.directions_bus;
      case 'Motor': return Icons.two_wheeler;
      default: return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profil Saya',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text('Verifikasi data dengan Admin',
                style: TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadProfile,
            tooltip: 'Muat Ulang',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorState(message: _error!, onRetry: _loadProfile)
              : _userData == null
                  ? const Center(child: Text('Data tidak ditemukan.'))
                  : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _userData!;
    final name = d['name'] as String? ?? '-';
    final email = d['email'] as String? ?? '-';
    final phone = d['phone'] as String? ?? '';
    final role = d['role'] as String? ?? '-';
    final provider = d['provider'] as String? ?? '-';
    final plateNumber = d['plateNumber'] as String? ?? '';
    final vehicleType = d['vehicleType'] as String? ?? '';
    final vehicleBrand = d['vehicleBrand'] as String? ?? '';
    final vehicleModel = d['vehicleModel'] as String? ?? '';
    final vehicleColor = d['vehicleColor'] as String? ?? '';
    final driverStatus = d['status'] as String? ?? 'idle';
    final createdAt = _formatTs(d['createdAt']);

    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final photoUrl = d['photoUrl'] as String? ?? '';

    final statusMeta = _statusMeta[driverStatus] ??
        const _ChipMeta(label: 'TIDAK DIKETAHUI', color: Colors.grey);

    return RefreshIndicator(
      onRefresh: _loadProfile,
      color: Colors.indigo[600],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
        children: [
          // ── Info banner ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.indigo[600], size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Data ini ditampilkan dari sistem. '
                    'Hubungi Admin jika ada yang tidak sesuai.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.indigo[700],
                        height: 1.4),
                  ),
                ),
              ],
            ),
          ),

          // ── Avatar + nama ────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.indigo[200]!, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: photoUrl.isNotEmpty
                      ? ClipOval(
                          child: Image.network(photoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                    child: Text(initial,
                                        style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.indigo[600])),
                                  )))
                      : Center(
                          child: Text(initial,
                              style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo[600]))),
                ),
                const SizedBox(height: 14),
                Text(name,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 6),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusMeta.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: statusMeta.color.withOpacity(0.4)),
                  ),
                  child: Text(statusMeta.label,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusMeta.color)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Kartu Informasi Akun ─────────────────────────────────
          _SectionCard(
            title: 'INFORMASI AKUN',
            icon: Icons.account_circle_outlined,
            color: Colors.indigo,
            children: [
              _InfoRow(
                icon: Icons.person_outline,
                label: 'Nama Lengkap',
                value: name,
              ),
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: email,
              ),
              if (phone.isNotEmpty)
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: 'Telepon',
                  value: phone,
                ),
              _InfoRow(
                icon: Icons.badge_outlined,
                label: 'Role',
                value: role == 'driver' ? 'Driver' : role,
              ),
              _InfoRow(
                icon: provider == 'google'
                    ? Icons.g_mobiledata
                    : Icons.lock_outline,
                label: 'Login via',
                value: provider == 'google' ? 'Google' : 'Email & Password',
              ),
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Terdaftar',
                value: createdAt,
                isLast: true,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Kartu Data Kendaraan Terdaftar (dari register) ────────
          if (plateNumber.isNotEmpty || vehicleType.isNotEmpty)
            _SectionCard(
              title: 'KENDARAAN SAAT DAFTAR',
              icon: Icons.how_to_reg_outlined,
              color: Colors.teal,
              children: [
                if (plateNumber.isNotEmpty)
                  _InfoRow(
                    icon: Icons.credit_card_outlined,
                    label: 'Plat Nomor',
                    value: plateNumber,
                    mono: true,
                  ),
                if (vehicleType.isNotEmpty)
                  _InfoRow(
                    icon: Icons.category_outlined,
                    label: 'Jenis Kendaraan',
                    value: vehicleType,
                  ),
                if (vehicleBrand.isNotEmpty)
                  _InfoRow(
                    icon: Icons.local_offer_outlined,
                    label: 'Merk Kendaraan',
                    value: vehicleBrand,
                  ),
                if (vehicleModel.isNotEmpty)
                  _InfoRow(
                    icon: Icons.directions_car_filled_outlined,
                    label: 'Tipe Kendaraan',
                    value: vehicleModel,
                  ),
                if (vehicleColor.isNotEmpty)
                  _InfoRow(
                    icon: Icons.palette_outlined,
                    label: 'Warna Kendaraan',
                    value: vehicleColor,
                    isLast: true,
                  ),
              ],
            ),
          if (plateNumber.isNotEmpty || vehicleType.isNotEmpty)
            const SizedBox(height: 16),

          // ── Kartu Kendaraan dari Admin (collection vehicles) ──────
          _SectionCard(
            title: 'ARMADA YANG DITUGASKAN ADMIN',
            icon: Icons.directions_car_outlined,
            color: Colors.blue,
            children: _vehicles.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.car_crash_outlined,
                                size: 40, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada kendaraan yang ditugaskan oleh Admin.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 13,
                                  height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]
                : _vehicles.asMap().entries.map((entry) {
                    final i = entry.key;
                    final v = entry.value;
                    final isLast = i == _vehicles.length - 1;
                    return _VehicleRow(
                      vehicle: v,
                      iconForType: _iconForType,
                      isLast: isLast,
                    );
                  }).toList(),
          ),
          const SizedBox(height: 24),

          // ── Tombol Keluar ────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () {
              widget.provider.logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => AuthScreen(provider: widget.provider)),
                (route) => false,
              );
            },
            icon:
                Icon(Icons.logout_rounded, color: Colors.red[600], size: 18),
            label: Text('Keluar Akun',
                style: TextStyle(
                    color: Colors.red[600], fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: BorderSide(color: Colors.red[200]!),
              backgroundColor: Colors.red[50],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper: chip meta ────────────────────────────────────────────────────────

class _ChipMeta {
  final String label;
  final Color color;
  const _ChipMeta({required this.label, required this.color});
}

// ─── Section Card ─────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final MaterialColor color;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
              border: Border(bottom: BorderSide(color: color[100]!)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color[600], size: 16),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color[700],
                        letterSpacing: 0.6)),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;
  final bool mono;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[400], size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                        letterSpacing: 0.4)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                        fontFamily: mono ? 'monospace' : null)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vehicle Row (armada dari admin) ─────────────────────────────────────────

class _VehicleRow extends StatelessWidget {
  final Map<String, dynamic> vehicle;
  final IconData Function(String) iconForType;
  final bool isLast;

  const _VehicleRow({
    required this.vehicle,
    required this.iconForType,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final plate = vehicle['plateNumber'] as String? ?? '-';
    final type = vehicle['vehicleType'] as String? ?? 'Mobil';
    final brand = vehicle['vehicleBrand'] as String? ?? '';
    final model = vehicle['vehicleModel'] as String? ?? '';
    final color = vehicle['vehicleColor'] as String? ?? '';
    final status = vehicle['status'] as String? ?? 'idle';

    final statusLabel = {
          'idle': 'Standby',
          'berangkat': 'Berangkat',
          'perjalanan': 'Perjalanan',
          'sampai': 'Sampai',
        }[status] ??
        status;

    final statusColor = {
          'idle': Colors.blueGrey[600]!,
          'berangkat': Colors.blue[600]!,
          'perjalanan': Colors.teal[600]!,
          'sampai': Colors.orange[600]!,
        }[status] ??
        Colors.grey[600]!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey[100]!)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconForType(type),
                color: Colors.blue[600], size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plate,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: 'monospace',
                        color: Color(0xFF1E293B))),
                Text(
                    '$type${brand.isNotEmpty ? ' • $brand' : ''}${model.isNotEmpty ? ' $model' : ''}${color.isNotEmpty ? ' • $color' : ''}',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(statusLabel,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor)),
          ),
        ],
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red[400], size: 48),
            const SizedBox(height: 16),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], height: 1.5)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}