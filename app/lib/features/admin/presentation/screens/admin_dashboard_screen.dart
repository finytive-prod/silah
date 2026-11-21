import 'package:flutter/material.dart';
import 'package:masjid_namaz_app/core/network/api_service.dart';
import 'package:masjid_namaz_app/features/prayer_times/presentation/screens/home_screen.dart';
import 'package:masjid_namaz_app/features/auth/presentation/screens/otp_login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;

  String? _masjidId;
  String? _masjidName;
  Map<String, dynamic>? _masjidDetails;
  Map<String, dynamic>? _adminOverview;
  Map<String, dynamic>? _todayPrayerTimes;
  List<dynamic> _specialSchedules = [];
  List<dynamic> _announcements = [];
  Map<String, dynamic>? _membersData;

  @override
  void initState() {
    super.initState();
    _loadMasjidData();
  }

  Future<void> _loadMasjidData() async {
    setState(() => _isLoading = true);
    try {
      final user = await ApiService.instance.getProfile();
      final adminRoles = user?['adminRoles'] as List<dynamic>?;

      if (adminRoles != null && adminRoles.isNotEmpty) {
        final primary = adminRoles.first;
        final mId = primary['masjidId'];
        _masjidId = mId;
        _masjidName = primary['masjidName'] ?? 'Masjid Admin';

        final overview = await ApiService.instance.getMasjidAdminOverview(mId);
        final todayTimes = await ApiService.instance.getTodayPrayerTimes(mId);
        final schedules = await ApiService.instance.getSpecialSchedules(mId);
        final notices = await ApiService.instance.getAnnouncements(mId);
        final members = await ApiService.instance.getMasjidMembers(mId);

        if (mounted) {
          setState(() {
            _adminOverview = overview;
            _masjidDetails = overview?['masjid'];
            _todayPrayerTimes = todayTimes;
            _specialSchedules = schedules;
            _announcements = notices;
            _membersData = members;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------------------------------------------------
  // TAB 1: Dashboard Overview
  // -------------------------------------------------------------
  Widget _buildDashboardTab() {
    final metrics = _adminOverview?['metrics'] ?? {};
    final memberCount = metrics['memberCount'] ?? 0;
    final noticesCount = metrics['activeAnnouncementsCount'] ?? _announcements.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        title: Text(_masjidName ?? 'Masjid Admin Dashboard', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F432B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadMasjidData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Banner
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: const Color(0xFF0F432B),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_masjidName ?? 'Masjid', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          '${_masjidDetails?['city'] ?? ''} • Admin Portal',
                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _statBadge('Members Connected', '$memberCount', Icons.people),
                            const SizedBox(width: 12),
                            _statBadge('Active Notices', '$noticesCount', Icons.campaign),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Today Prayer Times Card
                const Text("Today's Prayer Schedule", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _todayPrayerTimes == null
                        ? const Text('No prayer times configured for today.', style: TextStyle(color: Colors.grey))
                        : Column(
                            children: [
                              _prayerRow('Fajr', _todayPrayerTimes?['fajrAdhan'], _todayPrayerTimes?['fajrJamaah']),
                              const Divider(),
                              _prayerRow('Dhuhr', _todayPrayerTimes?['dhuhrAdhan'], _todayPrayerTimes?['dhuhrJamaah']),
                              const Divider(),
                              _prayerRow('Asr', _todayPrayerTimes?['asrAdhan'], _todayPrayerTimes?['asrJamaah']),
                              const Divider(),
                              _prayerRow('Maghrib', _todayPrayerTimes?['maghribAdhan'], _todayPrayerTimes?['maghribJamaah']),
                              const Divider(),
                              _prayerRow('Isha', _todayPrayerTimes?['ishaAdhan'], _todayPrayerTimes?['ishaJamaah']),
                              if (_todayPrayerTimes?['jummahJamaah'] != null) ...[
                                const Divider(),
                                _prayerRow('Jummah', _todayPrayerTimes?['jummahKhutbah'], _todayPrayerTimes?['jummahJamaah']),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statBadge(String title, String val, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(val, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _prayerRow(String name, String? adhan, String? jamaah) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Row(
            children: [
              if (adhan != null) ...[
                Text('Adhan: $adhan', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 14),
              ],
              Text('Jamaah: ${jamaah ?? '--:--'}', style: const TextStyle(color: Color(0xFF0F432B), fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: Manage Prayer Times & Special Events
  // -------------------------------------------------------------
  Widget _buildPrayerTimesTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        title: const Text('Manage Prayer & Events', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F432B),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Prayer Times Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Prayer Timings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F432B), foregroundColor: Colors.white),
                icon: const Icon(Icons.date_range, size: 16),
                label: const Text('Set Date Range', style: TextStyle(fontSize: 12)),
                onPressed: _showDateRangePrayerDialog,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Solar Times Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny_outlined, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sunrise (Ishraq)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(_todayPrayerTimes?['fajrJamaah'] != null ? '06:05 AM' : '--:--', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  Container(height: 24, width: 1, color: Colors.grey.shade300),
                  Row(
                    children: [
                      const Icon(Icons.nights_stay_outlined, color: Colors.indigo, size: 20),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Sunset (Maghrib)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(_todayPrayerTimes?['maghribJamaah'] != null ? '${_todayPrayerTimes?['maghribJamaah']} PM' : '--:--', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Daily Prayer Times Config Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Today Timings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      TextButton.icon(
                        icon: const Icon(Icons.edit, size: 14),
                        label: const Text('Edit Today'),
                        onPressed: _showSingleDayPrayerDialog,
                      ),
                    ],
                  ),
                  _prayerRow('Fajr', _todayPrayerTimes?['fajrAdhan'], _todayPrayerTimes?['fajrJamaah']),
                  const Divider(),
                  _prayerRow('Dhuhr', _todayPrayerTimes?['dhuhrAdhan'], _todayPrayerTimes?['dhuhrJamaah']),
                  const Divider(),
                  _prayerRow('Asr', _todayPrayerTimes?['asrAdhan'], _todayPrayerTimes?['asrJamaah']),
                  const Divider(),
                  _prayerRow('Maghrib', _todayPrayerTimes?['maghribAdhan'], _todayPrayerTimes?['maghribJamaah']),
                  const Divider(),
                  _prayerRow('Isha', _todayPrayerTimes?['ishaAdhan'], _todayPrayerTimes?['ishaJamaah']),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Special Events Section (Ramadan, Eid, Taraweeh, Tahajjud)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Special Events (Ramadan / Eid)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F432B), foregroundColor: Colors.white),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Event', style: TextStyle(fontSize: 12)),
                onPressed: _showAddSpecialEventDialog,
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (_specialSchedules.isEmpty)
            _buildEmptyCard('No Special Events Scheduled Yet (e.g. Ramadan, Eid, Taraweeh)')
          else
            ..._specialSchedules.map((s) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF0F432B).withValues(alpha: 0.1),
                    child: const Icon(Icons.event, color: Color(0xFF0F432B)),
                  ),
                  title: Text(s['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Time: ${s['startTime']} • ${s['startDate']?.toString().split('T')[0] ?? ''}\n${s['notes'] ?? ''}'),
                  isThreeLine: s['notes'] != null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteSpecialSchedule(s['id']),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showSingleDayPrayerDialog() {
    final dateStr = DateTime.now().toIso8601String().split('T')[0];
    final fajrJCtrl = TextEditingController(text: _todayPrayerTimes?['fajrJamaah'] ?? '05:30');
    final dhuhrJCtrl = TextEditingController(text: _todayPrayerTimes?['dhuhrJamaah'] ?? '13:15');
    final asrJCtrl = TextEditingController(text: _todayPrayerTimes?['asrJamaah'] ?? '16:45');
    final maghribJCtrl = TextEditingController(text: _todayPrayerTimes?['maghribJamaah'] ?? '18:20');
    final ishaJCtrl = TextEditingController(text: _todayPrayerTimes?['ishaJamaah'] ?? '20:15');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Prayer Times: $dateStr'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: fajrJCtrl, decoration: const InputDecoration(labelText: 'Fajr Jamaah (HH:mm)')),
              TextField(controller: dhuhrJCtrl, decoration: const InputDecoration(labelText: 'Dhuhr Jamaah (HH:mm)')),
              TextField(controller: asrJCtrl, decoration: const InputDecoration(labelText: 'Asr Jamaah (HH:mm)')),
              TextField(controller: maghribJCtrl, decoration: const InputDecoration(labelText: 'Maghrib Jamaah (HH:mm)')),
              TextField(controller: ishaJCtrl, decoration: const InputDecoration(labelText: 'Isha Jamaah (HH:mm)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F432B), foregroundColor: Colors.white),
            onPressed: () async {
              if (_masjidId == null) return;
              Navigator.pop(ctx);
              try {
                await ApiService.instance.updatePrayerTimes(_masjidId!, {
                  'date': dateStr,
                  'fajrJamaah': fajrJCtrl.text.trim(),
                  'dhuhrJamaah': dhuhrJCtrl.text.trim(),
                  'asrJamaah': asrJCtrl.text.trim(),
                  'maghribJamaah': maghribJCtrl.text.trim(),
                  'ishaJamaah': ishaJCtrl.text.trim(),
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prayer times updated!')));
                _loadMasjidData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDateRangePrayerDialog() {
    final startCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final endCtrl = TextEditingController(text: DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0]);
    final fajrJCtrl = TextEditingController(text: '05:30');
    final dhuhrJCtrl = TextEditingController(text: '13:15');
    final asrJCtrl = TextEditingController(text: '16:45');
    final maghribJCtrl = TextEditingController(text: '18:20');
    final ishaJCtrl = TextEditingController(text: '20:15');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Prayer Times Across Date Range'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)')),
              TextField(controller: endCtrl, decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)')),
              const Divider(),
              TextField(controller: fajrJCtrl, decoration: const InputDecoration(labelText: 'Fajr Jamaah (HH:mm)')),
              TextField(controller: dhuhrJCtrl, decoration: const InputDecoration(labelText: 'Dhuhr Jamaah (HH:mm)')),
              TextField(controller: asrJCtrl, decoration: const InputDecoration(labelText: 'Asr Jamaah (HH:mm)')),
              TextField(controller: maghribJCtrl, decoration: const InputDecoration(labelText: 'Maghrib Jamaah (HH:mm)')),
              TextField(controller: ishaJCtrl, decoration: const InputDecoration(labelText: 'Isha Jamaah (HH:mm)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F432B), foregroundColor: Colors.white),
            onPressed: () async {
              if (_masjidId == null) return;
              Navigator.pop(ctx);
              try {
                await ApiService.instance.updatePrayerTimeRange(_masjidId!, {
                  'startDate': startCtrl.text.trim(),
                  'endDate': endCtrl.text.trim(),
                  'fajrJamaah': fajrJCtrl.text.trim(),
                  'dhuhrJamaah': dhuhrJCtrl.text.trim(),
                  'asrJamaah': asrJCtrl.text.trim(),
                  'maghribJamaah': maghribJCtrl.text.trim(),
                  'ishaJamaah': ishaJCtrl.text.trim(),
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Date range schedule applied!')));
                _loadMasjidData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Apply Range'),
          ),
        ],
      ),
    );
  }

  void _showAddSpecialEventDialog() {
    String selectedType = 'RAMZAN_TIMETABLE';
    final titleCtrl = TextEditingController();
    final titleTaCtrl = TextEditingController();
    final startCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final timeCtrl = TextEditingController(text: '20:45');
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Add Special Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Event Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: selectedType,
                  items: const [
                    DropdownMenuItem(value: 'RAMZAN_TIMETABLE', child: Text('Ramadan Timetable (நோன்பு அட்டவணை)')),
                    DropdownMenuItem(value: 'TARAWEEH', child: Text('Taraweeh (தராஹீஹ்)')),
                    DropdownMenuItem(value: 'EID_UL_FITR', child: Text('Eid-ul-Fitr (ஈகை பெருநாள் தொழுகை)')),
                    DropdownMenuItem(value: 'EID_UL_ADHA', child: Text('Eid-ul-Adha (பக்ரீத் பெருநாள் தொழுகை)')),
                    DropdownMenuItem(value: 'TAHAJJUD', child: Text('Tahajjud (தஹஜ்ஜுத்)')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Other Special Occasion')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDState(() => selectedType = v);
                  },
                ),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Event Title *')),
                TextField(controller: titleTaCtrl, decoration: const InputDecoration(labelText: 'Tamil Title')),
                TextField(controller: startCtrl, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD) *')),
                TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Time (HH:mm) *')),
                TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (e.g. 20 Rakah)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F432B), foregroundColor: Colors.white),
              onPressed: () async {
                if (titleCtrl.text.isEmpty || _masjidId == null) return;
                Navigator.pop(ctx);
                try {
                  await ApiService.instance.createSpecialSchedule(_masjidId!, {
                    'type': selectedType,
                    'title': titleCtrl.text.trim(),
                    'titleTa': titleTaCtrl.text.trim().isEmpty ? null : titleTaCtrl.text.trim(),
                    'startDate': startCtrl.text.trim(),
                    'startTime': timeCtrl.text.trim(),
                    'notes': notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Special Event created!')));
                  _loadMasjidData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              child: const Text('Add Event'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSpecialSchedule(String id) async {
    if (_masjidId == null) return;
    try {
      await ApiService.instance.deleteSpecialSchedule(_masjidId!, id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Event deleted!')));
      _loadMasjidData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  // -------------------------------------------------------------
  // TAB 3: Notice Board / Announcements (Send to Connected Musallis)
  // -------------------------------------------------------------
  Widget _buildAnnouncementsTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        title: const Text('Masjid Notice Board', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F432B),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F432B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert),
        label: const Text('New Notice'),
        onPressed: _showCreateNoticeDialog,
      ),
      body: _announcements.isEmpty
          ? _buildEmptyCard('No Announcements Published for this Masjid Yet')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _announcements.length,
              itemBuilder: (ctx, i) {
                final a = _announcements[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(a['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _deleteNotice(a['id']),
                            ),
                          ],
                        ),
                        if (a['titleTa'] != null) Text(a['titleTa'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text(a['body'] ?? ''),
                        if (a['bodyTa'] != null) ...[
                          const SizedBox(height: 4),
                          Text(a['bodyTa'], style: const TextStyle(color: Colors.black87, fontSize: 13)),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          'Sent to all connected musallis • ${a['publishedAt']?.toString().split('T')[0] ?? ''}',
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showCreateNoticeDialog() {
    final titleCtrl = TextEditingController();
    final titleTaCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final bodyTaCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Broadcast Notice to Musallis'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title (English) *')),
              TextField(controller: titleTaCtrl, decoration: const InputDecoration(labelText: 'Title (Tamil)')),
              TextField(controller: bodyCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Message Body *')),
              TextField(controller: bodyTaCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Message (Tamil)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F432B), foregroundColor: Colors.white),
            onPressed: () async {
              if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty || _masjidId == null) return;
              Navigator.pop(ctx);
              try {
                await ApiService.instance.createAnnouncement(_masjidId!, {
                  'category': 'GENERAL',
                  'title': titleCtrl.text.trim(),
                  'titleTa': titleTaCtrl.text.trim().isEmpty ? null : titleTaCtrl.text.trim(),
                  'body': bodyCtrl.text.trim(),
                  'bodyTa': bodyTaCtrl.text.trim().isEmpty ? null : bodyTaCtrl.text.trim(),
                  'notifyPush': true,
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice broadcasted to all followers!')));
                _loadMasjidData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Broadcast'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNotice(String id) async {
    if (_masjidId == null) return;
    try {
      await ApiService.instance.deleteAnnouncement(_masjidId!, id);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notice deleted!')));
      _loadMasjidData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  // -------------------------------------------------------------
  // TAB 4: Manage Members & Roles
  // -------------------------------------------------------------
  Widget _buildMembersTab() {
    final memberships = (_membersData?['memberships'] as List<dynamic>?) ?? [];
    final admins = (_membersData?['admins'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        title: const Text('Manage Members & Roles', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F432B),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F432B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Member'),
        onPressed: _showAddMemberDialog,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Roles & Committee Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Masjid Admins & Roles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton.icon(
                icon: const Icon(Icons.security, size: 16),
                label: const Text('Assign Role'),
                onPressed: _showAssignRoleDialog,
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (admins.isEmpty)
            _buildEmptyCard('No custom roles assigned yet.')
          else
            ...admins.map((adm) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF0F432B),
                    child: Icon(Icons.shield, color: Colors.white, size: 18),
                  ),
                  title: Text(adm['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(adm['phone'] ?? ''),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                    child: Text(adm['role'] ?? '', style: const TextStyle(color: Color(0xFF0F432B), fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),

          // Musallis / Members Section
          Text('Connected Members (${memberships.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (memberships.isEmpty)
            _buildEmptyCard('No members connected yet. Tap Add Member to enroll.')
          else
            ...memberships.map((m) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey.shade200,
                    child: const Icon(Icons.person, color: Colors.grey),
                  ),
                  title: Text(m['name'] ?? 'Member', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${m['phone'] ?? ''} ${m['address'] != null ? '• ${m['address']}' : ''}'),
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Member to Masjid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Mobile Number (+91...) *')),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Member Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F432B), foregroundColor: Colors.white),
            onPressed: () async {
              if (phoneCtrl.text.isEmpty || _masjidId == null) return;
              Navigator.pop(ctx);
              try {
                await ApiService.instance.addMasjidMember(_masjidId!, phone: phoneCtrl.text.trim(), name: nameCtrl.text.trim());
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member added!')));
                _loadMasjidData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAssignRoleDialog() {
    final phoneCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String selectedRole = 'FINANCE';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Assign Custom Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Mobile Number *')),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name *')),
              const SizedBox(height: 10),
              DropdownButton<String>(
                isExpanded: true,
                value: selectedRole,
                items: const [
                  DropdownMenuItem(value: 'ADMIN', child: Text('Admin (Mutawalli)')),
                  DropdownMenuItem(value: 'FINANCE', child: Text('Finance (Treasurer)')),
                  DropdownMenuItem(value: 'ANNOUNCEMENT', child: Text('Announcement Volunteer')),
                ],
                onChanged: (v) {
                  if (v != null) setDState(() => selectedRole = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F432B), foregroundColor: Colors.white),
              onPressed: () async {
                if (phoneCtrl.text.isEmpty || nameCtrl.text.isEmpty || _masjidId == null) return;
                Navigator.pop(ctx);
                try {
                  await ApiService.instance.assignRole(
                    _masjidId!,
                    phone: phoneCtrl.text.trim(),
                    name: nameCtrl.text.trim(),
                    role: selectedRole,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role assigned!')));
                  _loadMasjidData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 5: Masjid Profile & Settings
  // -------------------------------------------------------------
  Widget _buildProfileTab() {
    final nameCtrl = TextEditingController(text: _masjidDetails?['name'] ?? '');
    final nameTaCtrl = TextEditingController(text: _masjidDetails?['nameTa'] ?? '');
    final cityCtrl = TextEditingController(text: _masjidDetails?['city'] ?? '');
    final addrCtrl = TextEditingController(text: _masjidDetails?['address'] ?? '');
    final latCtrl = TextEditingController(text: _masjidDetails?['latitude']?.toString() ?? '');
    final lngCtrl = TextEditingController(text: _masjidDetails?['longitude']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: _masjidDetails?['phone'] ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        title: const Text('Masjid Settings & Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F432B),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Masjid Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Masjid Name')),
                  TextField(controller: nameTaCtrl, decoration: const InputDecoration(labelText: 'Tamil Name')),
                  TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City')),
                  TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address')),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: latCtrl, decoration: const InputDecoration(labelText: 'Latitude'))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: lngCtrl, decoration: const InputDecoration(labelText: 'Longitude'))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F432B),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                    ),
                    onPressed: () async {
                      if (_masjidId == null) return;
                      try {
                        await ApiService.instance.updateMasjid(_masjidId!, {
                          'name': nameCtrl.text.trim(),
                          'nameTa': nameTaCtrl.text.trim().isEmpty ? null : nameTaCtrl.text.trim(),
                          'city': cityCtrl.text.trim(),
                          'address': addrCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                          'latitude': double.tryParse(latCtrl.text),
                          'longitude': double.tryParse(lngCtrl.text),
                        });
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masjid details updated!')));
                        _loadMasjidData();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                      }
                    },
                    child: const Text('Save Details'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Options
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: const Icon(Icons.home, color: Color(0xFF0F432B)),
            title: const Text('Switch to User App (Home)'),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              await ApiService.instance.clearSession();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const OtpLoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String msg) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboardTab(),
          _buildPrayerTimesTab(),
          _buildAnnouncementsTab(),
          _buildMembersTab(),
          _buildProfileTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0F432B),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Prayer & Events'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Notices'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Members'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
