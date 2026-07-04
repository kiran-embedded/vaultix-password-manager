// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:vaultix_app/app.dart';

void main() {
  testWidgets('Vaultix app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VaultixApp()));
    expect(find.byType(VaultixApp), findsOneWidget);
  });
}
