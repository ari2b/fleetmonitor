import 'package:flutter/material.dart';
import '../../../providers/fleet_provider.dart';
import '../../../models/vehicle_model.dart';

// ─── Konstanta dropdown ────────────────────────────────────────────────────────

const List<String> kVehicleTypes = ['Mobil', 'Truk', 'Pickup', 'Van/Minibus', 'Motor'];

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

// ─── Ikon per jenis kendaraan ─────────────────────────────────────────────────

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

// ─── Tab Kelola ───────────────────────────────────────────────────────────────

class AdminKelolaTab extends StatelessWidget {
  final FleetProvider provider;
  const AdminKelolaTab({super.key, required this.provider});

  void _openModal(BuildContext context, {Vehicle? vehicle}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _VehicleFormDialog(
        provider: provider,
        vehicle: vehicle,
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String plateNumber) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Armada'),
          ],
        ),
        content: Text(
            'Apakah Anda yakin ingin menghapus kendaraan $plateNumber?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteVehicle(id);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child:
                const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Tombol Tambah ──────────────────────────────
            OutlinedButton.icon(
              onPressed: () => _openModal(context),
              icon: Icon(Icons.add, color: Colors.indigo[600]),
              label: Text(
                'Tambah Armada Baru',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.indigo[600]),
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

            // ── Daftar Armada ──────────────────────────────
            ...provider.vehicles.map((v) => _VehicleCard(
                  vehicle: v,
                  onEdit: () => _openModal(context, vehicle: v),
                  onDelete: () =>
                      _confirmDelete(context, v.id, v.plateNumber),
                )),
          ],
        );
      },
    );
  }
}

// ─── Card Armada ──────────────────────────────────────────────────────────────

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
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Baris atas: ikon + plat + nama + tombol ──
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconForType(vehicle.vehicleType),
                    color: Colors.indigo[400], size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.plateNumber,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      vehicle.driverName,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Tombol Edit & Hapus
              Row(
                children: [
                  _ActionBtn(
                    icon: Icons.edit,
                    color: Colors.blue,
                    onTap: onEdit,
                  ),
                  const SizedBox(width: 8),
                  _ActionBtn(
                    icon: Icons.delete_outline,
                    color: Colors.red,
                    onTap: onDelete,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // ── Baris bawah: detail kendaraan ──────────────
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _InfoChip(
                icon: Icons.category_outlined,
                label: vehicle.vehicleType,
                color: Colors.indigo,
              ),
              _InfoChip(
                icon: Icons.directions_car_outlined,
                label: vehicle.vehicleBrand.isNotEmpty
                    ? vehicle.vehicleBrand
                    : '-',
                color: Colors.teal,
              ),
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                label: vehicle.vehicleYear.toString(),
                color: Colors.orange,
              ),
              _InfoChip(
                icon: Icons.palette_outlined,
                label: vehicle.vehicleColor.isNotEmpty
                    ? vehicle.vehicleColor
                    : '-',
                color: Colors.purple,
              ),
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

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

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
          Icon(icon, size: 12, color: color[600]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color[700]),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final MaterialColor color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color[600], size: 18),
      ),
    );
  }
}

// ─── Dialog Form Armada ───────────────────────────────────────────────────────

class _VehicleFormDialog extends StatefulWidget {
  final FleetProvider provider;
  final Vehicle? vehicle; // null = tambah baru, tidak null = edit

  const _VehicleFormDialog({
    required this.provider,
    this.vehicle,
  });

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _driverNameCtrl;
  late TextEditingController _plateNumberCtrl;

  late String _selectedType;
  late String _selectedBrand;
  late String _selectedColor;
  late int _selectedYear;

  bool _isSaving = false;

  bool get isEdit => widget.vehicle != null;

