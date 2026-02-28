import 'package:flutter/material.dart';
import '../../../providers/fleet_provider.dart';
import '../../../utils/status_theme.dart';

class AdminMapTab extends StatelessWidget {
  final FleetProvider provider;
  const AdminMapTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Background Grid Simulation
            Container(
              decoration: BoxDecoration(
                color: Colors.indigo[50],
                image: DecorationImage(
                  image: const NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'), 
                  colorFilter: ColorFilter.mode(Colors.indigo.withOpacity(0.05), BlendMode.srcIn),
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
            
            // Vehicles on map
            ...provider.vehicles.map((v) {
              double leftPos = v.lng * constraints.maxWidth;
              double topPos = v.lat * constraints.maxHeight;

              return AnimatedPositioned(
                duration: const Duration(milliseconds: 1500),
                curve: Curves.linear,
                left: leftPos - 30, // Offset center
                top: topPos - 40,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.grey[300]!)),
                      child: Row(
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: statusThemes[v.status]!.color, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text(v.plateNumber, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: v.status == 'idle' ? Colors.blueGrey[400] : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                      ),
                      child: Icon(Icons.local_shipping, size: 24, color: v.status == 'idle' ? Colors.white : Colors.indigo[600]),
                    )
                  ],
                ),
              );
            }),

            // Horizontal List at the bottom
            Positioned(
              bottom: 20, left: 0, right: 0,
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: provider.vehicles.length,
                itemBuilder: (context, index) {
                  final v = provider.vehicles[index];
                  final theme = statusThemes[v.status]!;
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(v.plateNumber, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.bold)),
                        Text(v.driverName, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: theme.bgColor, borderRadius: BorderRadius.circular(12)),
                          child: Text(theme.label, style: TextStyle(fontSize: 10, color: theme.color, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        );
      }
    );
  }
}