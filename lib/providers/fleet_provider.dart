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

  void toggleGps() {
    isGpsActive = !isGpsActive;
    if (isGpsActive) {
      _startGpsSimulation();
    } else {
      _gpsTimer?.cancel();
    }
    notifyListeners();
  }

  void updateStatus(String id, String newStatus) {
    final vehicleIndex = vehicles.indexWhere((v) => v.id == id);
    if (vehicleIndex != -1) {
      final now = DateTime.now();
      final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      vehicles[vehicleIndex].status = newStatus;
      vehicles[vehicleIndex].logs.insert(0, '$timeStr - ${statusThemes[newStatus]!.label}');
      
      // Keep only last 10 logs
      if (vehicles[vehicleIndex].logs.length > 10) {
        vehicles[vehicleIndex].logs.removeLast();
      }
      notifyListeners();
    }
  }

  void _startGpsSimulation() {
    final random = Random();
    _gpsTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (currentDriverId == null || !isGpsActive) {
        timer.cancel();
        return;
      }

      final vehicleIndex = vehicles.indexWhere((v) => v.id == currentDriverId);
      if (vehicleIndex != -1) {
        final v = vehicles[vehicleIndex];
        if (v.status == 'berangkat' || v.status == 'perjalanan') {
          double moveLat = (random.nextDouble() - 0.5) * 0.02;
          double moveLng = (random.nextDouble() - 0.5) * 0.02;
          
          v.lat = min(max(v.lat + moveLat, 0.1), 0.9);
          v.lng = min(max(v.lng + moveLng, 0.1), 0.9);
          notifyListeners();
        }
      }
    });
  }

  Vehicle? get currentVehicle {
    try {
      return vehicles.firstWhere((v) => v.id == currentDriverId);
    } catch (e) {
      return null;
    }
  }
}