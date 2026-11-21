import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_service.dart';
import '../../../prayer_times/data/prayer_times_provider.dart';

class AnnouncementsScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  final String? masjidId;

  const AnnouncementsScreen({super.key, this.onBack, this.masjidId});

  @override
  ConsumerState<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  List<dynamic> _notices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    setState(() => _isLoading = true);
    final targetId = widget.masjidId ?? ref.read(prayerTimesProvider).activeMasjid?['id'];

    if (targetId != null) {
      final list = await ApiService.instance.getAnnouncements(targetId);
      if (mounted) {
        setState(() {
          _notices = list;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _notices = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('அறிவிப்புகள் / Notices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchAnnouncements,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notices.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        const Text(
                          'அறிவிப்புகள் எதுவும் இல்லை',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No announcements posted by this masjid yet.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchAnnouncements,
                  child: ListView.builder(
                    padding: AppSpacing.screenPadding,
                    itemCount: _notices.length,
                    itemBuilder: (context, index) {
                      final item = _notices[index] as Map<String, dynamic>;
                      final isEmergency = item['isEmergency'] == true || item['type'] == 'EMERGENCY';
                      final title = (item['title'] ?? '').toString();
                      final body = (item['body'] ?? '').toString();
                      final createdAt = item['createdAt']?.toString() ?? '';
                      String displayTime = '';
                      if (createdAt.isNotEmpty) {
                        try {
                          final dt = DateTime.parse(createdAt).toLocal();
                          displayTime = '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
                        } catch (_) {
                          displayTime = createdAt;
                        }
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isEmergency ? AppColors.emergency : AppColors.outline,
                            width: isEmergency ? 1.5 : 0.8,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isEmergency ? Icons.warning_amber_rounded : Icons.campaign_outlined,
                                    color: isEmergency ? AppColors.emergency : AppColors.primary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isEmergency ? AppColors.emergency : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                body,
                                style: const TextStyle(fontSize: 15, height: 1.4, color: AppColors.textPrimary),
                              ),
                              if (displayTime.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      displayTime,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                    const Icon(Icons.check_circle_outline, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
