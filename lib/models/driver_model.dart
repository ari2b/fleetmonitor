class Driver {
  final String id;
  String name;
  String email;
  String phone;
  String licenseNumber; // Nomor SIM
  String licenseType; // SIM A, B1, B2, C
  String status; // aktif, nonaktif
  String photoUrl;
  final DateTime createdAt;

  Driver({
    required this.id,
    required this.name,
    this.email = '',
    this.phone = '',
    this.licenseNumber = '',
    this.licenseType = 'SIM B1',
    this.status = 'aktif',
    this.photoUrl = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Driver.fromMap(String id, Map<String, dynamic> map) {
    return Driver(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      licenseNumber: map['licenseNumber'] ?? '',
      licenseType: map['licenseType'] ?? 'SIM B1',
      status: map['status'] ?? 'aktif',
      photoUrl: map['photoUrl'] ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'licenseNumber': licenseNumber,
      'licenseType': licenseType,
      'status': status,
      'photoUrl': photoUrl,
    };
  }
}