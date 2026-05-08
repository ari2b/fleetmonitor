import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../models/vehicle_model.dart';
import '../../../providers/fleet_provider.dart';
import '../../../utils/status_theme.dart';

// ─── Ikon per jenis kendaraan ─────────────────────────────────────────────────

IconData _iconForType(String type) {
  switch (type) {
    case 'Truk':
      return Icons.local_shipping;
    case 'Pickup':
      return Icons.airport_shuttle;
    case 'Van/Minibus':
      return Icons.directions_bus;
    case 'Motor':
      return Icons.two_wheeler;
    default:
      return Icons.directions_car;
  }
}

// ─── Admin Map Tab ─────────────────────────────────────────────────────────────

class AdminMapTab extends StatefulWidget {
  final FleetProvider provider;
  const AdminMapTab({super.key, required this.provider});

  @override
  State<AdminMapTab> createState() => _AdminMapTabState();
}

class _AdminMapTabState extends State<AdminMapTab> {
  final MapController _mapController = MapController();
  Vehicle? _selectedVehicle;
  bool _followSelected = false;

  // Pusat peta — area Madiun, Jawa Timur
  static const ll.LatLng _defaultCenter = ll.LatLng(-7.6298, 111.5225);
  static const double _defaultZoom = 14.0;

  @override
  void initState() {
    super.initState();
    widget.provider.addListener(_onProviderUpdate);
  }

  @override
  void dispose() {
    widget.provider.removeListener(_onProviderUpdate);
    super.dispose();
  }

  void _onProviderUpdate() {
    // Jika follow mode aktif & ada kendaraan dipilih, ikuti posisinya
    if (_followSelected && _selectedVehicle != null) {
      final v = widget.provider.vehicles
          .where((v) => v.id == _selectedVehicle!.id)
          .firstOrNull;
      if (v != null) {
        _mapController.move(ll.LatLng(v.lat, v.lng), _mapController.camera.zoom);
      }
    }
  }

  void _selectVehicle(Vehicle v) {
    setState(() {
      _selectedVehicle = v;
      _followSelected = true;
    });
    _mapController.move(
      ll.LatLng(v.lat, v.lng),
      16.0,
    );
  }

