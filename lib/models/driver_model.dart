class Driver {
  final String id;
  String name;
  String email;
  String phone;
  String status; // aktif, nonaktif
  String photoUrl;
  final DateTime createdAt;

  Driver({
    required this.id,
    required this.name,
    this.email = '',
    this.phone = '',
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
      'status': status,
      'photoUrl': photoUrl,
    };
  }
}