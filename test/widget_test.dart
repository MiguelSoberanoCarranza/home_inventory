// This is a basic Flutter widget test.
//
// Smoke test to verify the app loads correctly.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:home_inventory/main.dart';
import 'package:home_inventory/services/app_state.dart';

void main() {
  testWidgets('App loads and shows bottom navigation', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState()..init(),
        child: const HomeInventoryApp(),
      ),
    );

    // Allow async initialization to complete
    await tester.pumpAndSettle();

    // Verify bottom navigation items are present
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Inventario'), findsOneWidget);
    expect(find.text('Caduci.'), findsOneWidget);
    expect(find.text('Lista'), findsOneWidget);
  });
}