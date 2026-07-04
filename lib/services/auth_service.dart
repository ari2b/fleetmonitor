import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static Stream<User?> get userStream => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  // ─── Register Email/Password ──────────────────────────
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? phone,
    String? plateNumber,
    String? vehicleType,
    String? vehicleBrand,
    String? vehicleModel,
    String? vehicleColor,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user!.updateDisplayName(name.trim());

      final Map<String, dynamic> userData = {
        'uid': cred.user!.uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone?.trim() ?? '',
        'role': role,
        'provider': 'email',
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (role == 'driver' && plateNumber != null) {
        userData['plateNumber'] = plateNumber.trim().toUpperCase();
        userData['vehicleType'] = vehicleType ?? 'Mobil';
        userData['vehicleBrand'] = vehicleBrand ?? '';
        userData['vehicleModel'] = vehicleModel ?? '';
        userData['vehicleColor'] = vehicleColor ?? '';
        userData['status'] = 'idle';
        userData['lat'] = 0.5;
        userData['lng'] = 0.5;
      }

      await _db.collection('users').doc(cred.user!.uid).set(userData);

      // Sinkronkan juga ke koleksi 'drivers' & 'vehicles' supaya driver
      // yang mendaftar sendiri langsung muncul di tampilan Kelola admin
      // (Master Data Driver, jumlah kendaraan, dropdown armada, dll).
      if (role == 'driver') {
        await _syncDriverAndVehicle(
          uid: cred.user!.uid,
          name: name.trim(),
          email: email.trim(),
          phone: phone ?? '',
          plateNumber: plateNumber,
          vehicleType: vehicleType,
          vehicleBrand: vehicleBrand,
          vehicleModel: vehicleModel,
          vehicleColor: vehicleColor,
        );
      }

      // Kembalikan uid — signOut dilakukan di UI setelah dialog sukses
      return {'success': true, 'uid': cred.user!.uid};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _parseError(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan. Coba lagi.'};
    }
  }

  // ─── Sync driver self-register ke koleksi drivers & vehicles ──
  static Future<void> _syncDriverAndVehicle({
    required String uid,
    required String name,
    required String email,
    String phone = '',
    String? plateNumber,
    String? vehicleType,
    String? vehicleBrand,
    String? vehicleModel,
    String? vehicleColor,
  }) async {
    try {
      // 'drivers' — master data driver yang dibaca tampilan Kelola admin
      await _db.collection('drivers').doc(uid).set({
        'name': name,
        'email': email,
        'phone': phone,
        'status': 'aktif',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 'vehicles' — supaya kendaraan yang diisi saat registrasi langsung
      // terhitung & muncul di dropdown Armada.
      if (plateNumber != null && plateNumber.trim().isNotEmpty) {
        await _db.collection('vehicles').doc(uid).set({
          'driverId': uid,
          'driverName': name,
          'plateNumber': plateNumber.trim().toUpperCase(),
          'vehicleType': vehicleType ?? 'Mobil',
          'vehicleBrand': vehicleBrand ?? '',
          'vehicleModel': vehicleModel ?? '',
          'vehicleYear': DateTime.now().year,
          'vehicleColor': vehicleColor ?? '',
          'status': 'idle',
          'lat': 0.5,
          'lng': 0.5,
          'heading': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ _syncDriverAndVehicle gagal: $e');
    }
  }

  // ─── Register Google ───────────────────────────────────
  // Hanya untuk user BARU. Jika sudah terdaftar → tolak & minta login.
  static Future<Map<String, dynamic>> registerWithGoogle({
    required String role,
    String? phone,
    String? plateNumber,
    String? vehicleType,
    String? vehicleBrand,
    String? vehicleModel,
    String? vehicleColor,
  }) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Registrasi Google dibatalkan.'};
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final uid = cred.user!.uid;

      // Cek apakah sudah pernah terdaftar
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        // Sudah terdaftar → tolak registrasi, minta login
        await _auth.signOut();
        await _googleSignIn.signOut();
        return {
          'success': false,
          'alreadyRegistered': true,
          'message': 'Akun Google ini sudah terdaftar. Silakan gunakan tombol Login.',
        };
      }

      // Driver baru → wajib ada plat nomor
      if (role == 'driver' && (plateNumber == null || plateNumber.trim().isEmpty)) {
        // Belum ada plat → kembalikan data Google agar UI bisa minta plat
        return {
          'success': false,
          'needPlate': true,
          'googleUser': {
            'uid': uid,
            'name': cred.user!.displayName ?? '',
            'email': cred.user!.email ?? '',
          },
        };
      }

      // Buat dokumen Firestore
      final Map<String, dynamic> userData = {
        'uid': uid,
        'name': cred.user!.displayName ?? googleUser.displayName ?? '',
        'email': cred.user!.email ?? googleUser.email,
        'phone': phone?.trim() ?? '',
        'role': role,
        'provider': 'google',
        'photoUrl': cred.user!.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (role == 'driver') {
        userData['plateNumber'] = plateNumber!.trim().toUpperCase();
        userData['vehicleType'] = vehicleType ?? 'Mobil';
        userData['vehicleBrand'] = vehicleBrand ?? '';
        userData['vehicleModel'] = vehicleModel ?? '';
        userData['vehicleColor'] = vehicleColor ?? '';
        userData['status'] = 'idle';
        userData['lat'] = 0.5;
        userData['lng'] = 0.5;
      }

      await _db.collection('users').doc(uid).set(userData);

      // Sinkronkan juga ke koleksi 'drivers' & 'vehicles' (lihat penjelasan
      // di _syncDriverAndVehicle) supaya konsisten dengan registrasi manual.
      if (role == 'driver') {
        await _syncDriverAndVehicle(
          uid: uid,
          name: cred.user!.displayName ?? googleUser.displayName ?? '',
          email: cred.user!.email ?? googleUser.email ?? '',
          phone: phone ?? '',
          plateNumber: plateNumber,
          vehicleType: vehicleType,
          vehicleBrand: vehicleBrand,
          vehicleModel: vehicleModel,
          vehicleColor: vehicleColor,
        );
      }

      // Sign out setelah registrasi — user diminta login manual
      await _auth.signOut();
      await _googleSignIn.signOut();

      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _parseError(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Google Sign-In gagal. Coba lagi.'};
    }
  }

  // ─── Admin Membuat Akun Driver Baru ───────────────────
  // Dipakai admin untuk mendaftarkan driver dari dalam aplikasi.
  // Memakai secondary Firebase App instance supaya createUser tidak
  // menggantikan sesi login admin yang sedang aktif (createUser di
  // instance default akan otomatis sign-in sebagai user baru).
  static Future<Map<String, dynamic>> adminCreateDriver({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String status = 'aktif',
  }) async {
    FirebaseApp? secondaryApp;
    try {
      // Buat/gunakan secondary app instance bernama unik
      try {
        secondaryApp = Firebase.app('AdminCreateDriver');
      } catch (_) {
        secondaryApp = await Firebase.initializeApp(
          name: 'AdminCreateDriver',
          options: Firebase.app().options,
        );
      }

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user!.updateDisplayName(name.trim());
      final uid = cred.user!.uid;

      // Simpan dokumen 'drivers' (master data) dan 'users' (profile login)
      // dengan id yang sama (uid) agar driver bisa langsung login.
      final driverData = {
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await _db.collection('drivers').doc(uid).set(driverData);
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': 'driver',
        'provider': 'email',
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sign out dari secondary app supaya tidak menumpuk sesi
      await secondaryAuth.signOut();

      return {'success': true, 'uid': uid};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _parseError(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Gagal membuat akun driver: $e'};
    }
  }

  // ─── Login Email/Password ─────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final doc = await _db.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists) {
        await _auth.signOut();
        return {'success': false, 'message': 'Data akun tidak ditemukan.'};
      }
      return {
        'success': true,
        'uid': cred.user!.uid,
        'role': doc.data()!['role'] as String,
        'data': doc.data(),
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _parseError(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan. Coba lagi.'};
    }
  }

  // ─── Login Google ─────────────────────────────────────
  // Hanya untuk user yang SUDAH terdaftar.
  // Mendukung 2 skenario:
  // 1. Akun pernah daftar via Google → UID di Firestore cocok
  // 2. Akun dibuat via email (AdminSeeder) → cari by email,
  //    lalu link akun Google ke akun yang sudah ada
  static Future<Map<String, dynamic>> loginWithGoogle({
    required String role,
  }) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Login Google dibatalkan.'};
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      final uid = cred.user!.uid;
      final email = cred.user!.email ?? googleUser.email;

      // ── Cek 1: dokumen Firestore berdasarkan UID Google ──
      var doc = await _db.collection('users').doc(uid).get();

      // ── Cek 2: jika tidak ketemu by UID, cari by email ──
      // Kasus: dokumen admin dibuat via AdminSeeder dengan placeholder UID,
      // lalu user pertama kali login pakai Google → migrate ke UID Google
      if (!doc.exists) {
        final byEmail = await _db
            .collection('users')
            .where('email', isEqualTo: email)
            .where('role', isEqualTo: role)
            .limit(1)
            .get();

        if (byEmail.docs.isNotEmpty) {
          // Dokumen ditemukan by email → migrate ke UID Google
          final oldData = byEmail.docs.first.data();
          final newData = Map<String, dynamic>.from(oldData);
          newData['uid'] = uid;
          newData['provider'] = 'google';
          newData['photoUrl'] = cred.user!.photoURL ?? '';

          // Buat dokumen baru dengan UID Google yang benar
          await _db.collection('users').doc(uid).set(newData);

          // Hapus dokumen placeholder lama
          if (byEmail.docs.first.id != uid) {
            await _db.collection('users').doc(byEmail.docs.first.id).delete();
          }

          // Ambil dokumen baru yang sudah di-migrate
          doc = await _db.collection('users').doc(uid).get();
        }
      }

      // ── Tidak ditemukan sama sekali ──
      if (!doc.exists) {
        await _auth.signOut();
        await _googleSignIn.signOut();
        return {
          'success': false,
          'notRegistered': true,
          'message': 'Akun Google ini belum terdaftar. Silakan daftar terlebih dahulu.',
        };
      }

      // ── Cek role cocok ──
      final existingRole = doc.data()!['role'] as String;
      if (existingRole != role) {
        await _auth.signOut();
        await _googleSignIn.signOut();
        return {
          'success': false,
          'message':
              'Akun ini terdaftar sebagai ${existingRole == 'admin' ? 'Admin' : 'Driver'}. '
              'Silakan pilih role yang sesuai.',
        };
      }

      return {
        'success': true,
        'uid': uid,
        'role': existingRole,
        'data': doc.data(),
      };
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _parseError(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Google Sign-In gagal. Coba lagi.'};
    }
  }

  // ─── Logout ───────────────────────────────────────────
  static Future<void> logout() async {
    await _auth.signOut();
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
  }

  // ─── Get user data ────────────────────────────────────
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (_) {
      return null;
    }
  }

  // ─── Parse error ──────────────────────────────────────
  static String _parseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email sudah digunakan akun lain.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'weak-password':
        return 'Password minimal 6 karakter.';
      case 'user-not-found':
        return 'Email tidak terdaftar.';
      case 'wrong-password':
        return 'Password salah.';
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba beberapa saat lagi.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan.';
      case 'account-exists-with-different-credential':
        return 'Email ini sudah terdaftar dengan metode login lain.';
      default:
        return 'Gagal: $code';
    }
  }
}