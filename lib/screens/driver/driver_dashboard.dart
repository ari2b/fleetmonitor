import 'package:flutter/material.dart';
import '../../providers/fleet_provider.dart';
import '../auth/login_screen.dart';

class DriverDashboard extends StatelessWidget {
  final FleetProvider provider;
  const DriverDashboard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final curV = provider.currentVehicle;
    if (curV == null) return const Scaffold(body: Center(child: Text('Loading...')));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.indigo[600], borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(curV.driverName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                Text(curV.plateNumber, style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: Colors.grey[500])),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () {
              provider.logout();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AuthScreen(provider: provider)));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // GPS CARD
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.indigo[600]!, Colors.blue[700]!]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.indigo[100], size: 16),
                          const SizedBox(width: 4),
                          Text('Pelacakan GPS', style: TextStyle(color: Colors.indigo[100], fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: provider.isGpsActive ? Colors.greenAccent.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          provider.isGpsActive ? 'AKTIF' : 'NON-AKTIF',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: provider.isGpsActive ? Colors.greenAccent : Colors.white54),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Posisi Saat Ini', style: TextStyle(fontSize: 12, color: Colors.indigo[100])),
                          const SizedBox(height: 4),
                          Text('${curV.lat.toStringAsFixed(4)}, ${curV.lng.toStringAsFixed(4)}', 
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Colors.white)),
                        ],
                      ),
                      InkWell(
                        onTap: () => provider.toggleGps(),
                        child: Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: provider.isGpsActive ? Colors.white : Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: provider.isGpsActive ? 0 : 2)
                          ),
                          child: Icon(
                            provider.isGpsActive ? Icons.pause_circle_filled : Icons.play_arrow, 
                            color: provider.isGpsActive ? Colors.indigo[600] : Colors.white, 
                            size: 36
                          ),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // STATUS TITLE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('UPDATE STATUS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                if (!provider.isGpsActive)
                  const Row(children: [Icon(Icons.info, color: Colors.red, size: 12), SizedBox(width:4), Text('GPS OFF', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold))])
              ],
            ),
            const SizedBox(height: 12),

            // STATUS GRID
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _StatusBtn(
                  active: curV.status == 'berangkat',
                  icon: Icons.play_circle_outline,
                  label: 'Berangkat',
                  color: Colors.blue,
                  disabled: !provider.isGpsActive,
                  onTap: () => provider.updateStatus(curV.id, 'berangkat'),
                ),
                _StatusBtn(
                  active: curV.status == 'perjalanan',
                  icon: Icons.navigation_outlined,
                  label: 'Jalan',
                  color: Colors.teal,
                  disabled: !provider.isGpsActive,
                  onTap: () => provider.updateStatus(curV.id, 'perjalanan'),
                ),
                _StatusBtn(
                  active: curV.status == 'sampai',
                  icon: Icons.check_circle_outline,
                  label: 'Sampai',
                  color: Colors.orange,
                  disabled: false,
                  onTap: () => provider.updateStatus(curV.id, 'sampai'),
                ),
                _StatusBtn(
                  active: curV.status == 'idle',
                  icon: Icons.local_cafe_outlined,
                  label: 'Selesai',
                  color: Colors.blueGrey,
                  disabled: false,
                  onTap: () => provider.updateStatus(curV.id, 'idle'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _StatusBtn extends StatelessWidget {
  final bool active, disabled;
  final IconData icon;
  final String label;
  final MaterialColor color;
  final VoidCallback onTap;

  const _StatusBtn({required this.active, required this.disabled, required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: active ? color[600] : color[50],
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: active ? color[600]! : color[100]!),
          boxShadow: active ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Opacity(
          opacity: disabled ? 0.3 : 1.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: active ? Colors.white : color[600]),
              const SizedBox(height: 8),
              Text(label.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: active ? Colors.white : color[600])),
            ],
          ),
        ),
      ),
    );
  }
}