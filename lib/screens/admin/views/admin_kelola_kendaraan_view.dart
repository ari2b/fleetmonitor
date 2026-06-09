import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../providers/fleet_provider.dart';
import '../../../models/driver_model.dart';
import '../../../models/vehicle_model.dart';

// ─── Konstanta ────────────────────────────────────────────────────────────────

const List<String> kVehicleTypes = [
  'Mobil',
  'Truk',
  'Pickup',
  'Van/Minibus',
  'Motor'
];

const List<String> kVehicleBrands = [
  'Toyota',
  'Mitsubishi',
  'Daihatsu',
  'Honda',
  'Suzuki',
  'Isuzu',
  'Hino',
  'Ford',
  'Hyundai',
  'Wuling',
  'Lainnya',
];

const List<String> kVehicleColors = [
  'Putih',
  'Hitam',
  'Silver',
  'Abu-abu',
  'Merah',
  'Biru',
  'Kuning',
  'Hijau',
  'Orange',
  'Coklat',
];

IconData _iconForType(String type) {
  switch (type) {
    case 'Truk':
      return Icons.local_shipping;
    case 'Pickup':
      return Icons.airport_shuttle;
    case 'Van/Minibus':
      return Icons.directions_bus;
    case 'Motor':
      return Icons.two_wheeler;
    default:
      return Icons.directions_car;
  }
}

// ─── View Kendaraan per Driver ────────────────────────────────────────────────

class AdminKelolaKendaraanView extends StatefulWidget {
  final Driver driver;
  final FleetProvider provider;

  const AdminKelolaKendaraanView({
    super.key,
    required this.driver,
    required this.provider,
  });

  @override
  State<AdminKelolaKendaraanView> createState() =>
      _AdminKelolaKendaraanViewState();
}

class _AdminKelolaKendaraanViewState
    extends State<AdminKelolaKendaraanView> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Stream real-time kendaraan milik driver ini dari Firestore.
  Stream<List<Vehicle>> get _vehiclesStream {
    // Coba dengan orderBy dulu; fallback ditangani di StreamBuilder
    return _db
        .collection('vehicles')
        .where('driverId', isEqualTo: widget.driver.id)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Vehicle.fromMap(d.id, d.data())).toList());
  }

  Future<void> _addVehicle({
    required String plateNumber,
    required String vehicleType,
    required String vehicleBrand,
    required int vehicleYear,
    required String vehicleColor,
  }) async {
    final random = Random();
    final docRef = _db.collection('vehicles').doc();

    final lat = -7.6298 + (random.nextDouble() - 0.5) * 0.02;
    final lng = 111.5225 + (random.nextDouble() - 0.5) * 0.02;

    await docRef.set({
      'driverName': widget.driver.name,
      'plateNumber': plateNumber,
      'vehicleType': vehicleType,
      'vehicleBrand': vehicleBrand,
      'vehicleYear': vehicleYear,
      'vehicleColor': vehicleColor,
      'lat': lat,
      'lng': lng,
      'heading': 0.0,
      'status': 'idle',
      'driverId': widget.driver.id,
      'createdAt': FieldValue.serverTimestamp(),
    });
    // Stream otomatis refresh — tidak perlu push manual ke provider
  }

  Future<void> _updateVehicle(Vehicle v) async {
    await _db.collection('vehicles').doc(v.id).update({
      'plateNumber': v.plateNumber,
      'vehicleType': v.vehicleType,
      'vehicleBrand': v.vehicleBrand,
      'vehicleYear': v.vehicleYear,
      'vehicleColor': v.vehicleColor,
      'driverName': widget.driver.name,
      'driverId': widget.driver.id,
    });
  }

  Future<void> _deleteVehicle(String id) async {
    await _db.collection('vehicles').doc(id).delete();
    widget.provider.deleteVehicle(id);
  }

  void _openVehicleForm({Vehicle? vehicle}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _VehicleFormDialog(
        driver: widget.driver,
        vehicle: vehicle,
        onSave: (v, isNew) async {
          if (isNew) {
            await _addVehicle(
              plateNumber: v.plateNumber,
              vehicleType: v.vehicleType,
              vehicleBrand: v.vehicleBrand,
              vehicleYear: v.vehicleYear,
              vehicleColor: v.vehicleColor,
            );
          } else {
            await _updateVehicle(v);
          }
        },
      ),
    );
  }

  void _confirmDeleteVehicle(Vehicle v) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Kendaraan'),
          ],
        ),
        content: Text('Hapus kendaraan "${v.plateNumber}" dari daftar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteVehicle(v.id);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo[600],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kendaraan — ${widget.driver.name}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            Text(
              'Status: ${widget.driver.status == 'aktif' ? 'Aktif' : 'Non-Aktif'}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<Vehicle>>(
        stream: _vehiclesStream,
        builder: (context, snapshot) {
          // ── Loading ──────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // ── Error (mis. index belum dibuat) ─────────────
          if (snapshot.hasError) {
            final err = snapshot.error.toString();
            if (err.contains('index') || err.contains('FAILED_PRECONDITION')) {
              return _FallbackVehicleList(
                driverId: widget.driver.id,
                driver: widget.driver,
                onAdd: () => _openVehicleForm(),
                onEdit: (v) => _openVehicleForm(vehicle: v),
                onDelete: _confirmDeleteVehicle,
              );
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red[400], size: 48),
                  const SizedBox(height: 12),
                  Text('Gagal memuat kendaraan',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            );
          }

          final vehicles = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _DriverInfoBanner(driver: widget.driver),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _openVehicleForm(),
                icon: Icon(Icons.add_circle_outline, color: Colors.teal[600]),
                label: Text(
                  'Tambah Kendaraan',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.teal[600]),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: BorderSide(color: Colors.teal[200]!, width: 1.5),
                  backgroundColor: Colors.teal[50],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 16),
              if (vehicles.isEmpty)
                _EmptyVehicle()
              else
                ...vehicles.map((v) => _VehicleCard(
                      vehicle: v,
                      onEdit: () => _openVehicleForm(vehicle: v),
                      onDelete: () => _confirmDeleteVehicle(v),
                    )),
            ],
          );
        },
      ),
    );
  }
}