  // Tahun 10 tahun ke belakang sampai tahun ini
  List<int> get _years {
    final now = DateTime.now().year;
    return List.generate(now - 2009, (i) => now - i);
  }

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    _driverNameCtrl = TextEditingController(text: v?.driverName ?? '');
    _plateNumberCtrl = TextEditingController(text: v?.plateNumber ?? '');
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
    _driverNameCtrl.dispose();
    _plateNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    if (isEdit) {
      await widget.provider.updateVehicleData(
        id: widget.vehicle!.id,
        driverName: _driverNameCtrl.text.trim(),
        plateNumber: _plateNumberCtrl.text.trim().toUpperCase(),
        vehicleType: _selectedType,
        vehicleBrand: _selectedBrand,
        vehicleYear: _selectedYear,
        vehicleColor: _selectedColor,
      );
    } else {
      await widget.provider.addVehicle(
        driverName: _driverNameCtrl.text.trim(),
        plateNumber: _plateNumberCtrl.text.trim().toUpperCase(),
        vehicleType: _selectedType,
        vehicleBrand: _selectedBrand,
        vehicleYear: _selectedYear,
        vehicleColor: _selectedColor,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────
          _DialogHeader(
            isEdit: isEdit,
            onClose: () => Navigator.pop(context),
          ),

          // ── Form ──────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Driver
                    _fieldLabel('NAMA DRIVER'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _driverNameCtrl,
                      hint: 'Masukkan nama driver...',
                      icon: Icons.person_outline,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Nama tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Plat Nomor
                    _fieldLabel('PLAT NOMOR KENDARAAN'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _plateNumberCtrl,
                      hint: 'Contoh: B 1234 CD',
                      icon: Icons.credit_card_outlined,
                      caps: TextCapitalization.characters,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Plat nomor tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Jenis Kendaraan
                    _fieldLabel('JENIS KENDARAAN'),
                    const SizedBox(height: 8),
                    _buildDropdown<String>(
                      value: _selectedType,
                      icon: Icons.category_outlined,
                      items: kVehicleTypes,
                      labelBuilder: (e) => e,
                      onChanged: (v) =>
                          setState(() => _selectedType = v!),
                    ),
                    const SizedBox(height: 16),

                    // Merek Kendaraan
                    _fieldLabel('MEREK KENDARAAN'),
                    const SizedBox(height: 8),
                    _buildDropdown<String>(
                      value: _selectedBrand,
                      icon: Icons.directions_car_outlined,
                      items: kVehicleBrands,
                      labelBuilder: (e) => e,
                      onChanged: (v) =>
                          setState(() => _selectedBrand = v!),
                    ),
                    const SizedBox(height: 16),

                    // Tahun & Warna — side by side
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('TAHUN'),
                              const SizedBox(height: 8),
                              _buildDropdown<int>(
                                value: _selectedYear,
                                icon:
                                    Icons.calendar_today_outlined,
                                items: _years,
                                labelBuilder: (e) => e.toString(),
                                onChanged: (v) => setState(
                                    () => _selectedYear = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _fieldLabel('WARNA'),
                              const SizedBox(height: 8),
                              _buildDropdown<String>(
                                value: _selectedColor,
                                icon: Icons.palette_outlined,
                                items: kVehicleColors,
                                labelBuilder: (e) => e,
                                onChanged: (v) => setState(
                                    () => _selectedColor = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tombol Aksi
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                              side: BorderSide(
                                  color: Colors.grey[300]!),
                            ),
                            child: Text('Batal',
                                style: TextStyle(
                                    color: Colors.grey[700])),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _handleSave,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor: Colors.indigo[600],
                              disabledBackgroundColor:
                                  Colors.indigo[300],
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
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
                                : const Text('Simpan Data',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight:
                                            FontWeight.bold)),
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

  // ── Helper widgets ─────────────────────────────────────

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextCapitalization caps = TextCapitalization.words,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
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
          borderSide:
              BorderSide(color: Colors.indigo[500]!, width: 2),
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

  Widget _buildDropdown<T>({
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
          borderSide:
              BorderSide(color: Colors.indigo[500]!, width: 2),
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

// ─── Dialog Header ────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  final bool isEdit;
  final VoidCallback onClose;

  const _DialogHeader({required this.isEdit, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.indigo[600],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.storage, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isEdit ? 'Edit Data Armada' : 'Tambah Armada Baru',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
          ),
          InkWell(
            onTap: onClose,
            child: const Icon(Icons.close,
                color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }
}