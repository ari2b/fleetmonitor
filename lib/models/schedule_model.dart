import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  final String id;
  String title;
  String description;
  String driverId;
  String driverName;
  String vehicleId;
  String vehiclePlate;
  DateTime scheduleDate;
  String startTime;
  String endTime;
  String location;
  String status; // pending, confirmed, completed, cancelled
  final DateTime createdAt;

  Schedule({
    required this.id,
    required this.title,
    this.description = '',
    required this.driverId,
    this.driverName = '',
    this.vehicleId = '',
    this.vehiclePlate = '',
    required this.scheduleDate,
    this.startTime = '',
    this.endTime = '',
    this.location = '',
    this.status = 'pending',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Schedule.fromMap(String id, Map<String, dynamic> map) {
    return Schedule(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      driverId: map['driverId'] ?? '',
      driverName: map['driverName'] ?? '',
      vehicleId: map['vehicleId'] ?? '',
      vehiclePlate: map['vehiclePlate'] ?? '',
      scheduleDate: map['scheduleDate'] != null
          ? (map['scheduleDate'] as Timestamp).toDate()
          : DateTime.now(),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      location: map['location'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'driverId': driverId,
      'driverName': driverName,
      'vehicleId': vehicleId,
      'vehiclePlate': vehiclePlate,
      'scheduleDate': Timestamp.fromDate(scheduleDate),
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'status': status,
    };
  }
}