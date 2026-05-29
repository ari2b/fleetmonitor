import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/driver_model.dart';
import '../../../models/schedule_model.dart';

// ─── Warna Status Jadwal ──────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status) {
    case 'confirmed':
      return Colors.blue[600]!;
    case 'completed':
      return Colors.green[600]!;
    case 'cancelled':
      return Colors.red[600]!;
    default:
      return Colors.orange[600]!;
  }
}

Color _statusBg(String status) {
  switch (status) {
    case 'confirmed':
      return Colors.blue[50]!;
    case 'completed':
      return Colors.green[50]!;
    case 'cancelled':
      return Colors.red[50]!;
    default:
      return Colors.orange[50]!;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'confirmed':
      return 'Dikonfirmasi';
    case 'completed':
      return 'Selesai';
    case 'cancelled':
      return 'Dibatalkan';
    default:
      return 'Menunggu';
  }
}

// ─── Admin Jadwal View ────────────────────────────────────────────────────────

class AdminJadwalView extends StatefulWidget {
  final Driver driver;
  const AdminJadwalView({super.key, required this.driver});

  @override
  State<AdminJadwalView> createState() => _AdminJadwalViewState();
}

class _AdminJadwalViewState extends State<AdminJadwalView> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Schedule> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final snap = await _db
          .collection('schedules')
          .where('driverId', isEqualTo: widget.driver.id)
          .orderBy('scheduleDate', descending: false)
          .get();
      _schedules =
          snap.docs.map((d) => Schedule.fromMap(d.id, d.data())).toList();
    } catch (_) {
      _schedules = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _addSchedule(Schedule s) async {
    final docRef = _db.collection('schedules').doc();
    await docRef.set({
      ...s.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    final newSchedule = Schedule.fromMap(docRef.id, s.toMap());
    _schedules.add(newSchedule);
    if (mounted) setState(() {});
  }

  Future<void> _updateSchedule(Schedule s) async {
    await _db.collection('schedules').doc(s.id).update(s.toMap());
    final idx = _schedules.indexWhere((x) => x.id == s.id);
    if (idx != -1) _schedules[idx] = s;
    if (mounted) setState(() {});
  }

  Future<void> _deleteSchedule(String id) async {
    await _db.collection('schedules').doc(id).delete();
    _schedules.removeWhere((s) => s.id == id);
    if (mounted) setState(() {});
  }

  void _openForm({Schedule? schedule}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ScheduleFormDialog(
        driver: widget.driver,
        schedule: schedule,
        onSave: (s, isNew) async {
          if (isNew) {
            await _addSchedule(s);
          } else {
            await _updateSchedule(s);
          }
        },
      ),
    );
  }

  void _confirmDelete(Schedule s) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Jadwal'),
          ],
        ),
        content: Text('Hapus jadwal "${s.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteSchedule(s.id);
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
        backgroundColor: Colors.orange[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jadwal — ${widget.driver.name}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            const Text(
              'Kelola jadwal kegiatan driver',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSchedules,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Info driver
                  _DriverBanner(driver: widget.driver),
                  const SizedBox(height: 16),

                  // Tombol tambah jadwal
                  OutlinedButton.icon(
                    onPressed: () => _openForm(),
                    icon: Icon(Icons.add_circle_outline,
                        color: Colors.orange[700]),
                    label: Text(
                      'Tambah Jadwal Baru',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700]),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: BorderSide(color: Colors.orange[200]!, width: 1.5),
                      backgroundColor: Colors.orange[50],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Daftar jadwal
                  if (_schedules.isEmpty)
                    _EmptySchedule()
                  else
                    ..._schedules.map((s) => _ScheduleCard(
                          schedule: s,
                          onEdit: () => _openForm(schedule: s),
                          onDelete: () => _confirmDelete(s),
                        )),
                ],
              ),
            ),
    );
  }
}

// ─── Driver Banner ────────────────────────────────────────────────────────────

