import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/vehicle_model.dart';
import '../utils/status_theme.dart';

class FleetProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── State ─────────────────────────────────────────────
  List<Vehicle> vehicles = [];
  bool isLoadingVehicles = false;

  String? currentDriverId;
  bool isGpsActive = false;
  Timer? _gpsTimer;
  StreamSubscription<QuerySnapshot>? _vehiclesSubscription;

  /// UID Firebase Auth pengguna yang sedang login (untuk fitur profil driver)
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  // ─── Inisialisasi: stream kendaraan dari Firestore ─────
  FleetProvider() {
    _listenToVehicles();
  }

  /// Real-time listener ke koleksi 'vehicles' di Firestore.
  /// Setiap perubahan (tambah/edit/hapus) langsung tercermin di UI.
  void _listenToVehicles() {
    isLoadingVehicles = true;
    _vehiclesSubscription = _db
        .collection('vehicles')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen(
      (snapshot) {
        vehicles = snapshot.docs
            .map((d) => Vehicle.fromMap(d.id, d.data()))
            .toList();
        isLoadingVehicles = false;
        notifyListeners();
      },
      onError: (_) {
        isLoadingVehicles = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _vehiclesSubscription?.cancel();
    _gpsTimer?.cancel();
    super.dispose();
  }

  // ─── Auth ──────────────────────────────────────────────

  void loginAsDriver(String id) {
    currentDriverId = id;
    notifyListeners();
  }

  void loginAsDriverFromFirebase({
    required String uid,
    required String driverName,
    required String plateNumber,
    double lat = -7.6298,
    double lng = 111.5225,
  }) {
    // Pastikan kendaraan driver ada di list (Firestore stream mungkin belum
    // selesai saat login). Jika belum ada, tambahkan sementara.
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
          final deltaLat = (random.nextDouble() - 0.5) * 0.001;
          final deltaLng = (random.nextDouble() - 0.5) * 0.001;
          v.lat = (v.lat + deltaLat).clamp(-7.70, -7.58);
          v.lng = (v.lng + deltaLng).clamp(111.48, 111.58);
          v.heading = (atan2(deltaLng, deltaLat) * 180 / pi + 360) % 360;

          _db.collection('users').doc(currentDriverId).update({
            'lat': v.lat,
            'lng': v.lng,
            'heading': v.heading,
          }).catchError((_) {});

          notifyListeners();
        }
      }
    });
  }

  // ─── Update posisi GPS nyata ───────────────────────────
  void updateGpsPosition({
    required String id,
    required double lat,
    required double lng,
    double heading = 0,
  }) {
    final idx = vehicles.indexWhere((v) => v.id == id);
    if (idx != -1) {
      vehicles[idx].lat = lat;
      vehicles[idx].lng = lng;
      vehicles[idx].heading = heading;
      notifyListeners();

      _db.collection('users').doc(id).update({
        'lat': lat,
        'lng': lng,
        'heading': heading,
        'lastSeen': FieldValue.serverTimestamp(),
      }).catchError((_) {});
    }
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

  Future<void> addVehicle({
    required String driverName,
    required String plateNumber,
    required String vehicleType,
    required String vehicleBrand,
    required int vehicleYear,
    required String vehicleColor,
  }) async {
    final docRef = _db.collection('vehicles').doc();
    final random = Random();
    final newVehicle = Vehicle(
      id: docRef.id,
      driverName: driverName,
      plateNumber: plateNumber,
      vehicleType: vehicleType,
      vehicleBrand: vehicleBrand,
      vehicleYear: vehicleYear,
      vehicleColor: vehicleColor,
      lat: -7.6298 + (random.nextDouble() - 0.5) * 0.02,
      lng: 111.5225 + (random.nextDouble() - 0.5) * 0.02,
    );

    await docRef.set({
      ...newVehicle.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Tidak perlu push ke `vehicles` manual — stream Firestore akan update otomatis
  }

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

  Future<void> deleteVehicle(String id) async {
    vehicles.removeWhere((v) => v.id == id);
    if (currentDriverId == id) {
      currentDriverId = null;
      isGpsActive = false;
      _gpsTimer?.cancel();
    }

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