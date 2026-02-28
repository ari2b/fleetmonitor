class Vehicle {
  final String id;
  String driverName;     // mutable untuk edit
  String plateNumber;    // mutable untuk edit
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