class _DriverBanner extends StatelessWidget {
  final Driver driver;
  const _DriverBanner({required this.driver});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[100]!),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withOpacity(0.06),
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
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            alignment: Alignment.center,
            child: Text(
              driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: driver.status == 'aktif'
                        ? Colors.green[50]
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: driver.status == 'aktif'
                          ? Colors.green[200]!
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    driver.status == 'aktif' ? 'AKTIF' : 'NON-AKTIF',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: driver.status == 'aktif'
                          ? Colors.green[700]
                          : Colors.grey[500],
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

// ─── Schedule Card ────────────────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ScheduleCard({
    required this.schedule,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(schedule.status);
    final bgColor = _statusBg(schedule.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          // Header card
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.event_rounded, color: color, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.grey[800]),
                      ),
                      Text(
                        _formatDate(schedule.scheduleDate),
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Text(
                    _statusLabel(schedule.status),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') onEdit();
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Edit')
                        ])),
                    const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus',
                              style: TextStyle(color: Colors.red))
                        ])),
                  ],
                  icon: Icon(Icons.more_vert,
                      color: Colors.grey[500], size: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ],
            ),
          ),

          // Body card
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (schedule.startTime.isNotEmpty ||
                    schedule.endTime.isNotEmpty)
                  _InfoRow(
                    icon: Icons.access_time_rounded,
                    text:
                        '${schedule.startTime} — ${schedule.endTime}',
                    color: Colors.blue,
                  ),
                if (schedule.location.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: schedule.location,
                    color: Colors.red,
                  ),
                ],
                if (schedule.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Text(
                    schedule.description,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final MaterialColor color;

  const _InfoRow(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color[500]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style:
                  TextStyle(fontSize: 12, color: Colors.grey[700])),
        ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptySchedule extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.calendar_today_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Belum ada jadwal untuk driver ini.\nTambahkan jadwal baru di atas.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey[400], fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Dialog Form Jadwal ───────────────────────────────────────────────────────

class _ScheduleFormDialog extends StatefulWidget {
  final Driver driver;
  final Schedule? schedule;
  final Future<void> Function(Schedule s, bool isNew) onSave;

  const _ScheduleFormDialog({
    required this.driver,
    this.schedule,
    required this.onSave,
  });

  @override
  State<_ScheduleFormDialog> createState() => _ScheduleFormDialogState();
}

class _ScheduleFormDialogState extends State<_ScheduleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;

  late DateTime _selectedDate;
  late String _selectedStatus;
  bool _isSaving = false;

  bool get isEdit => widget.schedule != null;

  static const List<String> _statuses = [
    'pending',
    'confirmed',
    'completed',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    _titleCtrl = TextEditingController(text: s?.title ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _locationCtrl = TextEditingController(text: s?.location ?? '');
    _startCtrl = TextEditingController(text: s?.startTime ?? '');
    _endCtrl = TextEditingController(text: s?.endTime ?? '');
    _selectedDate = s?.scheduleDate ?? DateTime.now();
    _selectedStatus = s?.status ?? 'pending';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final initial = parts.length == 2
        ? TimeOfDay(
            hour: int.tryParse(parts[0]) ?? 8,
            minute: int.tryParse(parts[1]) ?? 0)
        : const TimeOfDay(hour: 8, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      ctrl.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final schedule = Schedule(
      id: widget.schedule?.id ?? '',
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      driverId: widget.driver.id,
      driverName: widget.driver.name,
      scheduleDate: _selectedDate,
      startTime: _startCtrl.text.trim(),
      endTime: _endCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      status: _selectedStatus,
    );

    await widget.onSave(schedule, !isEdit);
    if (mounted) Navigator.pop(context);
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.orange[700],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit Jadwal' : 'Tambah Jadwal',
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
                    _label('JUDUL KEGIATAN *'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleCtrl,
                      decoration: _inputDeco(
                          'Contoh: Pengiriman Barang ke Surabaya',
                          Icons.title_rounded),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Judul tidak boleh kosong'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    _label('TANGGAL *'),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                color: Colors.grey[400], size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _formatDate(_selectedDate),
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[800]),
                            ),
                            const Spacer(),
                            Icon(Icons.edit_calendar_outlined,
                                color: Colors.orange[400], size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('JAM MULAI'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _startCtrl,
                                readOnly: true,
                                onTap: () => _pickTime(_startCtrl),
                                decoration: _inputDeco(
                                    '08:00', Icons.access_time_rounded),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('JAM SELESAI'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _endCtrl,
                                readOnly: true,
                                onTap: () => _pickTime(_endCtrl),
                                decoration: _inputDeco(
                                    '17:00', Icons.access_time_outlined),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    _label('LOKASI / TUJUAN'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _locationCtrl,
                      decoration: _inputDeco(
                          'Contoh: Gudang Madiun → Surabaya',
                          Icons.location_on_outlined),
                    ),
                    const SizedBox(height: 14),

                    _label('KETERANGAN / DESKRIPSI'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 3,
                      decoration: _inputDeco(
                          'Catatan tambahan untuk driver...',
                          Icons.description_outlined),
                    ),
                    const SizedBox(height: 14),

                    _label('STATUS'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      onChanged: (v) =>
                          setState(() => _selectedStatus = v!),
                      decoration: _inputDeco('', Icons.flag_outlined),
                      items: _statuses
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _statusColor(e),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(_statusLabel(e),
                                        style: const TextStyle(
                                            fontSize: 14)),
                                  ],
                                ),
                              ))
                          .toList(),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      icon: Icon(Icons.expand_more,
                          color: Colors.grey[400]),
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
                              backgroundColor: Colors.orange[700],
                              disabledBackgroundColor:
                                  Colors.orange[300],
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
                                        strokeWidth: 2.5))
                                : const Text('Simpan',
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
          borderSide: BorderSide(color: Colors.orange[500]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[300]!, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}