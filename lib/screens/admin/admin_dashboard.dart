import 'package:flutter/material.dart';
import '../../providers/fleet_provider.dart';
import 'views/admin_map_view.dart';
import 'views/admin_list_view.dart';
import 'views/admin_kelola_view.dart';

class AdminDashboard extends StatefulWidget {
  final FleetProvider provider;
  const AdminDashboard({super.key, required this.provider});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo[600],
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.only(left: 12),
          child: Icon(Icons.monitor_heart, color: Colors.white),
        ),
        title: ListenableBuilder(
          listenable: widget.provider,
          builder: (context, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monitoring Panel',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              Text(
                'Total ${widget.provider.vehicles.length} Armada Terdaftar',
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              widget.provider.logout();
              Navigator.pop(context);
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.indigo[600],
          unselectedLabelColor: Colors.white70,
          indicator: const BoxDecoration(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            color: Colors.white,
          ),
          tabs: const [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 16),
                  SizedBox(width: 6),
                  Text('Peta Live', style: TextStyle(fontSize: 13))
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.list, size: 16),
                  SizedBox(width: 6),
                  Text('Armada', style: TextStyle(fontSize: 13))
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storage, size: 16),
                  SizedBox(width: 6),
                  Text('Kelola', style: TextStyle(fontSize: 13))
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          AdminMapTab(provider: widget.provider),
          AdminListTab(provider: widget.provider),
          AdminKelolaTab(provider: widget.provider),
        ],
      ),
    );
  }
}