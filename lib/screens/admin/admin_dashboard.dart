import 'package:flutter/material.dart';
import '../../providers/fleet_provider.dart';
import 'views/admin_map_view.dart';
import 'views/admin_list_view.dart';

class AdminDashboard extends StatelessWidget {
  final FleetProvider provider;
  const AdminDashboard({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.indigo[600],
          elevation: 0,
          leading: const Icon(Icons.monitor_heart, color: Colors.white),
          title: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monitoring Panel', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Text('Total 3 Armada Aktif', style: TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                provider.logout();
                Navigator.pop(context);
              },
            )
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.indigo[600],
            unselectedLabelColor: Colors.white70,
            indicator: const BoxDecoration(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              color: Colors.white,
            ),
            tabs: const [
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.map, size: 18), SizedBox(width: 8), Text('Peta Live')])),
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.list, size: 18), SizedBox(width: 8), Text('Daftar Armada')])),
            ],
          ),
        ),
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(), // Disable swipe agar tidak bentrok dengan map panning nanti
          children: [
            AdminMapTab(provider: provider),
            AdminListTab(provider: provider),
          ],
        ),
      ),
    );
  }
}