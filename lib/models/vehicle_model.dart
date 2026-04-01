class Vehicle {
  final String id;
  String driverName;
  String plateNumber;
  String vehicleType;   // jenis: Mobil, Truk, dll
  String vehicleBrand;  // merek: Toyota, Mitsubishi, dll
  int vehicleYear;      // tahun: 2020, 2021, dll
  String vehicleColor;  // warna: Putih, Hitam, dll
  String status;
  double lat;
  double lng;
  List<String> logs;

  Vehicle({
    required this.id,
    required this.driverName,
    required this.plateNumber,
    this.vehicleType = 'Mobil',
    this.vehicleBrand = '',
    this.vehicleYear = 2020,
    this.vehicleColor = '',
    this.status = 'idle',
    required this.lat,
    required this.lng,
    List<String>? logs,
  }) : logs = logs ?? [];

  /// Buat Vehicle dari dokumen Firestore
  factory Vehicle.fromMap(String id, Map<String, dynamic> map) {
    return Vehicle(
      id: id,
      driverName: map['driverName'] ?? '',
      plateNumber: map['plateNumber'] ?? '',
      vehicleType: map['vehicleType'] ?? 'Mobil',
      vehicleBrand: map['vehicleBrand'] ?? '',
      vehicleYear: (map['vehicleYear'] as num?)?.toInt() ?? 2020,
      vehicleColor: map['vehicleColor'] ?? '',
      status: map['status'] ?? 'idle',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.5,
      lng: (map['lng'] as num?)?.toDouble() ?? 0.5,
    );
  }

  /// Konversi ke Map untuk disimpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'driverName': driverName,
      'plateNumber': plateNumber,
      'vehicleType': vehicleType,
      'vehicleBrand': vehicleBrand,
      'vehicleYear': vehicleYear,
      'vehicleColor': vehicleColor,
      'status': status,
      'lat': lat,
      'lng': lng,
    };
  }
}