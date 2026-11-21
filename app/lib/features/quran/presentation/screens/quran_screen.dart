import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class QuranScreen extends StatelessWidget {
  final VoidCallback? onBack;
  const QuranScreen({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    final surahs = [
      {'number': 1, 'name': 'Al-Fatihah', 'nameAr': 'الفاتحة', 'meaning': 'தோற்றுவாய்', 'verses': 7},
      {'number': 2, 'name': 'Al-Baqarah', 'nameAr': 'البقرة', 'meaning': 'பசுக் கன்று', 'verses': 286},
      {'number': 3, 'name': 'Ali Imran', 'nameAr': 'آل عمران', 'meaning': 'இம்ரானின் குடும்பம்', 'verses': 200},
      {'number': 4, 'name': 'An-Nisa', 'nameAr': 'النساء', 'meaning': 'பெண்கள்', 'verses': 176},
      {'number': 36, 'name': 'Ya-Sin', 'nameAr': 'يس', 'meaning': 'யாஸீன்', 'verses': 83},
      {'number': 67, 'name': 'Al-Mulk', 'nameAr': 'الملك', 'meaning': 'ஆட்சி', 'verses': 30},
      {'number': 112, 'name': 'Al-Ikhlas', 'nameAr': 'الإخلاص', 'meaning': 'ஏகத்துவம்', 'verses': 4},
    ];

    return Scaffold(
      appBar: AppBar(
        leading: (onBack != null || Navigator.canPop(context))
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () {
                  if (onBack != null) {
                    onBack!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              )
            : null,
        title: const Text('திருக்குர்ஆன் / Holy Quran'),
      ),
      body: Column(
        children: [
          // Last Read Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF1B5E20)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'கடைசியாக ஓதியது (Last Read)',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ஸூரத்துல் பகரா (Al-Baqarah)',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'ஆயத் / Ayah: 255 (ஆயத்துல் குர்ஸி)',
                      style: TextStyle(color: AppColors.secondary, fontSize: 14),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(80, 40),
                  ),
                  child: const Text('தொடர்க / Resume'),
                ),
              ],
            ),
          ),

          // Surah List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: surahs.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final s = surahs[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  leading: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${s['number']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  title: Text(
                    '${s['name']} • ${s['meaning']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: Text('${s['verses']} வசனங்கள் (Verses)'),
                  trailing: Text(
                    s['nameAr'] as String,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  onTap: () {
                    // Open Surah reader
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
