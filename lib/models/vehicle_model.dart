class Vehicle {
  final String id;
  final String driverName;
  final String plateNumber;
  String status;
  double lat;
  double lng;
  List<String> logs;

  Vehicle({
    required this.id,
    required this.driverName,
    required this.plateNumber,
    this.status = 'idle',
    required this.lat,
    required this.lng,
    List<String>? logs,
  }) : logs = logs ?? [];
}