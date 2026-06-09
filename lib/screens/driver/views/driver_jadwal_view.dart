import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/schedule_model.dart';

// ─── Warna & Label Status ─────────────────────────────────────────────────────

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

// ─── Driver Jadwal View ───────────────────────────────────────────────────────

class DriverJadwalView extends StatefulWidget {
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
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<Schedule> _schedules = [];
  bool _isLoading = true;
  late TabController _tabController;

  // Filter tab: semua, aktif (pending/confirmed), selesai/batal
  static const List<String> _tabs = ['Semua', 'Aktif', 'Riwayat'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSchedules();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);
    try {
      final snap = await _db
          .collection('schedules')
          .where('driverId', isEqualTo: widget.driverId)
          .orderBy('scheduleDate', descending: false)
          .get();
      _schedules =
          snap.docs.map((d) => Schedule.fromMap(d.id, d.data())).toList();
    } catch (_) {
      _schedules = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<Schedule> get _allSchedules => _schedules;
  List<Schedule> get _activeSchedules => _schedules
      .where((s) => s.status == 'pending' || s.status == 'confirmed')
      .toList();
  List<Schedule> get _historySchedules => _schedules
      .where((s) => s.status == 'completed' || s.status == 'cancelled')
      .toList();

  // Driver hanya bisa update ke: confirmed, completed, cancelled
  void _showUpdateStatusDialog(Schedule schedule) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StatusUpdateSheet(
        schedule: schedule,
        onUpdate: (newStatus) async {
          await _updateStatus(schedule, newStatus);
        },
      ),
    );
  }

  Future<void> _updateStatus(Schedule schedule, String newStatus) async {
    try {
      await _db
          .collection('schedules')
          .doc(schedule.id)
          .update({'status': newStatus});
      final idx = _schedules.indexWhere((s) => s.id == schedule.id);
      if (idx != -1) {
        setState(() {
          _schedules[idx] = Schedule(
            id: schedule.id,
            title: schedule.title,
            description: schedule.description,
            driverId: schedule.driverId,
            driverName: schedule.driverName,
            scheduleDate: schedule.scheduleDate,
            startTime: schedule.startTime,
            endTime: schedule.endTime,
            location: schedule.location,
            status: newStatus,
          );
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Status diperbarui ke: ${_statusLabel(newStatus)}'),
            backgroundColor: _statusColor(newStatus),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memperbarui status.')),
        );
      }
    }
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
            const Text(
              'Jadwal Saya',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            Text(
              widget.driverName,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorWeight: 3,
          tabs: _tabs
              .map((t) => Tab(
                    child: Text(t,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13)),
                  ))
              .toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _ScheduleList(
                  schedules: _allSchedules,
                  onUpdateStatus: _showUpdateStatusDialog,
                  onRefresh: _loadSchedules,
                  emptyMessage:
                      'Belum ada jadwal.\nAdmin akan menambahkan jadwal untuk Anda.',
                ),
                _ScheduleList(
                  schedules: _activeSchedules,
                  onUpdateStatus: _showUpdateStatusDialog,
                  onRefresh: _loadSchedules,
                  emptyMessage:
                      'Tidak ada jadwal aktif saat ini.',
                ),
                _ScheduleList(
                  schedules: _historySchedules,
                  onUpdateStatus: _showUpdateStatusDialog,
                  onRefresh: _loadSchedules,
                  emptyMessage: 'Belum ada riwayat jadwal.',
                  isHistory: true,
                ),
              ],
            ),
    );
  }
}

// ─── Schedule List ────────────────────────────────────────────────────────────

class _ScheduleList extends StatelessWidget {
  final List<Schedule> schedules;
  final void Function(Schedule) onUpdateStatus;
  final Future<void> Function() onRefresh;
  final String emptyMessage;
  final bool isHistory;

