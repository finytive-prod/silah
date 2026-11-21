import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:masjid_namaz_app/core/network/api_service.dart';
import 'package:masjid_namaz_app/features/prayer_times/data/prayer_times_provider.dart';
import 'package:masjid_namaz_app/features/qibla/presentation/screens/qibla_screen.dart';
import 'package:masjid_namaz_app/features/masjid/presentation/screens/connect_masjid_screen.dart';
import 'package:masjid_namaz_app/features/announcements/presentation/screens/announcements_screen.dart';
import 'package:masjid_namaz_app/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:masjid_namaz_app/features/admin/presentation/screens/super_admin_dashboard_screen.dart';
import 'package:masjid_namaz_app/features/auth/presentation/screens/otp_login_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedTabIndex = 0;
  List<dynamic> _masjids = [];
  List<dynamic> _announcements = [];
  String _calcMethod = 'Hanafi';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await ApiService.instance.getProfile();
    final masjids = await ApiService.instance.getMasjids();
    if (mounted) {
      setState(() => _masjids = masjids);
      if (masjids.isNotEmpty) {
        final activeId = masjids.first['id'];
        final notices = await ApiService.instance.getAnnouncements(activeId);
        if (mounted) {
          setState(() => _announcements = notices);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedTabIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _selectedTabIndex != 0) {
          setState(() => _selectedTabIndex = 0);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F9F7),
        drawer: _buildDrawer(),
        body: IndexedStack(
          index: _selectedTabIndex,
          children: [
            _buildHomeTab(),
            const ConnectMasjidScreen(),
            QiblaScreen(onBack: () => setState(() => _selectedTabIndex = 0)),
            AnnouncementsScreen(onBack: () => setState(() => _selectedTabIndex = 0)),
            _buildProfileTab(),
          ],
        ),
        bottomNavigationBar: _buildCustomBottomNav(),
      ),
    );
  }

  // Pixel-Perfect Custom Bottom Navigation Bar matching Figma
  Widget _buildCustomBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.mosque_outlined, Icons.mosque, 'Masjids'),
              _buildNavItem(2, Icons.explore_outlined, Icons.explore, 'Qibla'),
              _buildNavItem(3, Icons.chat_bubble_outline, Icons.chat_bubble, 'Notice'),
              _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEAF7EE) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? const Color(0xFF0F432B) : Colors.grey.shade500,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? const Color(0xFF0F432B) : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MAIN HOME VIEW: Reactive from Provider & Backend Only
  Widget _buildHomeTab() {
    final prayerState = ref.watch(prayerTimesProvider);

    if (prayerState.isLoading && prayerState.times == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9F7),
        appBar: _buildTopAppBar(),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF0F432B)),
              SizedBox(height: 16),
              Text(
                'Syncing times from Masjid server...',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    final times = prayerState.times;
    final activeMasjid = prayerState.activeMasjid;
    final nextPrayer = prayerState.nextPrayer;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F7),
      appBar: _buildTopAppBar(),
      body: RefreshIndicator(
        color: const Color(0xFF0F432B),
        onRefresh: () async {
          await ref.read(prayerTimesProvider.notifier).refreshFromBackend();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row: Prayer timings & Hanafi selector
              _buildPrayerTimingsHeader(),
              const SizedBox(height: 16),

              // Active Masjid Card
              _buildActiveMasjidCard(activeMasjid),
              const SizedBox(height: 16),

              // Hero "UP NEXT" Prayer Card
              if (nextPrayer != null) _buildHeroUpNextCard(nextPrayer),
              const SizedBox(height: 20),

              // Today's Timetable Table (strictly from backend / maintained state)
              _buildTodayTimetableCard(times, nextPrayer?.name),
              const SizedBox(height: 20),

              // Sun & Fasting Card
              _buildSunAndFastingCard(times),
              const SizedBox(height: 20),

              // Announcements Card
              _buildAnnouncementsCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Top App Bar
  PreferredSizeWidget _buildTopAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF7F9F7),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Builder(
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 0.8),
            ),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.black87, size: 20),
              padding: EdgeInsets.zero,
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
        ),
      ),
      centerTitle: true,
      title: Column(
        children: [
          Text(
            'Silah',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            'COMMUNITY ADHAN',
            style: TextStyle(
              fontSize: 9,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      actions: [
        // Live Sync Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF7EE),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFC7EAD1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.circle, color: Color(0xFF1E824C), size: 7),
              SizedBox(width: 5),
              Text(
                'Live Sync',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E824C),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Compass / Qibla Icon
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300, width: 0.8),
            ),
            child: IconButton(
              icon: const Icon(Icons.explore_outlined, color: Colors.black87, size: 19),
              padding: EdgeInsets.zero,
              onPressed: () => setState(() => _selectedTabIndex = 2),
            ),
          ),
        ),
      ],
    );
  }

  // 1. Prayer Timings Header & Date Row
  Widget _buildPrayerTimingsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prayer timings',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Saturday, 21 Nov 2026',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                    const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  ],
                ),
                const Text(
                  '10 Jumada al-Awwal 1448 AH',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1E824C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            // Hanafi Pill Selector
            InkWell(
              onTap: _showCalculationMethodDialog,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.tune, size: 14, color: Colors.black87),
                    const SizedBox(width: 5),
                    Text(
                      _calcMethod,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2. Active Masjid Card
  Widget _buildActiveMasjidCard(Map<String, dynamic>? activeMasjid) {
    final masjidName = activeMasjid?['name'] ?? 'Select Masjid';
    final masjidAddress = activeMasjid?['address'] ?? 'Tap to select an active masjid';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: const [
                Icon(Icons.mosque, size: 14, color: Color(0xFF1E824C)),
                SizedBox(width: 5),
                Text(
                  'ACTIVE MASJID',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Color(0xFF1E824C),
                  ),
                ),
              ],
            ),
            if (activeMasjid != null && activeMasjid['city'] != null)
              Row(
                children: [
                  const Icon(Icons.location_city, size: 12, color: Colors.grey),
                  const SizedBox(width: 3),
                  Text(
                    activeMasjid['city'] ?? '',
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _showMasjidSelector,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on, color: Color(0xFF0F432B), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              masjidName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (activeMasjid != null) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: activeMasjid['approvalStatus'] == 'APPROVED'
                                    ? const Color(0xFFE6F7EC)
                                    : const Color(0xFFFFF3CD),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                activeMasjid['approvalStatus'] == 'APPROVED' ? 'VERIFIED' : 'PENDING',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: activeMasjid['approvalStatus'] == 'APPROVED'
                                      ? const Color(0xFF167C43)
                                      : const Color(0xFF856404),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        masjidAddress,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.unfold_more, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 3. Hero "UP NEXT" Prayer Card
  Widget _buildHeroUpNextCard(NextPrayerInfo next) {
    final hours = next.timeUntilAdhan.inHours.toString().padLeft(2, '0');
    final minutes = (next.timeUntilAdhan.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (next.timeUntilAdhan.inSeconds % 60).toString().padLeft(2, '0');

    final iqamahHours = next.timeUntilIqamah.inHours;
    final iqamahMins = next.timeUntilIqamah.inMinutes % 60;
    final iqamahTimeStr = iqamahHours > 0 ? '${iqamahHours}h ${iqamahMins}m' : '${iqamahMins}m';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F432B), Color(0xFF0A3420)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F432B).withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, color: Color(0xFF4ECCA3), size: 7),
                    SizedBox(width: 5),
                    Text(
                      'UP NEXT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_empty, color: Color(0xFFFFD54F), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Iqamah in $iqamahTimeStr',
                      style: const TextStyle(
                        color: Color(0xFFFFD54F),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Prayer Name & Congregation Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                next.name,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF4ECCA3).withOpacity(0.5)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Congregation',
                  style: TextStyle(
                    color: Color(0xFF4ECCA3),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Dynamic Adhan & Iqamah from Backend
          Row(
            children: [
              Text(
                'ADHAN ',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600),
              ),
              Text(
                next.adhan,
                style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              Text('  ·  ', style: TextStyle(color: Colors.white.withOpacity(0.4))),
              Text(
                'IQAMAH ',
                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600),
              ),
              Text(
                next.iqamah,
                style: const TextStyle(fontSize: 13, color: Color(0xFF4ECCA3), fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Bottom Section: Ticking Countdown + Action Buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIME REMAINING TO ADHAN',
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.1,
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$hours : $minutes : $seconds',
                      style: GoogleFonts.spaceMono(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Row(
                      children: [
                        Text('HRS', style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600)),
                        const SizedBox(width: 24),
                        Text('MIN', style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600)),
                        const SizedBox(width: 24),
                        Text('SEC', style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.5), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening Google Maps directions to Masjid...')),
                      );
                    },
                    icon: const Icon(Icons.navigation_outlined, size: 14, color: Colors.white),
                    label: const Text('Map', style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Adhan alert reminder set!')),
                      );
                    },
                    icon: const Icon(Icons.notifications_active_outlined, size: 14, color: Colors.white),
                    label: const Text('Alert', style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 4. Today's Timetable Card - STRICTLY FROM BACKEND MAP
  Widget _buildTodayTimetableCard(Map<String, dynamic>? times, String? nextPrayerName) {
    if (times == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: const Center(child: Text('Loading timetable from Masjid database...')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's timetable",
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Auto-synced with masjid clock · $_calcMethod',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, color: Color(0xFF1E824C), size: 6),
                    SizedBox(width: 4),
                    Text(
                      'Official',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E824C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table Header
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'PRAYER',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 0.8),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'ADHAN / AZAAN',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 0.8),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'IQAMAH',
                  textAlign: TextAlign.end,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade600, letterSpacing: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 6),

          // Dynamic Prayer Rows from Backend
          _buildPrayerTableRow(
            icon: Icons.wb_twilight_outlined,
            name: 'Fajr',
            adhan: times['fajrAdhan'] ?? '--',
            iqamah: times['fajrJamaah'] ?? '--',
            isNext: nextPrayerName == 'Fajr',
          ),
          _buildPrayerTableRow(
            icon: Icons.wb_sunny_outlined,
            name: DateTime.now().weekday == DateTime.friday ? 'Jumu\'ah' : 'Dhuhr',
            adhan: times['dhuhrAdhan'] ?? '--',
            iqamah: times['dhuhrJamaah'] ?? '--',
            isNext: nextPrayerName == 'Dhuhr' || nextPrayerName == 'Jumu\'ah',
          ),
          _buildPrayerTableRow(
            icon: Icons.wb_sunny,
            name: 'Asr',
            adhan: times['asrAdhan'] ?? '--',
            iqamah: times['asrJamaah'] ?? '--',
            isNext: nextPrayerName == 'Asr',
          ),
          _buildPrayerTableRow(
            icon: Icons.wb_twilight,
            name: 'Maghrib',
            adhan: times['maghribAdhan'] ?? '--',
            iqamah: times['maghribJamaah'] ?? '--',
            isNext: nextPrayerName == 'Maghrib',
          ),
          _buildPrayerTableRow(
            icon: Icons.nightlight_round_outlined,
            name: 'Isha',
            adhan: times['ishaAdhan'] ?? '--',
            iqamah: times['ishaJamaah'] ?? '--',
            isNext: nextPrayerName == 'Isha',
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 11, color: Colors.black87),
                  children: [
                    const TextSpan(text: 'Jumu\'ah 1st Khutbah: ', style: TextStyle(color: Colors.grey)),
                    TextSpan(
                      text: times['jummahKhutbah'] ?? '12:45 PM',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Opening Full Month Calendar from Database...')),
                  );
                },
                child: Row(
                  children: const [
                    Text('Full Month', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F432B))),
                    Icon(Icons.chevron_right, size: 14, color: Color(0xFF0F432B)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerTableRow({
    required IconData icon,
    required String name,
    required String adhan,
    required String iqamah,
    required bool isNext,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isNext ? const Color(0xFFEBF6EE) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Icon(icon, size: 16, color: isNext ? const Color(0xFF0F432B) : Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                    color: isNext ? const Color(0xFF0F432B) : Colors.black87,
                  ),
                ),
                if (isNext) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F432B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'NEXT',
                      style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              adhan,
              style: TextStyle(
                fontSize: 13,
                color: isNext ? Colors.black87 : Colors.grey.shade700,
                fontWeight: isNext ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              iqamah,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isNext ? const Color(0xFF0F432B) : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. Sun & Fasting Card
  Widget _buildSunAndFastingCard(Map<String, dynamic>? times) {
    final sunrise = times?['sunrise'] ?? times?['fajrJamaah'] ?? '--:--';
    final ishraq = times?['ishraq'] ?? '--:--';
    final sunset = times?['sunset'] ?? times?['maghribAdhan'] ?? '--:--';
    final sehri = times?['sehri'] ?? times?['fajrAdhan'] ?? '--:--';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sun & Fasting',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Row(
                children: const [
                  Icon(Icons.schedule, size: 12, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('Local solar time', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBFBFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Sunrise\n(Shurooq)', style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.2)),
                          Icon(Icons.wb_sunny_outlined, color: Colors.amber, size: 18),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sunrise,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ishraq $ishraq',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBFBFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Sunset & Iftar\n ', style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.2)),
                          Icon(Icons.wb_twilight, color: Colors.orange, size: 18),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        sunset,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fast $sehri',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF1E824C), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Announcements Card
  Widget _buildAnnouncementsCard() {
    final hasNotices = _announcements.isNotEmpty;
    final latestNotice = hasNotices ? _announcements.first : null;
    final noticeTitle = hasNotices
        ? (latestNotice?['title'] ?? 'Notice')
        : 'No Announcements';
    final noticeBody = hasNotices
        ? (latestNotice?['body'] ?? '')
        : 'Your masjid has not published any announcements at this time.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Announcements',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  if (hasNotices) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7EE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_announcements.length} New',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E824C)),
                      ),
                    ),
                  ],
                ],
              ),
              InkWell(
                onTap: () => setState(() => _selectedTabIndex = 3),
                child: Row(
                  children: const [
                    Text('View all', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                    Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Inner Announcement Tile
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9C4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.campaign, color: Color(0xFFF57F17), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF7EE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'JUMU\'AH NOTICE',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF167C43)),
                            ),
                          ),
                          const Text('Today', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        noticeTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        noticeBody,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.3),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Masjid Admin', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                          Row(
                            children: const [
                              Text('Read parking instructions', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0F432B))),
                              Icon(Icons.chevron_right, size: 12, color: Color(0xFF0F432B)),
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
        ],
      ),
    );
  }

  // Profile Tab (Tab 4)
  Widget _buildProfileTab() {
    final user = ApiService.instance.currentUser;
    final userName = user?['name'] ?? 'User';
    final userPhone = user?['phone'] ?? '';
    final isMasjidAdmin = ApiService.instance.isMasjidAdmin;
    final isSuperAdmin = ApiService.instance.isSuperAdmin;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF0F432B),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFEAF7EE),
              child: Icon(Icons.person, size: 48, color: Color(0xFF0F432B)),
            ),
            const SizedBox(height: 12),
            Text(userName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(userPhone, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),

            // ROLE SWITCHER BUTTON
            if (isMasjidAdmin || isSuperAdmin) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F432B),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.admin_panel_settings, color: Colors.amber, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Administrative Mode',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You are an authorized administrator. Switch modes to update prayer schedules, publish notices, or manage roles.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => isSuperAdmin
                                ? const SuperAdminDashboardScreen()
                                : const AdminDashboardScreen(),
                          ),
                        ).then((_) => setState(() {}));
                      },
                      icon: const Icon(Icons.swap_horiz, color: Colors.black87),
                      label: Text(isSuperAdmin ? 'Open Super Admin Portal' : 'Switch to Masjid Admin Portal'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            ListTile(
              leading: const Icon(Icons.mosque),
              title: const Text('Change Active Masjid'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showMasjidSelector,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Asr Calculation Method'),
              subtitle: Text(_calcMethod),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showCalculationMethodDialog,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out / Switch Account', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await ApiService.instance.clearSession();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const OtpLoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Drawer (Menu from top-left button)
  Widget _buildDrawer() {
    final isMasjidAdmin = ApiService.instance.isMasjidAdmin;
    final isSuperAdmin = ApiService.instance.isSuperAdmin;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF0F432B)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Silah',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text('Community Adhan & Masjid Sync', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          if (isMasjidAdmin || isSuperAdmin) ...[
            ListTile(
              leading: const Icon(Icons.swap_horiz, color: Colors.amber),
              title: Text(
                isSuperAdmin ? 'Switch to Super Admin Portal' : 'Switch to Masjid Admin Portal',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => isSuperAdmin
                        ? const SuperAdminDashboardScreen()
                        : const AdminDashboardScreen(),
                  ),
                ).then((_) => setState(() {}));
              },
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.mosque),
            title: const Text('Select Masjid'),
            onTap: () {
              Navigator.pop(context);
              _showMasjidSelector();
            },
          ),
          ListTile(
            leading: const Icon(Icons.explore),
            title: const Text('Qibla Compass'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedTabIndex = 2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.campaign),
            title: const Text('Announcements'),
            onTap: () {
              Navigator.pop(context);
              setState(() => _selectedTabIndex = 3);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.account_circle),
            title: const Text('Login / Account'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OtpLoginScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCalculationMethodDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Asr Calculation Method'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() => _calcMethod = 'Hanafi');
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Icon(_calcMethod == 'Hanafi' ? Icons.check_circle : Icons.circle_outlined, color: const Color(0xFF0F432B)),
                const SizedBox(width: 10),
                const Text('Hanafi (Shadow length 2x)'),
              ],
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() => _calcMethod = 'Standard / Shafi');
              Navigator.pop(ctx);
            },
            child: Row(
              children: [
                Icon(_calcMethod != 'Hanafi' ? Icons.check_circle : Icons.circle_outlined, color: const Color(0xFF0F432B)),
                const SizedBox(width: 10),
                const Text('Standard / Shafi / Maliki (Shadow 1x)'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showMasjidSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final activeMasjid = ref.read(prayerTimesProvider).activeMasjid;

        return Container(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Masjid / பள்ளிவாசல்', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              if (_masjids.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('Loading active masjids from database...')),
                ),
              ..._masjids.map((m) {
                final isSelected = m['id'] == activeMasjid?['id'];
                return ListTile(
                  leading: const Icon(Icons.mosque, color: Color(0xFF0F432B)),
                  title: Text('${m['name']} (${m['city'] ?? ''})'),
                  subtitle: Text(m['address'] ?? ''),
                  trailing: isSelected ? const Icon(Icons.check, color: Color(0xFF0F432B)) : null,
                  onTap: () async {
                    Navigator.pop(ctx);
                    await ref.read(prayerTimesProvider.notifier).switchMasjid(m as Map<String, dynamic>);
                    final notices = await ApiService.instance.getAnnouncements(m['id']);
                    if (mounted) {
                      setState(() => _announcements = notices);
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
