import 'package:flutter/material.dart';
import '../../providers/fleet_provider.dart';
import '../../services/auth_service.dart';
import '../admin/admin_dashboard.dart';
import '../driver/driver_dashboard.dart';
import 'register_screen.dart';

class AuthScreen extends StatelessWidget {
  final FleetProvider provider;
  const AuthScreen({super.key, required this.provider});

  void _showLoginSheet(BuildContext context, String role) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LoginBottomSheet(role: role, provider: provider),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header biru ──────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.indigo[600],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.local_shipping, size: 48, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text('Fleet Monitor',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Manajemen Armada Real-time',
                          style: TextStyle(color: Colors.indigo[100])),
                    ],
                  ),
                ),

                // ── Tombol role ──────────────────────────
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.security, color: Colors.white),
                        label: const Text('Masuk sebagai Admin',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[600],
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () => _showLoginSheet(context, 'admin'),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: Icon(Icons.person, color: Colors.indigo[600]),
                        label: Text('Masuk sebagai Driver',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo[600])),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          side: BorderSide(color: Colors.indigo[100]!, width: 2),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => _showLoginSheet(context, 'driver'),
                      ),
                      const SizedBox(height: 24),
                      Text('Versi 2.0.4 • © 2024 Fleet System',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Bottom Sheet Login
// ════════════════════════════════════════════════════════════════════════════
class _LoginBottomSheet extends StatefulWidget {
  final String role;
  final FleetProvider provider;
  const _LoginBottomSheet({required this.role, required this.provider});

  @override
  State<_LoginBottomSheet> createState() => _LoginBottomSheetState();
}

class _LoginBottomSheetState extends State<_LoginBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _obscure = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMsg;

  bool get isAdmin => widget.role == 'admin';
  Color get accent => isAdmin ? Colors.indigo[600]! : Colors.teal[600]!;
  Color get accentLight => isAdmin ? Colors.indigo[50]! : Colors.teal[50]!;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ── Navigasi ke dashboard ─────────────────────────────
  void _goToDashboard(Map<String, dynamic> result) {
    final role = result['role'] as String;
    final data = result['data'] as Map<String, dynamic>;
    Navigator.pop(context);
    if (role == 'admin') {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => AdminDashboard(provider: widget.provider)));
    } else {
      widget.provider.loginAsDriverFromFirebase(
        uid: result['uid'],
        driverName: data['name'] ?? '',
        plateNumber: data['plateNumber'] ?? '',
        lat: (data['lat'] as num?)?.toDouble() ?? 0.5,
        lng: (data['lng'] as num?)?.toDouble() ?? 0.5,
      );
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => DriverDashboard(provider: widget.provider)));
    }
  }

  // ── Login Email/Password ──────────────────────────────
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });

    final result = await AuthService.login(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      final role = result['role'] as String;
      if (role != widget.role) {
        setState(() => _errorMsg =
            'Akun ini terdaftar sebagai ${role == 'admin' ? 'Admin' : 'Driver'}. '
            'Silakan pilih role yang sesuai.');
        return;
      }
      _goToDashboard(result);
    } else {
      setState(() => _errorMsg = result['message']);
    }
  }

  // ── Login Google ──────────────────────────────────────
  Future<void> _handleGoogleLogin() async {
    setState(() { _isGoogleLoading = true; _errorMsg = null; });

    final result = await AuthService.loginWithGoogle(role: widget.role);

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result['success'] == true) {
      _goToDashboard(result);
    } else if (result['notRegistered'] == true) {
      // Belum daftar → arahkan ke halaman registrasi
      setState(() => _errorMsg = null);
      _showNotRegisteredDialog();
    } else {
      setState(() => _errorMsg = result['message']);
    }
  }

  void _showNotRegisteredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('Akun Belum Terdaftar'),
          ],
        ),
        content: Text(
          isAdmin
              ? 'Akun Google ini belum terdaftar sebagai Admin.\nHubungi administrator sistem untuk mendaftarkan akun Anda.'
              : 'Akun Google ini belum terdaftar.\nSilakan daftar terlebih dahulu.',
          style: TextStyle(color: Colors.grey[600], height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tutup', style: TextStyle(color: Colors.grey[500])),
          ),
          // Tombol daftar hanya muncul untuk Driver
          if (!isAdmin)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context); // tutup bottom sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RegisterScreen(
                        role: widget.role, provider: widget.provider),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Daftar Sekarang',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottomPadding),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: accentLight,
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(
                    isAdmin
                        ? Icons.admin_panel_settings_rounded
                        : Icons.local_shipping_rounded,
                    color: accent, size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Login ${isAdmin ? 'Admin' : 'Driver'}',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                    Text('Masukkan email & password Anda',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: Colors.grey[400]),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Form Email/Password ────────────────────
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildField(
                    controller: _emailCtrl,
                    hint: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Email tidak boleh kosong';
                      if (!v.contains('@')) return 'Format email tidak valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    controller: _passCtrl,
                    hint: 'Password',
                    icon: Icons.lock_outline,
                    obscure: _obscure,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey[400], size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Password tidak boleh kosong';
                      return null;
                    },
                  ),

                  // Error banner
                  if (_errorMsg != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red[600], size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_errorMsg!,
                                style: TextStyle(
                                    color: Colors.red[700], fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Tombol Login Email ─────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        disabledBackgroundColor: accent.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Masuk',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Tombol Login Google (di bawah Login) ─
                  _GoogleButton(
                    isLoading: _isGoogleLoading,
                    onTap: _handleGoogleLogin,
                  ),

                  // Tombol Daftar hanya untuk Driver
                  if (!isAdmin) ...[
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey[200])),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('belum punya akun?',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12)),
                        ),
                        Expanded(child: Divider(color: Colors.grey[200])),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Tombol Daftar Driver ───────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.person_add_alt_1_outlined,
                            color: accent, size: 20),
                        label: Text(
                          'Daftar Akun Driver Baru',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: accent),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: accent.withOpacity(0.4), width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegisterScreen(
                                  role: widget.role,
                                  provider: widget.provider),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent, width: 1.8)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[300]!, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red[400]!, width: 1.8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
      validator: validator,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Google Button Widget
// ════════════════════════════════════════════════════════════════════════════
class _GoogleButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _GoogleButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[300]!, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.grey)),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google G logo
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F3F4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text('G',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4285F4),
                          )),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Masuk dengan Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}