import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:masjid_namaz_app/app.dart';

void main() {
  testWidgets('Masjid Namaz App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MasjidApp(),
      ),
    );
    expect(find.textContaining('தொழுகை'), findsWidgets);
  });
}
