import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/schedule_model.dart';

// ─── Helpers warna & label ────────────────────────────────────────────────────

Color _statusColor(String s) {
  switch (s) {
    case 'confirmed': return Colors.blue[600]!;
    case 'completed': return Colors.green[600]!;
    case 'cancelled': return Colors.red[600]!;
    default:          return Colors.orange[600]!;
  }
}

Color _statusBg(String s) {
  switch (s) {
    case 'confirmed': return Colors.blue[50]!;
    case 'completed': return Colors.green[50]!;
    case 'cancelled': return Colors.red[50]!;
    default:          return Colors.orange[50]!;
  }
}

IconData _statusIcon(String s) {
  switch (s) {
    case 'confirmed': return Icons.check_circle_rounded;
    case 'completed': return Icons.task_alt_rounded;
    case 'cancelled': return Icons.cancel_rounded;
    default:          return Icons.access_time_rounded;
  }
}

String _statusLabel(String s) {
  switch (s) {
    case 'confirmed': return 'Dikonfirmasi';
    case 'completed': return 'Selesai';
    case 'cancelled': return 'Dibatalkan';
    default:          return 'Menunggu';
  }
}

String _formatDate(DateTime d) {
  const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
  const days   = ['Senin','Selasa','Rabu','Kamis','Jumat','Sabtu','Minggu'];
  return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
}

// ═════════════════════════════════════════════════════════════════════════════
// DriverJadwalView — entry point
// ═════════════════════════════════════════════════════════════════════════════

class DriverJadwalView extends StatefulWidget {
  /// [driverId]   : Firebase Auth UID dari koleksi 'users'
  /// [driverName] : Nama driver (dipakai sebagai query utama, karena admin
  ///                menyimpan jadwal dengan field driverName)
  final String driverId;
  final String driverName;

