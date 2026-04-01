import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vehicle_model.dart';
import '../utils/status_theme.dart';

class FleetProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<Vehicle> vehicles = [
    Vehicle(
      id: 'v1',
      driverName: 'Budi Santoso',
      plateNumber: 'B 1234 CD',
      vehicleType: 'Mobil',
      vehicleBrand: 'Toyota',
      vehicleYear: 2021,
      vehicleColor: 'Putih',
      lat: 0.25,
      lng: 0.35,
    ),
    Vehicle(
      id: 'v2',
      driverName: 'Agus Setiawan',
      plateNumber: 'D 5678 EF',
      vehicleType: 'Mobil',
      vehicleBrand: 'Mitsubishi',
      vehicleYear: 2020,
      vehicleColor: 'Hitam',
      lat: 0.65,
      lng: 0.75,
    ),
    Vehicle(
      id: 'v3',
      driverName: 'Rina Kartika',
      plateNumber: 'L 9012 GH',
      vehicleType: 'Mobil',
      vehicleBrand: 'Daihatsu',
      vehicleYear: 2022,
      vehicleColor: 'Silver',
      lat: 0.45,
      lng: 0.55,
    ),
  ];

  String? currentDriverId;
  bool isGpsActive = false;
  Timer? _gpsTimer;

  // ─── Auth ──────────────────────────────────────────────

  void loginAsDriver(String id) {
    currentDriverId = id;
    notifyListeners();
  }

  void loginAsDriverFromFirebase({
    required String uid,
    required String driverName,
    required String plateNumber,
    double lat = 0.5,
    double lng = 0.5,
  }) {
    final idx = vehicles.indexWhere((v) => v.id == uid);
    if (idx == -1) {
      vehicles.add(Vehicle(
        id: uid,
        driverName: driverName,
        plateNumber: plateNumber,
        lat: lat,
        lng: lng,
      ));
    } else {
      vehicles[idx].driverName = driverName;
      vehicles[idx].plateNumber = plateNumber;
    }
    currentDriverId = uid;
    notifyListeners();
  }

  void logout() {
    currentDriverId = null;
    isGpsActive = false;
    _gpsTimer?.cancel();
    notifyListeners();
  }

  // ─── GPS ───────────────────────────────────────────────

  void toggleGps() {
    isGpsActive = !isGpsActive;
    if (isGpsActive) {
      _startGpsSimulation();
    } else {
      _gpsTimer?.cancel();
    }
    notifyListeners();
  }

  void _startGpsSimulation() {
    final random = Random();
    _gpsTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (currentDriverId == null || !isGpsActive) {
        timer.cancel();
        return;
      }
      final idx = vehicles.indexWhere((v) => v.id == currentDriverId);
      if (idx != -1) {
        final v = vehicles[idx];
        if (v.status == 'berangkat' || v.status == 'perjalanan') {
          v.lat = min(max(v.lat + (random.nextDouble() - 0.5) * 0.02, 0.1), 0.9);
          v.lng = min(max(v.lng + (random.nextDouble() - 0.5) * 0.02, 0.1), 0.9);
          notifyListeners();
        }
      }
    });
  }

  // ─── Status ────────────────────────────────────────────

  void updateStatus(String id, String newStatus) {
    final idx = vehicles.indexWhere((v) => v.id == id);
    if (idx != -1) {
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      vehicles[idx].status = newStatus;
      vehicles[idx].logs.insert(0, '$timeStr - ${statusThemes[newStatus]!.label}');
      if (vehicles[idx].logs.length > 10) vehicles[idx].logs.removeLast();
      notifyListeners();
    }
  }

  // ─── CRUD + Firestore ──────────────────────────────────

  /// Tambah armada baru — simpan ke Firestore
  Future<void> addVehicle({
    required String driverName,
    required String plateNumber,
    required String vehicleType,
    required String vehicleBrand,
    required int vehicleYear,
    required String vehicleColor,
  }) async {
    final docRef = _db.collection('vehicles').doc();
    final newVehicle = Vehicle(
      id: docRef.id,
      driverName: driverName,
      plateNumber: plateNumber,
      vehicleType: vehicleType,
      vehicleBrand: vehicleBrand,
      vehicleYear: vehicleYear,
      vehicleColor: vehicleColor,
      lat: 0.4 + (Random().nextDouble() * 0.2),
      lng: 0.4 + (Random().nextDouble() * 0.2),
    );

    // Simpan ke Firestore
    await docRef.set({
      ...newVehicle.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    vehicles.add(newVehicle);
    notifyListeners();
  }

  /// Update data armada — update ke Firestore
  Future<void> updateVehicleData({
    required String id,
    required String driverName,
    required String plateNumber,
    required String vehicleType,
    required String vehicleBrand,
    required int vehicleYear,
    required String vehicleColor,
  }) async {
    final idx = vehicles.indexWhere((v) => v.id == id);
    if (idx != -1) {
      vehicles[idx].driverName = driverName;
      vehicles[idx].plateNumber = plateNumber;
      vehicles[idx].vehicleType = vehicleType;
      vehicles[idx].vehicleBrand = vehicleBrand;
      vehicles[idx].vehicleYear = vehicleYear;
      vehicles[idx].vehicleColor = vehicleColor;

      // Update ke Firestore (fire-and-forget, tidak perlu await di UI)
      _db.collection('vehicles').doc(id).update({
        'driverName': driverName,
        'plateNumber': plateNumber,
        'vehicleType': vehicleType,
        'vehicleBrand': vehicleBrand,
        'vehicleYear': vehicleYear,
        'vehicleColor': vehicleColor,
      }).catchError((_) {});

      notifyListeners();
    }
  }

  /// Hapus armada — hapus dari Firestore
  Future<void> deleteVehicle(String id) async {
    vehicles.removeWhere((v) => v.id == id);
    if (currentDriverId == id) {
      currentDriverId = null;
      isGpsActive = false;
      _gpsTimer?.cancel();
    }

    // Hapus dari Firestore
    _db.collection('vehicles').doc(id).delete().catchError((_) {});

    notifyListeners();
  }

  // ─── Getter ────────────────────────────────────────────

  Vehicle? get currentVehicle {
    try {
      return vehicles.firstWhere((v) => v.id == currentDriverId);
    } catch (_) {
      return null;
    }
  }
}