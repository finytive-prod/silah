import 'package:flutter/material.dart';
import 'package:masjid_namaz_app/core/network/api_service.dart';
import 'package:masjid_namaz_app/features/prayer_times/presentation/screens/home_screen.dart';
import 'package:masjid_namaz_app/features/auth/presentation/screens/otp_login_screen.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;

  // Data states directly from backend
  Map<String, dynamic>? _stats;
  List<dynamic> _allMasjids = [];
  List<dynamic> _pendingRequests = [];
  List<dynamic> _users = [];
  List<dynamic> _broadcasts = [];
  String _userSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await ApiService.instance.getSuperAdminStats();
      final masjids = await ApiService.instance.getMasjids();
      final pending = await ApiService.instance.getPendingMasjidRequests();
      final usersRes = await ApiService.instance.getUsers(search: _userSearchQuery);

      if (mounted) {
        setState(() {
          _stats = stats;
          _allMasjids = masjids;
          _pendingRequests = pending;
          _users = usersRes?['items'] ?? [];
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // -------------------------------------------------------------
  // TAB 1: Masjids List & Create
  // -------------------------------------------------------------
  Widget _buildMasjidsTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        title: const Text('Masjid Directory', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F432B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllData),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F432B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Masjid'),
        onPressed: _showCreateMasjidDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allMasjids.isEmpty
              ? _buildEmptyState('No Approved Masjids in Database', Icons.mosque)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _allMasjids.length,
                  itemBuilder: (ctx, i) {
                    final m = _allMasjids[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF0F432B).withValues(alpha: 0.1),
                          child: const Icon(Icons.mosque, color: Color(0xFF0F432B)),
                        ),
                        title: Text(
                          m['name'] ?? 'Unnamed Masjid',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (m['nameTa'] != null)
                              Text(m['nameTa'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${m['city'] ?? ''}, ${m['address'] ?? ''}',
                                    style: const TextStyle(fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: const Text('ACTIVE', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showCreateMasjidDialog() {
    final nameCtrl = TextEditingController();
    final nameTaCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final latCtrl = TextEditingController();
    final lngCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Masjid (Super Admin)'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Masjid Name *')),
              TextField(controller: nameTaCtrl, decoration: const InputDecoration(labelText: 'Tamil Name (Optional)')),
              TextField(controller: cityCtrl, decoration: const InputDecoration(labelText: 'City *')),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address *')),
              TextField(controller: latCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Latitude')),
              TextField(controller: lngCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Longitude')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F432B), foregroundColor: Colors.white),
            onPressed: () async {
              if (nameCtrl.text.isEmpty || cityCtrl.text.isEmpty || addrCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill required fields')));
                return;
              }
              Navigator.pop(ctx);
              try {
                await ApiService.instance.createMasjid(
                  name: nameCtrl.text.trim(),
                  city: cityCtrl.text.trim(),
                  address: addrCtrl.text.trim(),
                  nameTa: nameTaCtrl.text.trim().isEmpty ? null : nameTaCtrl.text.trim(),
                  latitude: double.tryParse(latCtrl.text),
                  longitude: double.tryParse(lngCtrl.text),
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masjid created successfully!')));
                _loadAllData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: Pending Approval Requests
  // -------------------------------------------------------------
  Widget _buildRequestsTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        title: const Text('Masjid Approval Requests', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F432B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingRequests.isEmpty
              ? _buildEmptyState('No Pending Registration Requests', Icons.check_circle_outline)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingRequests.length,
                  itemBuilder: (ctx, i) {
                    final req = _pendingRequests[i];
                    final creator = req['creator'] ?? {};
                    return Card(
                      margin: const EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    req['name'] ?? 'Unnamed',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('PENDING', style: TextStyle(color: Colors.amber.shade900, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('City: ${req['city'] ?? ''} | Address: ${req['address'] ?? ''}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                            const Divider(height: 20),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('Applicant: ${creator['name'] ?? 'Unknown'} (${creator['phone'] ?? ''})', style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                  onPressed: () => _handleReject(req['id'], req['name'] ?? ''),
                                  child: const Text('Reject'),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F432B), foregroundColor: Colors.white),
                                  onPressed: () => _handleApprove(req['id'], req['name'] ?? ''),
                                  child: const Text('Accept & Approve'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _handleApprove(String id, String name) async {
    try {
      final res = await ApiService.instance.approveMasjidRequest(id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Approved!')));
      _loadAllData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _handleReject(String id, String name) async {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject: $name'),
        content: TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason (optional)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.instance.rejectMasjidRequest(id, reasonCtrl.text.trim());
              _loadAllData();
            },
            child: const Text('Confirm Reject'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 3: Global Announcements
  // -------------------------------------------------------------
  Widget _buildAnnouncementsTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        title: const Text('Broadcast Announcements', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F432B),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F432B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.campaign),
        label: const Text('New Broadcast'),
        onPressed: _showBroadcastDialog,
      ),
      body: _broadcasts.isEmpty
          ? _buildEmptyState('No Broadcast Messages Sent Yet', Icons.campaign_outlined)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _broadcasts.length,
              itemBuilder: (ctx, i) {
                final b = _broadcasts[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: const Icon(Icons.campaign, color: Color(0xFF0F432B)),
                    title: Text(b['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(b['body'] ?? ''),
                    trailing: Text(b['audience'] ?? 'ALL', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                  ),
                );
              },
            ),
    );
  }

  void _showBroadcastDialog() {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String targetAudience = 'All Users';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Send Broadcast Notice'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Target Audience:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: targetAudience,
                  items: const [
                    DropdownMenuItem(value: 'All Users', child: Text('All Users (System-wide)')),
                    DropdownMenuItem(value: 'Admins Only', child: Text('Masjid Admins Only')),
                    DropdownMenuItem(value: 'Musallis Only', child: Text('Musallis Only')),
                  ],
                  onChanged: (v) {
                    if (v != null) setDState(() => targetAudience = v);
                  },
                ),
                const SizedBox(height: 10),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title *')),
                const SizedBox(height: 10),
                TextField(controller: bodyCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Message Body *')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F432B), foregroundColor: Colors.white),
              onPressed: () {
                if (titleCtrl.text.isEmpty || bodyCtrl.text.isEmpty) return;
                setState(() {
                  _broadcasts.insert(0, {
                    'title': titleCtrl.text.trim(),
                    'body': bodyCtrl.text.trim(),
                    'audience': targetAudience,
                    'sentAt': DateTime.now().toIso8601String(),
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement broadcasted!')));
              },
              child: const Text('Send Broadcast'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 4: User Management
  // -------------------------------------------------------------
  Widget _buildUsersTab() {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        title: const Text('User Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F432B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllData),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F432B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
        onPressed: _showAddUserDialog,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search user by name or phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (val) {
                _userSearchQuery = val;
                ApiService.instance.getUsers(search: val).then((res) {
                  if (mounted && res != null) {
                    setState(() => _users = res['items'] ?? []);
                  }
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? _buildEmptyState('No Users Found in Database', Icons.people_outline)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _users.length,
                        itemBuilder: (ctx, i) {
                          final u = _users[i];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF0F432B).withValues(alpha: 0.1),
                                child: Text(
                                  (u['name'] ?? 'U').toString().substring(0, 1).toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F432B)),
                                ),
                              ),
                              title: Text(u['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${u['phone'] ?? ''} ${u['address'] != null ? '• ${u['address']}' : ''}'),
                              trailing: u['isSuperAdmin'] == true
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(6)),
                                      child: const Text('SUPER ADMIN', style: TextStyle(color: Colors.purple, fontSize: 10, fontWeight: FontWeight.bold)),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    bool isSuper = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Mobile Number (+91...) *')),
                TextField(controller: ageCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Age')),
                TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address')),
                CheckboxListTile(
                  title: const Text('Make Super Admin'),
                  value: isSuper,
                  onChanged: (v) => setDState(() => isSuper = v ?? false),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F432B), foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.isEmpty || phoneCtrl.text.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await ApiService.instance.createUser({
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'age': int.tryParse(ageCtrl.text),
                    'address': addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                    'isSuperAdmin': isSuper,
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User registered in database!')));
                  _loadAllData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                }
              },
              child: const Text('Add User'),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 5: Profile & System Stats
  // -------------------------------------------------------------
  Widget _buildProfileTab() {
    final metrics = _stats?['metrics'] ?? {};
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: AppBar(
        title: const Text('Super Admin Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0F432B),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: const Color(0xFF0F432B),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.security, size: 40, color: Color(0xFF0F432B)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Super Administrator', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    ApiService.instance.currentUser?['phone'] ?? '+911234567890',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // System Metrics
          const Text('System Live Metrics', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _metricCard('Total Masjids', '${metrics['totalMasjids'] ?? 0}', Icons.mosque)),
              const SizedBox(width: 10),
              Expanded(child: _metricCard('Total Users', '${metrics['totalUsers'] ?? 0}', Icons.people)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _metricCard('Followers', '${metrics['totalFollowers'] ?? 0}', Icons.favorite)),
              const SizedBox(width: 10),
              Expanded(child: _metricCard('Sandha Total', '₹${metrics['totalSandhaCollected'] ?? 0}', Icons.currency_rupee)),
            ],
          ),
          const SizedBox(height: 24),

          // Switch / Logout Options
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: const Icon(Icons.switch_account, color: Color(0xFF0F432B)),
            title: const Text('Switch to User App (Home)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
            onTap: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            tileColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _metricCard(String title, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0F432B)),
          const SizedBox(height: 8),
          Text(val, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(msg, textAlign: TextAlign.center, style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          ],
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
          _buildMasjidsTab(),
          _buildRequestsTab(),
          _buildAnnouncementsTab(),
          _buildUsersTab(),
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
          BottomNavigationBarItem(icon: Icon(Icons.mosque), label: 'Masjids'),
          BottomNavigationBarItem(icon: Icon(Icons.pending_actions), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Broadcast'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
