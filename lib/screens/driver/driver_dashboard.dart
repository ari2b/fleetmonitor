import 'package:flutter/material.dart';
import '../../providers/fleet_provider.dart';
import '../auth/login_screen.dart';

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
                  // Avatar icon
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
                    child: const Icon(Icons.person, color: Colors.white, size: 20),
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
                // ─── GPS Card ───────────────────────────────────
                _GpsCard(provider: provider, vehicle: curV),
                const SizedBox(height: 24),

                // ─── Status Grid ────────────────────────────────
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
                      onTap: () => provider.updateStatus(curV.id, 'berangkat'),
                    ),
                    _StatusAction(
                      active: curV.status == 'perjalanan',
                      icon: Icons.navigation_rounded,
                      label: 'Jalan',
                      color: Colors.teal,
                      disabled: !provider.isGpsActive,
                      onTap: () => provider.updateStatus(curV.id, 'perjalanan'),
                    ),
                    _StatusAction(
                      active: curV.status == 'sampai',
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Sampai',
                      color: Colors.orange,
                      disabled: false,
                      onTap: () => provider.updateStatus(curV.id, 'sampai'),
                    ),
                    _StatusAction(
                      active: curV.status == 'idle',
                      icon: Icons.local_cafe_outlined,
                      label: 'Selesai',
                      color: Colors.blueGrey,
                      disabled: false,
                      onTap: () => provider.updateStatus(curV.id, 'idle'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ─── Route Info ─────────────────────────────────
                _RouteInfoCard(),
              ],
            ),
          ),

          // ─── Bottom Nav ─────────────────────────────────────
          bottomNavigationBar: _BottomNav(),
        );
      },
    );
  }
}

// ─── GPS Card ─────────────────────────────────────────────────────────────────
class _GpsCard extends StatelessWidget {
  final FleetProvider provider;
  final dynamic vehicle;

  const _GpsCard({required this.provider, required this.vehicle});

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
          // Background icon dekorasi
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
              // Row 1: label & badge aktif
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: provider.isGpsActive
                          ? Colors.greenAccent.withOpacity(0.2)
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      provider.isGpsActive ? 'AKTIF' : 'NON-AKTIF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: provider.isGpsActive
                            ? Colors.greenAccent
                            : Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Row 2: koordinat & tombol play
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
                        '${vehicle.lat.toStringAsFixed(4)}, ${vehicle.lng.toStringAsFixed(4)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => provider.toggleGps(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: provider.isGpsActive
                            ? Colors.white
                            : Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: provider.isGpsActive ? 0 : 2,
                        ),
                      ),
                      child: Icon(
                        provider.isGpsActive
                            ? Icons.pause_circle_filled_rounded
                            : Icons.play_arrow_rounded,
                        color: provider.isGpsActive
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

// ─── Route Info Card ──────────────────────────────────────────────────────────
class _RouteInfoCard extends StatelessWidget {
  const _RouteInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.location_on, color: Colors.blue[600], size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cek Rute Tujuan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Gudang A • 12.5 KM Lagi',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[300]),
        ],
      ),
    );
  }
}

// ─── Bottom Navigation Bar ───────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  const _BottomNav();

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
            icon: Icons.local_shipping,
            label: 'Driver',
            active: true,
          ),
          _NavItem(
            icon: Icons.notifications_none_rounded,
            label: 'Notif',
            active: false,
          ),
          _NavItem(
            icon: Icons.settings_outlined,
            label: 'Pengaturan',
            active: false,
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

  const _NavItem(
      {required this.icon, required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.indigo[600]! : Colors.grey[400]!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}