  const DriverJadwalView({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  State<DriverJadwalView> createState() => _DriverJadwalViewState();
}

class _DriverJadwalViewState extends State<DriverJadwalView>
    with SingleTickerProviderStateMixin {
  final _db = FirebaseFirestore.instance;

  late TabController _tabController;
  static const _tabs = ['Semua', 'Aktif', 'Riwayat'];

  // Hasil gabungan dari dua sumber query (by driverId & by driverName)
  final ValueNotifier<List<Schedule>> _merged = ValueNotifier([]);
  final ValueNotifier<bool> _isLoading = ValueNotifier(true);
  final ValueNotifier<String?> _errorMsg = ValueNotifier(null);

  StreamSubscription<QuerySnapshot>? _subById;
  StreamSubscription<QuerySnapshot>? _subByName;

  List<Schedule> _byId = [];
  List<Schedule> _byName = [];
  bool _gotId = false;
  bool _gotName = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _listenSchedules();
  }

  void _listenSchedules() {
    // Sumber 1: berdasarkan driverId (UID Firebase Auth driver)
    _subById = _db
        .collection('schedules')
        .where('driverId', isEqualTo: widget.driverId)
        .snapshots()
        .listen((snap) {
      _byId = snap.docs
          .map((d) => Schedule.fromMap(d.id, d.data()))
          .toList();
      _gotId = true;
      _recompute();
    }, onError: (e) {
      _gotId = true;
      _recompute();
    });

    // Sumber 2: berdasarkan driverName (nama driver — sesuai data admin saat ini)
    _subByName = _db
        .collection('schedules')
        .where('driverName', isEqualTo: widget.driverName)
        .snapshots()
        .listen((snap) {
      _byName = snap.docs
          .map((d) => Schedule.fromMap(d.id, d.data()))
          .toList();
      _gotName = true;
      _recompute();
    }, onError: (e) {
      _errorMsg.value = e.toString();
      _gotName = true;
      _recompute();
    });
  }

  void _recompute() {
    final seen = <String>{};
    final list = <Schedule>[];
    for (final s in [..._byId, ..._byName]) {
      if (seen.add(s.id)) list.add(s);
    }
    list.sort((a, b) => a.scheduleDate.compareTo(b.scheduleDate));
    _merged.value = list;
    if (_gotId && _gotName) {
      _isLoading.value = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subById?.cancel();
    _subByName?.cancel();
    _merged.dispose();
    _isLoading.dispose();
    _errorMsg.dispose();
    super.dispose();
  }

  // ── Update status jadwal ke Firestore ─────────────────
  Future<void> _updateStatus(Schedule s, String newStatus) async {
    try {
      await _db.collection('schedules').doc(s.id).update({
        'status': newStatus,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Icon(_statusIcon(newStatus), color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Jadwal ${_statusLabel(newStatus).toLowerCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          backgroundColor: _statusColor(newStatus),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Gagal memperbarui status.')));
      }
    }
  }

  // ── Tampilkan pop-up detail + tombol aksi ─────────────
  void _showDetailPopup(Schedule s) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _ScheduleDetailDialog(
        schedule: s,
        onConfirm:  () => _updateStatus(s, 'confirmed'),
        onCancel:   () => _updateStatus(s, 'cancelled'),
        onComplete: () => _updateStatus(s, 'completed'),
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
            const Text('Jadwal Saya',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(widget.driverName,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: _tabs
              .map((t) => Tab(
                  child: Text(t,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13))))
              .toList(),
        ),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: _isLoading,
        builder: (context, loading, _) {
          if (loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ValueListenableBuilder<String?>(
            valueListenable: _errorMsg,
            builder: (context, error, __) {
              return ValueListenableBuilder<List<Schedule>>(
                valueListenable: _merged,
                builder: (context, all, ___) {
                  final active = all
                      .where((s) =>
                          s.status == 'pending' || s.status == 'confirmed')
                      .toList();
                  final history = all
                      .where((s) =>
                          s.status == 'completed' || s.status == 'cancelled')
                      .toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _ScheduleList(
                        schedules: all,
                        onTap: _showDetailPopup,
                        emptyMsg:
                            'Belum ada jadwal.\nAdmin akan menambahkan jadwal untuk Anda.',
                      ),
                      _ScheduleList(
                        schedules: active,
                        onTap: _showDetailPopup,
                        emptyMsg: 'Tidak ada jadwal aktif saat ini.',
                      ),
                      _ScheduleList(
                        schedules: history,
                        onTap: _showDetailPopup,
                        emptyMsg: 'Belum ada riwayat jadwal.',
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Schedule List ────────────────────────────────────────────────────────────

class _ScheduleList extends StatelessWidget {
  final List<Schedule> schedules;
  final void Function(Schedule) onTap;
  final String emptyMsg;

  const _ScheduleList({
    required this.schedules,
    required this.onTap,
    required this.emptyMsg,
  });

  @override
  Widget build(BuildContext context) {
    if (schedules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today_outlined, size: 72, color: Colors.grey[300]),
              const SizedBox(height: 18),
              Text(emptyMsg,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey[400], fontSize: 14, height: 1.6)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: schedules.length,
      itemBuilder: (_, i) => _ScheduleCard(
        schedule: schedules[i],
        onTap: () => onTap(schedules[i]),
      ),
    );
  }
}

// ─── Schedule Card (list item) ────────────────────────────────────────────────

class _ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onTap;

  const _ScheduleCard({required this.schedule, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color  = _statusColor(schedule.status);
    final bgColor = _statusBg(schedule.status);
    final isPending = schedule.status == 'pending';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPending ? Colors.orange[300]! : Colors.grey[200]!,
            width: isPending ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          children: [
            // ── Header berwarna ───────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
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
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Icon(Icons.event_rounded, color: color, size: 17),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(schedule.title,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.grey[800])),
                        Text(_formatDate(schedule.scheduleDate),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  // Badge status
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Text(_statusLabel(schedule.status),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color)),
                  ),
                ],
              ),
            ),

            // ── Info singkat ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (schedule.startTime.isNotEmpty)
                    _MiniRow(
                      icon: Icons.access_time_rounded,
                      text: '${schedule.startTime} — ${schedule.endTime}',
                      color: Colors.blue,
                    ),
                  if (schedule.location.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    _MiniRow(
                      icon: Icons.location_on_outlined,
                      text: schedule.location,
                      color: Colors.red,
                    ),
                  ],
                  // Hint ketuk untuk aksi
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isPending)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.touch_app_rounded,
                                  size: 12, color: Colors.orange[700]),
                              const SizedBox(width: 4),
                              Text('Perlu konfirmasi',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else
                        Row(
                          children: [
                            Icon(Icons.touch_app_rounded,
                                size: 12, color: Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text('Ketuk untuk detail',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[400])),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final MaterialColor color;
  const _MiniRow({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color[500]),
        const SizedBox(width: 5),
        Expanded(
          child: Text(text,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

// ─── Pop-up Detail Jadwal ─────────────────────────────────────────────────────

class _ScheduleDetailDialog extends StatefulWidget {
  final Schedule schedule;
  final Future<void> Function() onConfirm;
  final Future<void> Function() onCancel;
  final Future<void> Function() onComplete;

  const _ScheduleDetailDialog({
    required this.schedule,
    required this.onConfirm,
    required this.onCancel,
    required this.onComplete,
  });

  @override
  State<_ScheduleDetailDialog> createState() => _ScheduleDetailDialogState();
}

class _ScheduleDetailDialogState extends State<_ScheduleDetailDialog> {
  bool _loading = false;

  bool get _isPending   => widget.schedule.status == 'pending';
  bool get _isConfirmed => widget.schedule.status == 'confirmed';
  bool get _isHistory   =>
      widget.schedule.status == 'completed' ||
      widget.schedule.status == 'cancelled';

  // ── Dialog konfirmasi 2 langkah ────────────────────────
  void _confirm2Step(
    String title,
    String body,
    Color btnColor,
    String btnLabel,
    Future<void> Function() action,
  ) {
    Navigator.pop(context); // tutup detail dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(body,
            style: TextStyle(color: Colors.grey[600], height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await action();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: btnColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(btnLabel,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s     = widget.schedule;
    final color  = _statusColor(s.status);
    final bgColor = _statusBg(s.status);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_statusIcon(s.status),
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_statusLabel(s.status),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, color: Colors.white70, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // ── Body detail ───────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info baris
                  _DetailRow(
                    icon: Icons.calendar_today_rounded,
                    label: 'Tanggal',
                    value: _formatDate(s.scheduleDate),
                    color: Colors.indigo,
                  ),
                  if (s.startTime.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons.access_time_rounded,
                      label: 'Waktu',
                      value: '${s.startTime} — ${s.endTime}',
                      color: Colors.blue,
                    ),
                  ],
                  if (s.location.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons.location_on_rounded,
                      label: 'Lokasi',
                      value: s.location,
                      color: Colors.red,
                    ),
                  ],
                  if (s.description.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Icon(Icons.notes_rounded,
                            size: 14, color: Colors.grey[400]),
                        const SizedBox(width: 6),
                        Text('KETERANGAN',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[400],
                                letterSpacing: 0.8)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(s.description,
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                              height: 1.5)),
                    ),
                  ],

                  // ── Tombol aksi ─────────────────────────────
                  if (!_isHistory) ...[
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Pending: tampilkan Konfirmasi + Batalkan
                    if (_isPending) ...[
                      // Banner peringatan
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.orange[700], size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Jadwal ini menunggu konfirmasi Anda.',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.orange[800]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Batalkan',
                              icon: Icons.cancel_outlined,
                              color: Colors.red[600]!,
                              outlined: true,
                              loading: _loading,
                              onTap: () => _confirm2Step(
                                'Batalkan Jadwal',
                                'Apakah Anda yakin ingin membatalkan\n"${s.title}"?',
                                Colors.red[600]!,
                                'Ya, Batalkan',
                                widget.onCancel,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionButton(
                              label: 'Konfirmasi',
                              icon: Icons.check_circle_outline,
                              color: Colors.blue[600]!,
                              loading: _loading,
                              onTap: () => _confirm2Step(
                                'Konfirmasi Jadwal',
                                'Apakah Anda siap melaksanakan\n"${s.title}"?',
                                Colors.blue[600]!,
                                'Ya, Konfirmasi',
                                widget.onConfirm,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Confirmed: tampilkan Batalkan + Tandai Selesai
                    if (_isConfirmed) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Colors.blue[700], size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Jadwal sudah dikonfirmasi. Tandai selesai setelah dilaksanakan.',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.blue[800]),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Batalkan',
                              icon: Icons.cancel_outlined,
                              color: Colors.red[600]!,
                              outlined: true,
                              loading: _loading,
                              onTap: () => _confirm2Step(
                                'Batalkan Jadwal',
                                'Apakah Anda yakin ingin membatalkan\n"${s.title}"?',
                                Colors.red[600]!,
                                'Ya, Batalkan',
                                widget.onCancel,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionButton(
                              label: 'Selesai',
                              icon: Icons.task_alt_rounded,
                              color: Colors.green[600]!,
                              loading: _loading,
                              onTap: () => _confirm2Step(
                                'Tandai Selesai',
                                'Apakah jadwal\n"${s.title}"\nsudah selesai dilaksanakan?',
                                Colors.green[600]!,
                                'Ya, Selesai',
                                widget.onComplete,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],

                  // Riwayat: tampilkan info saja
                  if (_isHistory) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(_statusIcon(s.status), color: color, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Jadwal ini sudah ${_statusLabel(s.status).toLowerCase()}.',
                              style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: Text('Tutup',
                            style: TextStyle(color: Colors.grey[700])),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Button helper ─────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool outlined;
  final bool loading;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: loading ? null : onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.6)),
          minimumSize: const Size(0, 46),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: loading ? null : onTap,
      icon: loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2))
          : Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 46),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

// ─── Detail Row helper ────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final MaterialColor color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: color[600]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[400],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}