class Vehicle {
  final String id;
  String driverName;
  String plateNumber;
  String vehicleType;
  String vehicleBrand;
  String vehicleModel;
  int vehicleYear;
  String vehicleColor;
  String status;
  double lat;
  double lng;
  double heading;
  String driverId; // Referensi ke dokumen drivers
  List<String> logs;

  Vehicle({
    required this.id,
    required this.driverName,
    required this.plateNumber,
    this.vehicleType = 'Mobil',
    this.vehicleBrand = '',
    this.vehicleModel = '',
    this.vehicleYear = 2020,
    this.vehicleColor = '',
    this.status = 'idle',
    required this.lat,
    required this.lng,
    this.heading = 0.0,
    this.driverId = '',
    List<String>? logs,
  }) : logs = logs ?? [];

  factory Vehicle.fromMap(String id, Map<String, dynamic> map) {
    return Vehicle(
      id: id,
      driverName: map['driverName'] ?? '',
      plateNumber: map['plateNumber'] ?? '',
      vehicleType: map['vehicleType'] ?? 'Mobil',
      vehicleBrand: map['vehicleBrand'] ?? '',
      vehicleModel: map['vehicleModel'] ?? '',
      vehicleYear: (map['vehicleYear'] as num?)?.toInt() ?? 2020,
      vehicleColor: map['vehicleColor'] ?? '',
      status: map['status'] ?? 'idle',
      lat: (map['lat'] as num?)?.toDouble() ?? -7.6298,
      lng: (map['lng'] as num?)?.toDouble() ?? 111.5225,
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      driverId: map['driverId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'driverName': driverName,
      'plateNumber': plateNumber,
      'vehicleType': vehicleType,
      'vehicleBrand': vehicleBrand,
      'vehicleModel': vehicleModel,
      'vehicleYear': vehicleYear,
      'vehicleColor': vehicleColor,
      'status': status,
      'lat': lat,
      'lng': lng,
      'heading': heading,
      'driverId': driverId,
    };
  }
}