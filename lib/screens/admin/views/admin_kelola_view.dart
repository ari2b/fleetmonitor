import 'package:flutter/material.dart';
import '../../../providers/fleet_provider.dart';

class AdminKelolaTab extends StatelessWidget {
  final FleetProvider provider;
  const AdminKelolaTab({super.key, required this.provider});

  void _openModal(BuildContext context, {String? id, String? driverName, String? plateNumber}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => _VehicleFormDialog(
        provider: provider,
        id: id,
        initialDriverName: driverName ?? '',
        initialPlateNumber: plateNumber ?? '',
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
        content: Text('Apakah Anda yakin ingin menghapus kendaraan $plateNumber?'),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
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
            // Tambah Button
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

            // Vehicle list
            ...provider.vehicles.map((v) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.local_shipping,
                            color: Colors.grey[400], size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v.plateNumber,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              v.driverName,
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          // Edit button
                          InkWell(
                            onTap: () => _openModal(
                              context,
                              id: v.id,
                              driverName: v.driverName,
                              plateNumber: v.plateNumber,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.edit,
                                  color: Colors.blue[600], size: 18),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Delete button
                          InkWell(
                            onTap: () => _confirmDelete(context, v.id, v.plateNumber),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red[50],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.delete_outline,
                                  color: Colors.red[600], size: 18),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )),
          ],
        );
      },
    );
  }
}

class _VehicleFormDialog extends StatefulWidget {
  final FleetProvider provider;
  final String? id;
  final String initialDriverName;
  final String initialPlateNumber;

  const _VehicleFormDialog({
    required this.provider,
    this.id,
    required this.initialDriverName,
    required this.initialPlateNumber,
  });

  @override
  State<_VehicleFormDialog> createState() => _VehicleFormDialogState();
}

class _VehicleFormDialogState extends State<_VehicleFormDialog> {
  late TextEditingController _driverNameCtrl;
  late TextEditingController _plateNumberCtrl;
  final _formKey = GlobalKey<FormState>();

  bool get isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    _driverNameCtrl = TextEditingController(text: widget.initialDriverName);
    _plateNumberCtrl = TextEditingController(text: widget.initialPlateNumber);
  }

  @override
  void dispose() {
    _driverNameCtrl.dispose();
    _plateNumberCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      if (isEdit) {
        widget.provider.updateVehicleData(
          widget.id!,
          _driverNameCtrl.text.trim(),
          _plateNumberCtrl.text.trim().toUpperCase(),
        );
      } else {
        widget.provider.addVehicle(
          _driverNameCtrl.text.trim(),
          _plateNumberCtrl.text.trim().toUpperCase(),
        );
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
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
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white70, size: 20),
                )
              ],
            ),
          ),

          // Form
          Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Driver Name
                  const Text(
                    'NAMA DRIVER',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _driverNameCtrl,
                    decoration: InputDecoration(
                      hintText: 'Masukkan nama driver...',
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),

                  // Plate Number
                  const Text(
                    'PLAT NOMOR KENDARAAN',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _plateNumberCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Contoh: B 1234 CD',
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
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                    validator: (val) =>
                        (val == null || val.trim().isEmpty) ? 'Plat nomor tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
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
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            backgroundColor: Colors.indigo[600],
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('Simpan Data',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}