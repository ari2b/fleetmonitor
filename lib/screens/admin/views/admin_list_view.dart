import 'package:flutter/material.dart';
import '../../../providers/fleet_provider.dart';
import '../../../utils/status_theme.dart';

class AdminListTab extends StatelessWidget {
  final FleetProvider provider;
  const AdminListTab({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.vehicles.length,
      itemBuilder: (context, index) {
        final v = provider.vehicles[index];
        final theme = statusThemes[v.status]!;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(12)),
                    child: Icon(Icons.local_shipping, color: Colors.indigo[600]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.plateNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(v.driverName, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: theme.bgColor, border: Border.all(color: theme.color.withOpacity(0.3)), borderRadius: BorderRadius.circular(12)),
                    child: Text(theme.label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.color)),
                  )
                ],
              ),
              if (v.logs.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.history, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text('LOG TERKINI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1)),
                  ],
                ),
                const SizedBox(height: 8),
                ...v.logs.take(3).map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.indigo[200], shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(log, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                    ],
                  ),
                )),
              ]
            ],
          ),
        );
      },
    );
  }
}