  const _ScheduleList({
    required this.schedules,
    required this.onUpdateStatus,
    required this.onRefresh,
    required this.emptyMessage,
    this.isHistory = false,
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
              Icon(Icons.calendar_today_outlined,
                  size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey[400], fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: schedules.length,
        itemBuilder: (_, i) => _DriverScheduleCard(
          schedule: schedules[i],
          onUpdateStatus: () => onUpdateStatus(schedules[i]),
          isHistory: isHistory,
        ),
      ),
    );
  }
}

// ─── Driver Schedule Card ─────────────────────────────────────────────────────

class _DriverScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onUpdateStatus;
  final bool isHistory;

  const _DriverScheduleCard({
    required this.schedule,
    required this.onUpdateStatus,
    this.isHistory = false,
  });

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

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(schedule.status);
    final bgColor = _statusBg(schedule.status);
    final canUpdate =
        schedule.status == 'pending' || schedule.status == 'confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: canUpdate ? color.withOpacity(0.3) : Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ───────────────────────────────────
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              ],
            ),
          ),

          // ── Body ─────────────────────────────────────
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

                // ── Tombol Update Status (hanya jika aktif) ──
                if (canUpdate) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 6),
                      Text(
                        'Perbarui status jika ada perubahan:',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onUpdateStatus,
                      icon: Icon(Icons.edit_note_rounded,
                          size: 18, color: Colors.indigo[600]),
                      label: Text(
                        'Perbarui Status Jadwal',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[600]),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        side: BorderSide(
                            color: Colors.indigo[200]!, width: 1.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Colors.indigo[50],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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

// ─── Bottom Sheet Update Status ───────────────────────────────────────────────

class _StatusUpdateSheet extends StatefulWidget {
  final Schedule schedule;
  final Future<void> Function(String) onUpdate;

  const _StatusUpdateSheet({
    required this.schedule,
    required this.onUpdate,
  });

  @override
  State<_StatusUpdateSheet> createState() => _StatusUpdateSheetState();
}

class _StatusUpdateSheetState extends State<_StatusUpdateSheet> {
  String? _selected;
  bool _isLoading = false;

  // Driver hanya bisa update ke status ini:
  static const List<Map<String, dynamic>> _options = [
    {
      'value': 'confirmed',
      'label': 'Dikonfirmasi',
      'desc': 'Saya siap menjalankan jadwal ini',
      'icon': Icons.check_circle_outline_rounded,
      'color': Colors.blue,
    },
    {
      'value': 'completed',
      'label': 'Selesai',
      'desc': 'Jadwal telah selesai dilaksanakan',
      'icon': Icons.task_alt_rounded,
      'color': Colors.green,
    },
    {
      'value': 'cancelled',
      'label': 'Dibatalkan',
      'desc': 'Tidak dapat melaksanakan jadwal ini',
      'icon': Icons.cancel_outlined,
      'color': Colors.red,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.schedule.status;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 20,
        right: 20,
        top: 0,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.edit_note_rounded,
                    color: Colors.indigo[600], size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Perbarui Status Jadwal',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      widget.schedule.title,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          ..._options.map((opt) {
            final isSelected = _selected == opt['value'];
            final color = opt['color'] as MaterialColor;
            return GestureDetector(
              onTap: () => setState(() => _selected = opt['value']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? color[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color[300]! : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      opt['icon'] as IconData,
                      color: isSelected ? color[600] : Colors.grey[400],
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            opt['label'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSelected
                                  ? color[700]
                                  : Colors.grey[700],
                            ),
                          ),
                          Text(
                            opt['desc'] as String,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.radio_button_checked,
                          color: color[600], size: 20)
                    else
                      Icon(Icons.radio_button_unchecked,
                          color: Colors.grey[300], size: 20),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
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
                  onPressed: (_isLoading ||
                          _selected == widget.schedule.status)
                      ? null
                      : () async {
                          setState(() => _isLoading = true);
                          await widget.onUpdate(_selected!);
                          if (context.mounted) Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    backgroundColor: Colors.indigo[600],
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isLoading
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
    );
  }
}