  void _fitAll() {
    final vehicles = widget.provider.vehicles;
    if (vehicles.isEmpty) return;

    setState(() {
      _selectedVehicle = null;
      _followSelected = false;
    });

    if (vehicles.length == 1) {
      _mapController.move(
        ll.LatLng(vehicles.first.lat, vehicles.first.lng),
        _defaultZoom,
      );
      return;
    }

    // Hitung bounding box semua kendaraan
    double minLat = vehicles.first.lat;
    double maxLat = vehicles.first.lat;
    double minLng = vehicles.first.lng;
    double maxLng = vehicles.first.lng;

    for (final v in vehicles) {
      minLat = min(minLat, v.lat);
      maxLat = max(maxLat, v.lat);
      minLng = min(minLng, v.lng);
      maxLng = max(maxLng, v.lng);
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(
          ll.LatLng(minLat - 0.005, minLng - 0.005),
          ll.LatLng(maxLat + 0.005, maxLng + 0.005),
        ),
        padding: const EdgeInsets.fromLTRB(40, 80, 40, 180),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.provider,
      builder: (context, _) {
        final vehicles = widget.provider.vehicles;

        return Stack(
          children: [
            // ── Peta Utama ──────────────────────────────
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _defaultCenter,
                initialZoom: _defaultZoom,
                minZoom: 5,
                maxZoom: 19,
                onTap: (_, __) => setState(() {
                  _selectedVehicle = null;
                  _followSelected = false;
                }),
              ),
              children: [
                // Tile layer OpenStreetMap (gratis, tanpa API key)
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.fleetmonitor',
                  maxZoom: 19,
                ),

                // Lingkaran radius di kendaraan yang dipilih
                if (_selectedVehicle != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: ll.LatLng(
                            _selectedVehicle!.lat, _selectedVehicle!.lng),
                        radius: 60,
                        color: Colors.indigo.withOpacity(0.12),
                        borderColor: Colors.indigo.withOpacity(0.4),
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),

                // Marker kendaraan
                MarkerLayer(
                  markers: vehicles.map((v) {
                    final isSelected = _selectedVehicle?.id == v.id;
                    final theme = statusThemes[v.status] ??
                        statusThemes['idle']!;

                    return Marker(
                      point: ll.LatLng(v.lat, v.lng),
                      width: isSelected ? 80 : 64,
                      height: isSelected ? 80 : 64,
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: () => _selectVehicle(v),
                        child: _VehicleMarker(
                          vehicle: v,
                          theme: theme,
                          isSelected: isSelected,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Attribution
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),
              ],
            ),

            // ── Tombol Kontrol Peta (kanan atas) ────────
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                children: [
                  _MapControlBtn(
                    icon: Icons.fit_screen,
                    tooltip: 'Tampilkan semua armada',
                    onTap: _fitAll,
                  ),
                  const SizedBox(height: 8),
                  _MapControlBtn(
                    icon: Icons.add,
                    tooltip: 'Zoom in',
                    onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MapControlBtn(
                    icon: Icons.remove,
                    tooltip: 'Zoom out',
                    onTap: () => _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    ),
                  ),
                ],
              ),
            ),

            // ── Badge Follow Mode ─────────────────────────
            if (_followSelected && _selectedVehicle != null)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.indigo[600],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.my_location,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Mengikuti ${_selectedVehicle!.plateNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setState(() => _followSelected = false),
                        child: const Icon(Icons.close,
                            color: Colors.white70, size: 14),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Detail Panel kendaraan dipilih ───────────
            if (_selectedVehicle != null) ...[
              Positioned(
                bottom: 124,
                left: 12,
                right: 12,
                child: _VehicleDetailPanel(
                  vehicle: _selectedVehicle!,
                  onClose: () => setState(() {
                    _selectedVehicle = null;
                    _followSelected = false;
                  }),
                  onFollow: () {
                    setState(() => _followSelected = !_followSelected);
                  },
                  isFollowing: _followSelected,
                ),
              ),
            ],

            // ── Daftar armada horizontal (bawah) ─────────
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              height: 100,
              child: _VehicleHorizontalList(
                vehicles: vehicles,
                selectedId: _selectedVehicle?.id,
                onSelect: _selectVehicle,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Marker Kendaraan ─────────────────────────────────────────────────────────

class _VehicleMarker extends StatelessWidget {
  final Vehicle vehicle;
  final StatusTheme theme;
  final bool isSelected;

  const _VehicleMarker({
    required this.vehicle,
    required this.theme,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: isSelected ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label plat nomor
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? Colors.indigo[600] : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? Colors.indigo[600]! : Colors.grey[300]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  vehicle.plateNumber,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.grey[800],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          // Ikon kendaraan
          Container(
            width: isSelected ? 44 : 36,
            height: isSelected ? 44 : 36,
            decoration: BoxDecoration(
              color: isSelected ? Colors.indigo[600] : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.color,
                width: isSelected ? 2.5 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSelected ? Colors.indigo : theme.color)
                      .withOpacity(0.35),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Icon(
              _iconForType(vehicle.vehicleType),
              size: isSelected ? 22 : 18,
              color: isSelected ? Colors.white : theme.color,
            ),
          ),
          // Jarum penunjuk
          CustomPaint(
            size: const Size(10, 6),
            painter: _MarkerNeedlePainter(
              color: isSelected ? Colors.indigo[600]! : Colors.white,
              borderColor: theme.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkerNeedlePainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  const _MarkerNeedlePainter(
      {required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Panel Detail Kendaraan ───────────────────────────────────────────────────

class _VehicleDetailPanel extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onClose;
  final VoidCallback onFollow;
  final bool isFollowing;

  const _VehicleDetailPanel({
    required this.vehicle,
    required this.onClose,
    required this.onFollow,
    required this.isFollowing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = statusThemes[vehicle.status] ?? statusThemes['idle']!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Baris atas
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForType(vehicle.vehicleType),
                  color: Colors.indigo[600],
                  size: 22,
                ),
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
                        fontSize: 15,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      vehicle.driverName,
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.color.withOpacity(0.3)),
                ),
                child: Text(
                  theme.label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: theme.color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onClose,
                child: Icon(Icons.close, color: Colors.grey[400], size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Koordinat & tombol follow
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.indigo[400], size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${vehicle.lat.toStringAsFixed(5)}, ${vehicle.lng.toStringAsFixed(5)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              GestureDetector(
                onTap: onFollow,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isFollowing
                        ? Colors.indigo[600]
                        : Colors.indigo[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.navigation,
                        color: isFollowing
                            ? Colors.white
                            : Colors.indigo[600],
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isFollowing ? 'Mengikuti' : 'Follow',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isFollowing
                              ? Colors.white
                              : Colors.indigo[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Info kendaraan
          if (vehicle.vehicleBrand.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _InfoBadge(
                  icon: Icons.directions_car_outlined,
                  label:
                      '${vehicle.vehicleBrand} ${vehicle.vehicleYear}',
                  color: Colors.teal,
                ),
                const SizedBox(width: 8),
                _InfoBadge(
                  icon: Icons.palette_outlined,
                  label: vehicle.vehicleColor,
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;

  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color[100]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color[700],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Daftar Armada Horizontal ─────────────────────────────────────────────────

class _VehicleHorizontalList extends StatelessWidget {
  final List<Vehicle> vehicles;
  final String? selectedId;
  final void Function(Vehicle) onSelect;

  const _VehicleHorizontalList({
    required this.vehicles,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final v = vehicles[index];
        final theme = statusThemes[v.status] ?? statusThemes['idle']!;
        final isSelected = v.id == selectedId;

        return GestureDetector(
          onTap: () => onSelect(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 160,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.indigo[600]
                  : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? Colors.indigo[600]!
                    : Colors.grey[200]!,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isSelected ? Colors.indigo : Colors.black)
                      .withOpacity(isSelected ? 0.25 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  v.plateNumber,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: isSelected
                        ? Colors.indigo[100]
                        : Colors.grey[500],
                  ),
                ),
                Text(
                  v.driverName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? Colors.white : Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withOpacity(0.2)
                        : theme.bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    theme.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? Colors.white : theme.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Tombol Kontrol Peta ──────────────────────────────────────────────────────

class _MapControlBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MapControlBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Icon(icon, color: Colors.grey[700], size: 20),
        ),
      ),
    );
  }
}