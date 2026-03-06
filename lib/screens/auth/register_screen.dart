import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../providers/fleet_provider.dart';

class RegisterScreen extends StatefulWidget {
  final String role;
  final FleetProvider provider;
  const RegisterScreen({super.key, required this.role, required this.provider});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMsg;

  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  bool get isAdmin => widget.role == 'admin';
  Color get accent => isAdmin ? Colors.indigo[600]! : Colors.teal[600]!;
  Color get accentLight => isAdmin ? Colors.indigo[50]! : Colors.teal[50]!;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 450));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _plateCtrl.dispose();
    super.dispose();
  }

  // ── Registrasi Email/Password ─────────────────────────
  Future<void> _doRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMsg = null; });

    final result = await AuthService.register(
      email: _emailCtrl.text,
      password: _passCtrl.text,
      name: _nameCtrl.text,
      role: widget.role,
      plateNumber: !isAdmin ? _plateCtrl.text : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      _showSuccessDialog(isGoogle: false);
    } else {
      setState(() => _errorMsg = result['message']);
    }
  }

  // ── Registrasi Google ─────────────────────────────────
  Future<void> _doGoogleRegister() async {
    // Driver perlu plat nomor dulu sebelum Google Sign-In
    if (!isAdmin) {
      _showGoogleDriverPlateDialog();
      return;
    }
    // Admin langsung proses
    await _processGoogleRegister(plateNumber: null);
  }

  Future<void> _processGoogleRegister({String? plateNumber}) async {
    setState(() { _isGoogleLoading = true; _errorMsg = null; });

    final result = await AuthService.registerWithGoogle(
      role: widget.role,
      plateNumber: plateNumber,
    );

    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result['success'] == true) {
      _showSuccessDialog(isGoogle: true);
    } else if (result['alreadyRegistered'] == true) {
      _showAlreadyRegisteredDialog();
    } else {
      setState(() => _errorMsg = result['message']);
    }
  }

  // ── Dialog plat nomor untuk driver Google ─────────────
  void _showGoogleDriverPlateDialog() {
    final plateCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool loading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: Colors.teal[50], shape: BoxShape.circle),
                    child: Icon(Icons.directions_car_rounded,
                        color: Colors.teal[600], size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('Plat Nomor Kendaraan',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 6),
                  Text(
                    'Masukkan plat nomor kendaraan\nsebelum melanjutkan dengan Google.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[500], height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: plateCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Contoh: B 1234 CD',
                      prefixIcon: Icon(Icons.directions_car_outlined,
                          color: Colors.grey[400], size: 20),
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
                          borderSide: BorderSide(
                              color: Colors.teal[600]!, width: 1.8)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? 'Plat nomor tidak boleh kosong'
                            : null,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: Text('Batal',
                              style: TextStyle(color: Colors.grey[600])),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: loading
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) return;
                                  setDlg(() => loading = true);
                                  Navigator.pop(ctx);
                                  await _processGoogleRegister(
                                      plateNumber: plateCtrl.text);
                                },
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 46),
                            backgroundColor: Colors.teal[600],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Lanjutkan',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Dialog sukses ─────────────────────────────────────
  void _showSuccessDialog({required bool isGoogle}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.green[50], shape: BoxShape.circle),
                child: Icon(Icons.check_circle_outline,
                    color: Colors.green[500], size: 52),
              ),
              const SizedBox(height: 20),
              const Text('Registrasi Berhasil!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              Text(
                'Akun ${isAdmin ? 'Admin' : 'Driver'} Anda telah dibuat${isGoogle ? ' via Google' : ''}.\nSilakan login untuk melanjutkan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey[500], fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    // signOut setelah dialog ditutup
                    await AuthService.logout();
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Kembali ke Login',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialog sudah terdaftar ────────────────────────────
  void _showAlreadyRegisteredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('Sudah Terdaftar'),
          ],
        ),
        content: Text(
          'Akun Google ini sudah terdaftar.\nSilakan gunakan tombol Login.',
          style: TextStyle(color: Colors.grey[600], height: 1.5),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // kembali ke login
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text('Ke Halaman Login',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: FadeTransition(
              opacity: _fade,
              child: SlideTransition(
                position: _slide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Badge role
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: accentLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isAdmin
                                          ? Icons.admin_panel_settings_rounded
                                          : Icons.local_shipping_rounded,
                                      color: accent, size: 14,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Daftar sebagai ${isAdmin ? 'Admin' : 'Driver'}',
                                      style: TextStyle(
                                          color: accent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // ── Registrasi Google (di atas form) ──
                              _GoogleRegisterButton(
                                isLoading: _isGoogleLoading,
                                onTap: _doGoogleRegister,
                                role: widget.role,
                              ),
                              const SizedBox(height: 20),

                              // Divider
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.grey[200])),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text('atau daftar dengan email',
                                        style: TextStyle(
                                            color: Colors.grey[400], fontSize: 11)),
                                  ),
                                  Expanded(child: Divider(color: Colors.grey[200])),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Nama
                              _label('NAMA LENGKAP'),
                              const SizedBox(height: 8),
                              _field(
                                ctrl: _nameCtrl,
                                hint: isAdmin ? 'Nama administrator' : 'Nama lengkap driver',
                                icon: Icons.person_outline,
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Nama tidak boleh kosong'
                                        : null,
                              ),
                              const SizedBox(height: 16),

                              // Plat (driver only)
                              if (!isAdmin) ...[
                                _label('PLAT NOMOR KENDARAAN'),
                                const SizedBox(height: 8),
                                _field(
                                  ctrl: _plateCtrl,
                                  hint: 'Contoh: B 1234 CD',
                                  icon: Icons.directions_car_outlined,
                                  caps: TextCapitalization.characters,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? 'Plat nomor tidak boleh kosong'
                                          : null,
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Email
                              _label('EMAIL'),
                              const SizedBox(height: 8),
                              _field(
                                ctrl: _emailCtrl,
                                hint: 'contoh@email.com',
                                icon: Icons.email_outlined,
                                keyboard: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty)
                                    return 'Email tidak boleh kosong';
                                  if (!v.contains('@'))
                                    return 'Format email tidak valid';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password
                              _label('PASSWORD'),
                              const SizedBox(height: 8),
                              _field(
                                ctrl: _passCtrl,
                                hint: 'Minimal 6 karakter',
                                icon: Icons.lock_outline,
                                obscure: _obscurePass,
                                suffix: _eyeBtn(
                                  visible: _obscurePass,
                                  onTap: () => setState(
                                      () => _obscurePass = !_obscurePass),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Password tidak boleh kosong';
                                  if (v.length < 6)
                                    return 'Password minimal 6 karakter';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Konfirmasi
                              _label('KONFIRMASI PASSWORD'),
                              const SizedBox(height: 8),
                              _field(
                                ctrl: _confirmCtrl,
                                hint: 'Ulangi password',
                                icon: Icons.lock_outline,
                                obscure: _obscureConfirm,
                                suffix: _eyeBtn(
                                  visible: _obscureConfirm,
                                  onTap: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm),
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Konfirmasi password tidak boleh kosong';
                                  if (v != _passCtrl.text)
                                    return 'Password tidak cocok';
                                  return null;
                                },
                              ),

                              // Error
                              if (_errorMsg != null) ...[
                                const SizedBox(height: 14),
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
                                                color: Colors.red[700],
                                                fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Tombol Daftar Email
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _doRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accent,
                                    disabledBackgroundColor:
                                        accent.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20, height: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5))
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              isAdmin
                                                  ? Icons.security
                                                  : Icons.person_add_rounded,
                                              color: Colors.white, size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text('Daftar Sekarang',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white)),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Link sudah punya akun
                              Center(
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: RichText(
                                    text: TextSpan(
                                      text: 'Sudah punya akun? ',
                                      style: TextStyle(
                                          color: Colors.grey[500], fontSize: 13),
                                      children: [
                                        TextSpan(
                                          text: 'Masuk di sini',
                                          style: TextStyle(
                                            color: accent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
          color: isAdmin ? Colors.indigo[600] : Colors.teal[600]),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registrasi ${isAdmin ? 'Admin' : 'Driver'}',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
              Text('Fleet Monitor',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String txt) => Text(txt,
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.8));

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType? keyboard,
    TextCapitalization caps = TextCapitalization.none,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      obscureText: obscure,
      textCapitalization: caps,
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

  Widget _eyeBtn({required bool visible, required VoidCallback onTap}) =>
      IconButton(
        icon: Icon(
          visible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: Colors.grey[400], size: 20,
        ),
        onPressed: onTap,
      );
}

// ════════════════════════════════════════════════════════════════════════════
// Google Register Button
// ════════════════════════════════════════════════════════════════════════════
class _GoogleRegisterButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  final String role;
  const _GoogleRegisterButton(
      {required this.isLoading, required this.onTap, required this.role});

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
                              color: Color(0xFF4285F4))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Daftar dengan Google',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700]),
                  ),
                ],
              ),
      ),
    );
  }
}