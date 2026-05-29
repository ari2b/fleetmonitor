import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/fleet_provider.dart';
import '../../../models/driver_model.dart';
import '../../../models/vehicle_model.dart';
import 'admin_kelola_kendaraan_view.dart';
import 'admin_jadwal_view.dart';

// ─── Konstanta ────────────────────────────────────────────────────────────────

const List<String> kDriverStatus = ['aktif', 'nonaktif'];

// ─── Tab Kelola (entry point) ─────────────────────────────────────────────────

class AdminKelolaTab extends StatefulWidget {
  final FleetProvider provider;
  const AdminKelolaTab({super.key, required this.provider});

  @override
  State<AdminKelolaTab> createState() => _AdminKelolaTabState();
}

class _AdminKelolaTabState extends State<AdminKelolaTab> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Driver> _drivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() => _isLoading = true);
    try {
      final snap = await _db
          .collection('drivers')
          .orderBy('createdAt', descending: false)
          .get();
      _drivers = snap.docs
          .map((d) => Driver.fromMap(d.id, d.data()))
          .toList();
    } catch (_) {
      _drivers = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveDriver(Driver driver, {bool isNew = false}) async {
    final data = {
      ...driver.toMap(),
      if (isNew) 'createdAt': FieldValue.serverTimestamp(),
    };
    if (isNew) {
      final ref = await _db.collection('drivers').add(data);
      driver = Driver.fromMap(ref.id, driver.toMap());
      _drivers.add(driver);
    } else {
      await _db.collection('drivers').doc(driver.id).update(data);
      final idx = _drivers.indexWhere((d) => d.id == driver.id);
      if (idx != -1) _drivers[idx] = driver;
    }
    if (mounted) setState(() {});
  }

  Future<void> _deleteDriver(String id) async {
    final vehicles = await _db
        .collection('vehicles')
        .where('driverId', isEqualTo: id)
        .get();
    for (final v in vehicles.docs) {
      await _db.collection('vehicles').doc(v.id).delete();
      widget.provider.deleteVehicle(v.id);
    }
    // Hapus jadwal milik driver ini
    final schedules = await _db
        .collection('schedules')
        .where('driverId', isEqualTo: id)
        .get();
    for (final s in schedules.docs) {
      await _db.collection('schedules').doc(s.id).delete();
    }
    await _db.collection('drivers').doc(id).delete();
    _drivers.removeWhere((d) => d.id == id);
    if (mounted) setState(() {});
  }

  void _openDriverForm({Driver? driver}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _DriverFormDialog(
        driver: driver,
        onSave: (d, isNew) => _saveDriver(d, isNew: isNew),
      ),
    );
  }

  void _confirmDeleteDriver(Driver driver) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Driver'),
          ],
        ),
        content: Text(
          'Hapus driver "${driver.name}"?\n\nSemua kendaraan dan jadwal yang terdaftar pada driver ini juga akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteDriver(driver.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openKendaraanView(Driver driver) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminKelolaKendaraanView(
          driver: driver,
          provider: widget.provider,
        ),
      ),
    );
    // Refresh daftar kendaraan di provider setelah kembali
    await _syncVehiclesFromFirestore();
  }

  /// Sync semua kendaraan dari Firestore ke FleetProvider
  Future<void> _syncVehiclesFromFirestore() async {
    try {
      final snap = await _db.collection('vehicles').get();
      final firestoreVehicles =
          snap.docs.map((d) => Vehicle.fromMap(d.id, d.data())).toList();

      // Ganti list vehicles di provider dengan data terbaru dari Firestore
      widget.provider.vehicles
        ..removeWhere((v) => !['v1', 'v2', 'v3'].contains(v.id))
        ..clear();
      widget.provider.vehicles.addAll(firestoreVehicles);
      widget.provider.notifyListeners();
    } catch (_) {}
  }

  void _openJadwalView(Driver driver) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminJadwalView(driver: driver),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDrivers,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Header info ───────────────────────────
                  _SectionHeader(
                    icon: Icons.people_alt_rounded,
                    title: 'Master Data Driver',
                    subtitle:
                        '${_drivers.length} driver terdaftar • Ketuk driver untuk kelola kendaraan & jadwal',
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 12),

                  // ── Tombol Tambah Driver ──────────────────
                  OutlinedButton.icon(
                    onPressed: () => _openDriverForm(),
                    icon: Icon(Icons.person_add_rounded,
                        color: Colors.indigo[600]),
                    label: Text(
                      'Tambah Driver Baru',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo[600]),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: BorderSide(color: Colors.indigo[200]!, width: 1.5),
                      backgroundColor: Colors.indigo[50],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Daftar Driver ─────────────────────────
                  if (_drivers.isEmpty)
                    _EmptyState(
                      icon: Icons.person_off_rounded,
                      message:
                          'Belum ada driver terdaftar.\nTambahkan driver terlebih dahulu.',
                    )
                  else
                    ..._drivers.map((driver) => _DriverCard(
                          driver: driver,
                          provider: widget.provider,
                          onEdit: () => _openDriverForm(driver: driver),
                          onDelete: () => _confirmDeleteDriver(driver),
                          onTapKendaraan: () => _openKendaraanView(driver),
                          onTapJadwal: () => _openJadwalView(driver),
                        )),
                ],
              ),
            ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final MaterialColor color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color[600]!, color[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Driver Card ──────────────────────────────────────────────────────────────

class _DriverCard extends StatefulWidget {
  final Driver driver;
  final FleetProvider provider;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTapKendaraan;
  final VoidCallback onTapJadwal;

  const _DriverCard({
    required this.driver,
    required this.provider,
    required this.onEdit,
    required this.onDelete,
    required this.onTapKendaraan,
    required this.onTapJadwal,
  });

  @override
  State<_DriverCard> createState() => _DriverCardState();
}

class _DriverCardState extends State<_DriverCard> {
  int _vehicleCount = 0;
  int _scheduleCount = 0;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    try {
      final vSnap = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('driverId', isEqualTo: widget.driver.id)
          .get();
      final sSnap = await FirebaseFirestore.instance
          .collection('schedules')
          .where('driverId', isEqualTo: widget.driver.id)
          .where('status', whereIn: ['pending', 'confirmed'])
          .get();
      if (mounted) {
        setState(() {
          _vehicleCount = vSnap.docs.length;
          _scheduleCount = sSnap.docs.length;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isAktif = widget.driver.status == 'aktif';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // ── Baris utama ──────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isAktif ? Colors.indigo[50] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          isAktif ? Colors.indigo[200]! : Colors.grey[300]!,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.driver.name.isNotEmpty
                        ? widget.driver.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isAktif ? Colors.indigo[600] : Colors.grey[400],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.driver.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isAktif
                                  ? Colors.green[50]
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isAktif
                                    ? Colors.green[300]!
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              isAktif ? 'AKTIF' : 'NON-AKTIF',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isAktif
                                    ? Colors.green[700]
                                    : Colors.grey[500],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      if (widget.driver.phone.isNotEmpty)
                        Text(
                          widget.driver.phone,
                          style:
                              TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      if (widget.driver.email.isNotEmpty)
                        Text(
                          widget.driver.email,
                          style: TextStyle(
                              color: Colors.grey[400], fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),

                Column(
                  children: [
                    _ActionIconBtn(
                      icon: Icons.edit_rounded,
                      color: Colors.blue,
                      onTap: widget.onEdit,
                    ),
                    const SizedBox(height: 6),
                    _ActionIconBtn(
                      icon: Icons.delete_outline_rounded,
                      color: Colors.red,
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),

          Divider(height: 1, color: Colors.grey[100]),

          // ── Footer: Kendaraan & Jadwal ─────────────────────
          IntrinsicHeight(
            child: Row(
              children: [
                // Kendaraan
                Expanded(
                  child: InkWell(
                    onTap: widget.onTapKendaraan,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.directions_car_rounded,
                              color: Colors.teal[400], size: 15),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$_vehicleCount Kendaraan',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.teal[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.teal[300], size: 11),
                        ],
                      ),
                    ),
                  ),
                ),

                VerticalDivider(width: 1, color: Colors.grey[100]),

                // Jadwal
                Expanded(
                  child: InkWell(
                    onTap: widget.onTapJadwal,
                    borderRadius: const BorderRadius.only(
                      bottomRight: Radius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_month_rounded,
                              color: Colors.orange[400], size: 15),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '$_scheduleCount Jadwal Aktif',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              color: Colors.orange[300], size: 11),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Icon Button ───────────────────────────────────────────────────────

class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final MaterialColor color;
  final VoidCallback onTap;

  const _ActionIconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color[600], size: 16),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey[400], fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog Form Driver ───────────────────────────────────────────────────────

class _DriverFormDialog extends StatefulWidget {
  final Driver? driver;
  final Future<void> Function(Driver driver, bool isNew) onSave;

  const _DriverFormDialog({this.driver, required this.onSave});

  @override
  State<_DriverFormDialog> createState() => _DriverFormDialogState();
}

class _DriverFormDialogState extends State<_DriverFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  late String _selectedStatus;
  bool _isSaving = false;

  bool get isEdit => widget.driver != null;

  @override
  void initState() {
    super.initState();
    final d = widget.driver;
    _nameCtrl = TextEditingController(text: d?.name ?? '');
    _emailCtrl = TextEditingController(text: d?.email ?? '');
    _phoneCtrl = TextEditingController(text: d?.phone ?? '');
    _selectedStatus = d?.status ?? 'aktif';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final driver = Driver(
      id: widget.driver?.id ?? '',
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      status: _selectedStatus,
    );

    await widget.onSave(driver, !isEdit);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.indigo[600],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isEdit ? 'Edit Data Driver' : 'Tambah Driver Baru',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close,
                      color: Colors.white70, size: 20),
                ),
              ],
            ),
          ),

          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('NAMA LENGKAP *'),
                    const SizedBox(height: 8),
                    _textField(
                      ctrl: _nameCtrl,
                      hint: 'Nama lengkap driver',
                      icon: Icons.person_outline,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    _label('NOMOR TELEPON'),
                    const SizedBox(height: 8),
                    _textField(
                      ctrl: _phoneCtrl,
                      hint: '08xxxxxxxxxx',
                      icon: Icons.phone_outlined,
                      keyboard: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),

                    _label('EMAIL'),
                    const SizedBox(height: 8),
                    _textField(
                      ctrl: _emailCtrl,
                      hint: 'email@contoh.com',
                      icon: Icons.email_outlined,
                      keyboard: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 14),

                    _label('STATUS'),
                    const SizedBox(height: 8),
                    _dropdown<String>(
                      value: _selectedStatus,
                      icon: Icons.toggle_on_outlined,
                      items: kDriverStatus,
                      labelBuilder: (e) =>
                          e[0].toUpperCase() + e.substring(1),
                      onChanged: (v) =>
                          setState(() => _selectedStatus = v!),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: Text('Batal',
                                style:
                                    TextStyle(color: Colors.grey[700])),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor: Colors.indigo[600],
                              disabledBackgroundColor: Colors.indigo[300],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5),
                                  )
                                : const Text('Simpan',
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
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      );

  Widget _textField({
    required TextEditingController ctrl,
    required String hint,
    required IconData icon,
    TextInputType? keyboard,
    TextCapitalization caps = TextCapitalization.words,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      textCapitalization: caps,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.indigo[500]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }

  Widget _dropdown<T>({
    required T value,
    required IconData icon,
    required List<T> items,
    required String Function(T) labelBuilder,
    required void Function(T?) onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.indigo[500]!, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child: Text(labelBuilder(e),
                    style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      icon: Icon(Icons.expand_more, color: Colors.grey[400]),
    );
  }
}