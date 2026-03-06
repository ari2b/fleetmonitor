import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Stream<User?> get userStream => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  // ─── Register ─────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required String role, // 'admin' | 'driver'
    String? plateNumber,
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
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (role == 'driver' && plateNumber != null) {
        userData['plateNumber'] = plateNumber.trim().toUpperCase();
        userData['status'] = 'idle';
        userData['lat'] = 0.5;
        userData['lng'] = 0.5;
      }

      // Simpan ke Firestore collection 'users'
      await _db.collection('users').doc(cred.user!.uid).set(userData);

      // Langsung sign out agar user login manual
      await _auth.signOut();

      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _parseError(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan. Coba lagi.'};
    }
  }

  // ─── Login ────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final doc =
          await _db.collection('users').doc(cred.user!.uid).get();

      if (!doc.exists) {
        await _auth.signOut();
        return {
          'success': false,
          'message': 'Data akun tidak ditemukan di database.'
        };
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

  // ─── Logout ───────────────────────────────────────────
  static Future<void> logout() async => await _auth.signOut();

  // ─── Get user data ────────────────────────────────────
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (_) {
      return null;
    }
  }

  // ─── Parse Firebase error ke Bahasa Indonesia ─────────
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
      default:
        return 'Gagal: $code';
    }
  }
}