// ─── Fallback tanpa orderBy ───────────────────────────────────────────────────

class _FallbackVehicleList extends StatelessWidget {
  final String driverId;
  final Driver driver;
  final VoidCallback onAdd;
  final void Function(Vehicle) onEdit;
  final void Function(Vehicle) onDelete;

  const _FallbackVehicleList({
    required this.driverId,
    required this.driver,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicles')
          .where('driverId', isEqualTo: driverId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        final vehicles = docs
            .map((d) =>
                Vehicle.fromMap(d.id, d.data() as Map<String, dynamic>))
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Buat Firestore composite index untuk koleksi "vehicles": '
                      'field driverId (ASC) + createdAt (ASC) agar tampilan optimal.',
                      style:
                          TextStyle(fontSize: 11, color: Colors.amber[900]),
                    ),
                  ),
                ],
              ),
            ),
            _DriverInfoBanner(driver: driver),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: Icon(Icons.add_circle_outline, color: Colors.teal[600]),
              label: Text('Tambah Kendaraan',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.teal[600])),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: BorderSide(color: Colors.teal[200]!, width: 1.5),
                backgroundColor: Colors.teal[50],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 16),
            if (vehicles.isEmpty)
              _EmptyVehicle()
            else
              ...vehicles.map((v) => _VehicleCard(
                    vehicle: v,
                    onEdit: () => onEdit(v),
                    onDelete: () => onDelete(v),
                  )),
          ],
        );
      },
    );
  }
}

// ─── Driver Info Banner ───────────────────────────────────────────────────────

class _DriverInfoBanner extends StatelessWidget {
  final Driver driver;
  const _DriverInfoBanner({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.indigo[100]!),
        boxShadow: [
          BoxShadow(
              color: Colors.indigo.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo[200]!),
            ),
            alignment: Alignment.center,
            child: Text(
              driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[600],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(driver.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                if (driver.phone.isNotEmpty)
                  Text(driver.phone,
                      style:
                          TextStyle(color: Colors.grey[500], fontSize: 12)),
                _StatusChip(
                  label: driver.status == 'aktif' ? 'AKTIF' : 'NON-AKTIF',
                  color: driver.status == 'aktif' ? Colors.green : Colors.grey,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final MaterialColor color;
  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color[200]!),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: color[700])),
    );
  }
}

// ─── Vehicle Card ─────────────────────────────────────────────────────────────

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _VehicleCard({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.teal[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconForType(vehicle.vehicleType),
                    color: Colors.teal[600], size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.plateNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'monospace'),
                    ),
                    Text(
                      '${vehicle.vehicleBrand} ${vehicle.vehicleYear}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _ActionBtn(
                      icon: Icons.edit_rounded,
                      color: Colors.blue,
                      onTap: onEdit),
                  const SizedBox(width: 8),
                  _ActionBtn(
                      icon: Icons.delete_outline_rounded,
                      color: Colors.red,
                      onTap: onDelete),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoChip(
                  icon: Icons.category_outlined,
                  label: vehicle.vehicleType,
                  color: Colors.teal),
              _InfoChip(
                  icon: Icons.palette_outlined,
                  label: vehicle.vehicleColor.isNotEmpty
                      ? vehicle.vehicleColor
                      : '-',
                  color: Colors.purple),
              _InfoChip(
                  icon: Icons.calendar_today_outlined,
                  label: vehicle.vehicleYear.toString(),
                  color: Colors.orange),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final MaterialColor color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color[100]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color[600]),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color[700])),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final MaterialColor color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color[600], size: 17),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyVehicle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Belum ada kendaraan untuk driver ini.\nTambahkan kendaraan di atas.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog Form Kendaraan ────────────────────────────────────────────────────

