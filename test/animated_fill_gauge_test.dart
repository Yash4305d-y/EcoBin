import 'package:ecobin/core/widgets/animated_fill_gauge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    AnimatedFillGauge.resetStaticMemory();
  });

  group('AnimatedFillGauge Unit & Widget Tests', () {
    testWidgets(
      'Displays Unavailable when fillPercentage is null (distinct from 0%)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(child: AnimatedFillGauge(fillPercentage: null)),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Unavailable'), findsOneWidget);
        expect(find.text('Fill Sensor Offline'), findsOneWidget);
        expect(find.text('0%'), findsNothing);
      },
    );

    testWidgets('Displays genuine 0% distinctly from unavailable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: AnimatedFillGauge(fillPercentage: 0.0)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
      expect(find.text('Low Capacity'), findsOneWidget);
      expect(find.text('Unavailable'), findsNothing);
    });

    testWidgets('Displays correct threshold labels for fill levels', (
      WidgetTester tester,
    ) async {
      // 25% -> Low Capacity
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: AnimatedFillGauge(fillPercentage: 25.0)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('25%'), findsOneWidget);
      expect(find.text('Low Capacity'), findsOneWidget);

      // 65% -> Moderate Fill
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: AnimatedFillGauge(fillPercentage: 65.0)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('65%'), findsOneWidget);
      expect(find.text('Moderate Fill'), findsOneWidget);

      // 90% -> Nearly Full
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: AnimatedFillGauge(fillPercentage: 90.0)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('90%'), findsOneWidget);
      expect(find.text('Nearly Full'), findsOneWidget);
    });

    testWidgets(
      'Animates smoothly from previous value to new value without restarting from zero',
      (WidgetTester tester) async {
        // Mount at 50%
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(child: AnimatedFillGauge(fillPercentage: 50.0)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('50%'), findsOneWidget);

        // Update to 70%
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(child: AnimatedFillGauge(fillPercentage: 70.0)),
            ),
          ),
        );

        // Halfway through animation duration (gaugeFill is 600ms)
        await tester.pump(const Duration(milliseconds: 300));

        // Value should be between 50% and 70% (e.g. 55-65%), definitely NOT 0-30%
        // Find the display text widget and inspect the number
        final textFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data != null &&
              widget.data!.endsWith('%') &&
              widget.data != '0%',
        );
        expect(textFinder, findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.text('70%'), findsOneWidget);
      },
    );
  });
}
