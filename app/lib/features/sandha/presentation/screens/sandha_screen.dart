import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_service.dart';
import '../../../prayer_times/data/prayer_times_provider.dart';

class SandhaScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const SandhaScreen({super.key, this.onBack});

  @override
  ConsumerState<SandhaScreen> createState() => _SandhaScreenState();
}

class _SandhaScreenState extends ConsumerState<SandhaScreen> {
  bool _isLoading = true;
  List<dynamic> _enrollments = [];
  List<dynamic> _plans = [];

  @override
  void initState() {
    super.initState();
    _fetchSandhaData();
  }

  Future<void> _fetchSandhaData() async {
    setState(() => _isLoading = true);
    final masjid = ref.read(prayerTimesProvider).activeMasjid;
    final masjidId = masjid?['id'];

    if (masjidId != null) {
      final enrollments = await ApiService.instance.getUserSandhaStatus(masjidId);
      final plans = await ApiService.instance.getMasjidSandhaPlans(masjidId);
      if (mounted) {
        setState(() {
          _enrollments = enrollments;
          _plans = plans;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _enrollments = [];
          _plans = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMasjid = ref.watch(prayerTimesProvider).activeMasjid;
    final masjidName = activeMasjid?['name'] ?? 'Masjid';

    return Scaffold(
      appBar: AppBar(
        leading: (widget.onBack != null || Navigator.canPop(context))
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              )
            : null,
        title: const Text('சந்தா விவரம் / Sandha Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSandhaData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _enrollments.isEmpty && _plans.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.volunteer_activism_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'சந்தா திட்டம் எதுவும் இல்லை',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No Sandha contribution plans active for $masjidName yet.\nYour masjid administration will post monthly subscription details here.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchSandhaData,
                  child: SingleChildScrollView(
                    padding: AppSpacing.screenPadding,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Current Plan Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.outline),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'மாதாந்திர சந்தா',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _enrollments.isNotEmpty ? AppColors.primaryContainer : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      _enrollments.isNotEmpty ? 'இணைக்கப்பட்டது / Active' : 'பதிவு செய்யப்படவில்லை',
                                      style: TextStyle(
                                        color: _enrollments.isNotEmpty ? AppColors.primary : Colors.grey.shade700,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _enrollments.isNotEmpty
                                    ? '${_enrollments.first['plan']?['name'] ?? 'General Fund'} • ₹${_enrollments.first['plan']?['amount'] ?? _enrollments.first['plan']?['monthlyAmount'] ?? '0'} / Month'
                                    : '$masjidName Community Fund',
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                              const Divider(height: 24),
                              Text(
                                'பள்ளிவாசல் பராமரிப்பு மற்றும் நல நிதிக்கான உங்கள் மாதாந்திர பங்களிப்பு.',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Active Plans in Masjid
                        if (_plans.isNotEmpty) ...[
                          const Text(
                            'கிடைக்கும் திட்டங்கள் / Available Plans',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 10),
                          ..._plans.map((p) {
                            final planAmount = p['amount'] ?? p['monthlyAmount'] ?? '0';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: AppColors.primaryContainer,
                                  child: Icon(Icons.currency_rupee, color: AppColors.primary, size: 20),
                                ),
                                title: Text(p['name'] ?? 'Sandha Plan', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(p['description'] ?? 'Monthly contribution'),
                                trailing: Text(
                                  '₹$planAmount/mo',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }
}
