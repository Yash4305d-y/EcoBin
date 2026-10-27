import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ecobin/app.dart';

void main() {
  testWidgets('EcoBin foundation app renders correctly with theme', (
    WidgetTester tester,
  ) async {
    // Build the EcoBinApp inside a ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: EcoBinApp()));

    // Verify app title and foundation header are rendered.
    expect(find.text('EcoBin'), findsOneWidget);
    expect(find.text('PHASE 1 READY'), findsOneWidget);
    expect(find.text('Project Foundation & Shell'), findsOneWidget);
  });
}
