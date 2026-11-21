import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/l10n/language_provider.dart';
import '../../../../core/network/api_service.dart';
import '../../../prayer_times/presentation/screens/home_screen.dart';

class ConnectMasjidScreen extends ConsumerStatefulWidget {
  const ConnectMasjidScreen({super.key});

  @override
  ConsumerState<ConnectMasjidScreen> createState() => _ConnectMasjidScreenState();
}

class _ConnectMasjidScreenState extends ConsumerState<ConnectMasjidScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  List<dynamic> _allMasjids = [];
  List<dynamic> _filteredMasjids = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  MobileScannerController? _scannerController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scannerController = MobileScannerController();
    _loadMasjids();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scannerController?.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadMasjids() async {
    setState(() => _isLoading = true);
    final masjids = await ApiService.instance.getMasjids();
    if (mounted) {
      setState(() {
        _allMasjids = masjids;
        _filteredMasjids = masjids;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() => _filteredMasjids = _allMasjids);
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _filteredMasjids = _allMasjids.where((m) {
        final name = (m['name'] ?? '').toString().toLowerCase();
        final nameTa = (m['nameTa'] ?? '').toString().toLowerCase();
        final city = (m['city'] ?? '').toString().toLowerCase();
        return name.contains(q) || nameTa.contains(q) || city.contains(q);
      }).toList();
    });
  }

  Future<void> _handleJoinMasjid(String masjidId, String masjidName) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      await ApiService.instance.joinMasjid(masjidId, isPrimary: true);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade800,
          content: Text('Connected to "$masjidName" successfully!'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade800,
            content: Text('Failed to connect: $e'),
          ),
        );
      }
    }
  }

  Future<void> _onQrDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final token = barcode.rawValue!.trim();
    setState(() => _isProcessing = true);

    try {
      final masjid = await ApiService.instance.getMasjidByQr(token);
      if (masjid != null && mounted) {
        await _handleJoinMasjid(masjid['id'], masjid['name'] ?? 'Masjid');
      } else if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.red,
            content: Text('Invalid or unrecognized Masjid QR code'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = ref.watch(languageProvider);
    final lang = ref.read(languageProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(lang.tr(en: 'Connect with Masjid', ta: 'பள்ளிவாசலுடன் இணையவும்')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            }
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.search),
              text: lang.tr(en: 'Search & Add', ta: 'தேடி இணைக்கவும்'),
            ),
            Tab(
              icon: const Icon(Icons.qr_code_scanner),
              text: lang.tr(en: 'Scan QR Code', ta: 'QR ஸ்கேன்'),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Search & Add
          _buildSearchAndAddTab(lang, isEn),

          // Tab 2: Scan QR Code
          _buildQrScannerTab(lang, isEn),
        ],
      ),
    );
  }

  Widget _buildSearchAndAddTab(LanguageNotifier lang, bool isEn) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Search Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              hintText: lang.tr(en: 'Search masjid by name or city...', ta: 'பள்ளிவாசல் பெயர் அல்லது ஊர் தேடுக...'),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),

        // Results List
        Expanded(
          child: _filteredMasjids.isEmpty
              ? Center(
                  child: Text(
                    lang.tr(en: 'No masjids found', ta: 'பள்ளிவாசல்கள் ஏதும் இல்லை'),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: AppSpacing.screenPadding,
                  itemCount: _filteredMasjids.length,
                  itemBuilder: (context, index) {
                    final masjid = _filteredMasjids[index];
                    final name = isEn
                        ? (masjid['name'] ?? 'Masjid')
                        : (masjid['nameTa'] ?? masjid['name'] ?? 'பள்ளிவாசல்');
                    final city = masjid['city'] ?? '';
                    final address = masjid['address'] ?? '';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.outline),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.mosque, color: AppColors.primary, size: 28),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '$city • $address',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                        trailing: ElevatedButton(
                          onPressed: _isProcessing
                              ? null
                              : () => _handleJoinMasjid(masjid['id'], name),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          child: Text(lang.tr(en: 'Join', ta: 'இணை')),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildQrScannerTab(LanguageNotifier lang, bool isEn) {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onQrDetected,
        ),
        // Overlay Instruction
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_scanner, color: AppColors.secondary, size: 36),
                const SizedBox(height: 8),
                Text(
                  lang.tr(
                    en: 'Point camera at Masjid QR Code to instantly connect',
                    ta: 'உடனடியாக இணைய பள்ளிவாசல் QR குறியீட்டை ஸ்கேன் செய்யவும்',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                if (_isProcessing) ...[
                  const SizedBox(height: 12),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: AppColors.secondary, strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
