import 'package:firebase_auth/firebase_auth.dart';
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
        'provider': 'email',
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (role == 'driver' && plateNumber != null) {
        userData['plateNumber'] = plateNumber.trim().toUpperCase();
        userData['status'] = 'idle';
        userData['lat'] = 0.5;
        userData['lng'] = 0.5;
      }

      await _db.collection('users').doc(cred.user!.uid).set(userData);
      // Kembalikan uid — signOut dilakukan di UI setelah dialog sukses
      return {'success': true, 'uid': cred.user!.uid};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': _parseError(e.code)};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan. Coba lagi.'};
    }
  }

  // ─── Register Google ───────────────────────────────────
  // Hanya untuk user BARU. Jika sudah terdaftar → tolak & minta login.
  static Future<Map<String, dynamic>> registerWithGoogle({
    required String role,
    String? plateNumber, // wajib jika role == 'driver'
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
        'role': role,
        'provider': 'google',
        'photoUrl': cred.user!.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (role == 'driver') {
        userData['plateNumber'] = plateNumber!.trim().toUpperCase();
        userData['status'] = 'idle';
        userData['lat'] = 0.5;
        userData['lng'] = 0.5;
      }

      await _db.collection('users').doc(uid).set(userData);

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