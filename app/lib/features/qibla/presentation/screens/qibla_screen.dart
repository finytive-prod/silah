import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_compass_v2/flutter_compass_v2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masjid_namaz_app/core/constants/app_colors.dart';
import 'package:masjid_namaz_app/core/l10n/language_provider.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBack;
  const QiblaScreen({super.key, this.onBack});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  // Qibla direction from South India / Tamil Nadu is approx 294° (WNW)
  static const double targetQiblaAngle = 294.0;

  double? _heading = 0.0;
  StreamSubscription? _compassSub;
  bool _hasHapticFired = false;

  @override
  void initState() {
    super.initState();
    _startCompassListener();
  }

  void _startCompassListener() {
    try {
      _compassSub = FlutterCompass.events?.listen((CompassEvent event) {
        if (!mounted) return;
        final heading = event.heading;
        if (heading != null) {
          setState(() {
            _heading = heading;
          });

          // Check if facing Qibla within ±4 degrees
          final diff = (heading - targetQiblaAngle).abs();
          if (diff <= 4.0 || diff >= 356.0) {
            if (!_hasHapticFired) {
              HapticFeedback.mediumImpact();
              _hasHapticFired = true;
            }
          } else {
            _hasHapticFired = false;
          }
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.read(languageProvider.notifier);
    final heading = _heading ?? 0.0;

    // Angle to rotate Kaaba needle relative to device orientation
    // When heading == targetQiblaAngle, needle points directly UP (0 rad)
    final double needleAngle = (targetQiblaAngle - heading) * (math.pi / 180);
    final double diff = (heading - targetQiblaAngle).abs();
    final bool isFacingQibla = diff <= 4.0 || diff >= 356.0;

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
        title: Text(lang.tr(en: 'Qibla Direction', ta: 'கிப்லா திசை')),
        actions: [
          TextButton(
            onPressed: () => lang.toggleLanguage(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16)),
              child: Text(ref.watch(languageProvider) ? 'தமிழ்' : 'English',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              // Bearing info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isFacingQibla ? const Color(0xFFE8F5E9) : AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isFacingQibla ? AppColors.success : AppColors.primary,
                    width: isFacingQibla ? 2.0 : 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isFacingQibla ? Icons.check_circle : Icons.explore,
                      color: isFacingQibla ? AppColors.success : AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFacingQibla
                                ? lang.tr(en: 'Facing Qibla! (Makkah)', ta: 'கிப்லாவை நோக்கி உள்ளீர்கள்!')
                                : '294° WNW • ${lang.tr(en: 'Makkah Direction', ta: 'மக்கா திசை')}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isFacingQibla ? AppColors.success : AppColors.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Current Heading: ${heading.toStringAsFixed(0)}° • Makkah: ~4,320 km',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Live Rotating Analog Compass
              Center(
                child: SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Compass Dial (Rotates in reverse of phone heading)
                      Transform.rotate(
                        angle: -heading * (math.pi / 180),
                        child: Container(
                          width: 270,
                          height: 270,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: isFacingQibla ? AppColors.success : AppColors.primary,
                              width: 3.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isFacingQibla ? AppColors.success : Colors.black).withOpacity(0.12),
                                blurRadius: 18,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: Stack(
                            children: const [
                              Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text('N', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 17)),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: 8),
                                  child: Text('S', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: EdgeInsets.only(left: 8),
                                  child: Text('W', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Text('E', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 15)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Kaaba Target Needle (Points dynamically to Qibla)
                      Transform.rotate(
                        angle: needleAngle,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isFacingQibla ? AppColors.success : Colors.black87,
                                shape: BoxShape.circle,
                                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                              ),
                              child: const Icon(Icons.mosque, color: Colors.white, size: 26),
                            ),
                            Container(
                              width: 4.5,
                              height: 80,
                              decoration: BoxDecoration(
                                color: isFacingQibla ? AppColors.success : AppColors.secondary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),

                      // Center Pivot
                      CircleAvatar(
                        radius: 8,
                        backgroundColor: isFacingQibla ? AppColors.success : AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Live Calibration & Sensor Indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.screen_rotation, color: AppColors.primary, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        lang.tr(
                          en: 'Rotate phone until needle points UP. Phone vibrates when facing Makkah.',
                          ta: 'ஊசி மேல்நோக்கி நிற்கும் வரை சுழற்றவும். மக்காவை அடையும்போது அதிர்வு ஏற்படும்.',
                        ),
                        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