class _VehicleFormDialog extends StatefulWidget {
  final Driver driver;
  final Vehicle? vehicle;
  final Future<void> Function(Vehicle v, bool isNew) onSave;

  const _VehicleFormDialog({
    required this.driver,
    this.vehicle,
    required this.onSave,
  });

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _plateCtrl;

  late String _selectedType;
  late String _selectedBrand;
  late String _selectedColor;
  late int _selectedYear;
  bool _isSaving = false;

  bool get isEdit => widget.vehicle != null;

  List<int> get _years {
    final now = DateTime.now().year;
    return List.generate(now - 2009, (i) => now - i);
  }

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _plateCtrl = TextEditingController(text: v?.plateNumber ?? '');
    _selectedType = v?.vehicleType ?? kVehicleTypes.first;
    _selectedBrand =
        (v?.vehicleBrand != null && kVehicleBrands.contains(v!.vehicleBrand))
            ? v.vehicleBrand
            : kVehicleBrands.first;
    _selectedColor =
        (v?.vehicleColor != null && kVehicleColors.contains(v!.vehicleColor))
            ? v.vehicleColor
            : kVehicleColors.first;
    _selectedYear = v?.vehicleYear ?? DateTime.now().year;
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final vehicle = Vehicle(
      id: widget.vehicle?.id ?? '',
      driverName: widget.driver.name,
      plateNumber: _plateCtrl.text.trim().toUpperCase(),
      vehicleType: _selectedType,
      vehicleBrand: _selectedBrand,
      vehicleYear: _selectedYear,
      vehicleColor: _selectedColor,
      lat: widget.vehicle?.lat ?? -7.6298,
      lng: widget.vehicle?.lng ?? 111.5225,
    );

    await widget.onSave(vehicle, !isEdit);
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.teal[600],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.directions_car_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Kendaraan' : 'Tambah Kendaraan',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      Text(
                        'Driver: ${widget.driver.name}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11),
                      ),
                    ],
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
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('PLAT NOMOR *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _plateCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _inputDeco(
                          'Contoh: AE 1234 CD', Icons.credit_card_outlined),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Plat nomor tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _label('JENIS KENDARAAN'),
                    const SizedBox(height: 8),
                    _dropdown<String>(
                      value: _selectedType,
                      icon: Icons.category_outlined,
                      items: kVehicleTypes,
                      labelBuilder: (e) => e,
                      onChanged: (v) => setState(() => _selectedType = v!),
                    ),
                    const SizedBox(height: 14),
                    _label('MEREK KENDARAAN'),
                    const SizedBox(height: 8),
                    _dropdown<String>(
                      value: _selectedBrand,
                      icon: Icons.directions_car_outlined,
                      items: kVehicleBrands,
                      labelBuilder: (e) => e,
                      onChanged: (v) => setState(() => _selectedBrand = v!),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('TAHUN'),
                              const SizedBox(height: 8),
                              _dropdown<int>(
                                value: _selectedYear,
                                icon: Icons.calendar_today_outlined,
                                items: _years,
                                labelBuilder: (e) => e.toString(),
                                onChanged: (v) =>
                                    setState(() => _selectedYear = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('WARNA'),
                              const SizedBox(height: 8),
                              _dropdown<String>(
                                value: _selectedColor,
                                icon: Icons.palette_outlined,
                                items: kVehicleColors,
                                labelBuilder: (e) => e,
                                onChanged: (v) =>
                                    setState(() => _selectedColor = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                                style: TextStyle(color: Colors.grey[700])),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor: Colors.teal[600],
                              disabledBackgroundColor: Colors.teal[300],
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5))
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

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
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
          borderSide: BorderSide(color: Colors.teal[500]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

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
          borderSide: BorderSide(color: Colors.teal[500]!, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: items
          .map((e) => DropdownMenuItem<T>(
                value: e,
                child:
                    Text(labelBuilder(e), style: const TextStyle(fontSize: 14)),
              ))
          .toList(),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
      icon: Icon(Icons.expand_more, color: Colors.grey[400]),
    );
  }
}