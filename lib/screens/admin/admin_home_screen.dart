import 'package:flutter/material.dart';
import '../../providers/fleet_provider.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';
import 'admin_dashboard.dart';

class AdminHomeScreen extends StatelessWidget {
  final FleetProvider provider;
  const AdminHomeScreen({super.key, required this.provider});

  Future<void> _handleLogout(BuildContext context) async {
    await AuthService.logout();
    provider.logout();
    if (!context.mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => AuthScreen(provider: provider)),
      (route) => false,
    );
  }

  void _goToTab(BuildContext context, int tabIndex) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => AdminDashboard(
          provider: provider,
          initialTabIndex: tabIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo[700]!, Colors.indigo[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.monitor_heart,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Fleet Monitor',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20)),
                        Text('Panel Administrator',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12)),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white70),
                      tooltip: 'Logout',
                      onPressed: () => _handleLogout(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Greeting ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withOpacity(0.4), width: 2),
                      ),
                      child: const Icon(Icons.admin_panel_settings_rounded,
                          color: Colors.white, size: 36),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Selamat Datang, Admin!',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pilih menu yang ingin Anda akses',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.7), fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // ── Menu Cards ────────────────────────────────
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MENU UTAMA',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _MenuCard(
                        icon: Icons.map_rounded,
                        title: 'Peta Live',
                        subtitle: 'Pantau posisi armada secara real-time',
                        color: Colors.blue,
                        onTap: () => _goToTab(context, 0),
                      ),
                      const SizedBox(height: 14),
                      _MenuCard(
                        icon: Icons.local_shipping_rounded,
                        title: 'Daftar Armada',
                        subtitle: 'Lihat status dan log seluruh kendaraan',
                        color: Colors.teal,
                        onTap: () => _goToTab(context, 1),
                      ),
                      const SizedBox(height: 14),
                      _MenuCard(
                        icon: Icons.manage_accounts_rounded,
                        title: 'Kelola Armada',
                        subtitle: 'Tambah, edit, dan hapus driver & kendaraan',
                        color: Colors.indigo,
                        onTap: () => _goToTab(context, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final MaterialColor color;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color[100]!),
                ),
                child: Icon(icon, color: color[600], size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.grey[300], size: 16),
            ],
          ),
        ),
      ),
    );
  }
}