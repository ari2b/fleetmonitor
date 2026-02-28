import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import '../models/vehicle_model.dart';
import '../utils/status_theme.dart';

class FleetProvider extends ChangeNotifier {
  List<Vehicle> vehicles = [
    Vehicle(id: 'v1', driverName: 'Budi Santoso', plateNumber: 'B 1234 CD', lat: 0.25, lng: 0.35),
    Vehicle(id: 'v2', driverName: 'Agus Setiawan', plateNumber: 'D 5678 EF', lat: 0.65, lng: 0.75),
    Vehicle(id: 'v3', driverName: 'Rina Kartika', plateNumber: 'L 9012 GH', lat: 0.45, lng: 0.55),
  ];

  String? currentDriverId;
  bool isGpsActive = false;
  Timer? _gpsTimer;

  // ─── Auth ─────────────────────────────────────────────
  void loginAsDriver(String id) {
    currentDriverId = id;
    notifyListeners();
  }

  void logout() {
    currentDriverId = null;
    isGpsActive = false;
    _gpsTimer?.cancel();
    notifyListeners();
  }

  // ─── GPS ──────────────────────────────────────────────
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

  // ─── Status ───────────────────────────────────────────
  void updateStatus(String id, String newStatus) {
    final idx = vehicles.indexWhere((v) => v.id == id);
    if (idx != -1) {
      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      vehicles[idx].status = newStatus;
      vehicles[idx].logs
          .insert(0, '$timeStr - ${statusThemes[newStatus]!.label}');
      if (vehicles[idx].logs.length > 10) vehicles[idx].logs.removeLast();
      notifyListeners();
    }
  }

  // ─── CRUD ─────────────────────────────────────────────

  /// Tambah armada baru
  void addVehicle(String driverName, String plateNumber) {
    final newVehicle = Vehicle(
      id: 'v${DateTime.now().millisecondsSinceEpoch}',
      driverName: driverName,
      plateNumber: plateNumber,
      lat: 0.4 + (Random().nextDouble() * 0.2),
      lng: 0.4 + (Random().nextDouble() * 0.2),
    );
    vehicles.add(newVehicle);
    notifyListeners();
  }

  /// Update nama driver & plat nomor
  void updateVehicleData(String id, String driverName, String plateNumber) {
    final idx = vehicles.indexWhere((v) => v.id == id);
    if (idx != -1) {
      vehicles[idx].driverName = driverName;
      vehicles[idx].plateNumber = plateNumber;
      notifyListeners();
    }
  }

  /// Hapus armada berdasarkan id
  void deleteVehicle(String id) {
    vehicles.removeWhere((v) => v.id == id);
    // Jika driver yang login dihapus, logout otomatis
    if (currentDriverId == id) {
      currentDriverId = null;
      isGpsActive = false;
      _gpsTimer?.cancel();
    }
    notifyListeners();
  }

  // ─── Getter ───────────────────────────────────────────
  Vehicle? get currentVehicle {
    try {
      return vehicles.firstWhere((v) => v.id == currentDriverId);
    } catch (_) {
      return null;
    }
  }
}