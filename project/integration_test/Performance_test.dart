import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// ==============================================================================
// PERFORMANCE TESTS
// Records frame render times to detect visual lag (jank) on complex screens.
//
// Run with:
// `flutter drive --driver=test_driver/integration_test.dart \
//               --target=integration_test/Performance_test.dart`
// ==============================================================================

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Performance: Generic Scroll Baseline', () {
    testWidgets('Baseline list scrolling performance (100 items)', (WidgetTester tester) async {
      await tester.pumpWidget(const _BaselineListShell(itemCount: 100));

      await binding.watchPerformance(() async {
        final listFinder = find.byType(ListView);
        await tester.fling(listFinder, const Offset(0, -800), 3000);
        await tester.pumpAndSettle();
        await tester.fling(listFinder, const Offset(0, 800), 3000);
        await tester.pumpAndSettle();
      }, reportKey: 'baseline_scroll_100_items');
    });
  });

  group('Performance: Passenger Summary List', () {
    testWidgets('Passenger card list renders 50 items without jank', (WidgetTester tester) async {
      await tester.pumpWidget(const _PassengerListShell(passengerCount: 50));

      await binding.watchPerformance(() async {
        final listFinder = find.byType(ListView);
        await tester.fling(listFinder, const Offset(0, -600), 2500);
        await tester.pumpAndSettle();
        await tester.fling(listFinder, const Offset(0, 600), 2500);
        await tester.pumpAndSettle();
      }, reportKey: 'passenger_list_50_items');
    });
  });

  group('Performance: Driver Dashboard Summary Cards', () {
    testWidgets('Dashboard summary card grid renders smoothly', (WidgetTester tester) async {
      await tester.pumpWidget(const _DashboardShell());

      await binding.watchPerformance(() async {
        final scrollable = find.byType(SingleChildScrollView);
        await tester.fling(scrollable, const Offset(0, -400), 2000);
        await tester.pumpAndSettle();
        await tester.fling(scrollable, const Offset(0, 400), 2000);
        await tester.pumpAndSettle();
      }, reportKey: 'dashboard_card_grid');
    });
  });
}

// ── Baseline generic list shell ──────────────────────────────────────────────
class _BaselineListShell extends StatelessWidget {
  final int itemCount;
  const _BaselineListShell({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: ListView.builder(
          itemCount: itemCount,
          itemBuilder: (_, i) => ListTile(
            leading: const CircleAvatar(child: Icon(Icons.directions_bus)),
            title: Text('Stop #$i'),
            subtitle: const Text('Rendering performance check...'),
          ),
        ),
      ),
    );
  }
}

// ── Realistic passenger card list shell ────────────────────────────────────
class _PassengerListShell extends StatelessWidget {
  final int passengerCount;
  const _PassengerListShell({required this.passengerCount});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("Today's Passengers")),
        body: ListView.builder(
          itemCount: passengerCount,
          itemBuilder: (_, i) => Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: i % 3 == 0 ? Colors.green : i % 3 == 1 ? Colors.red : Colors.grey,
                child: Text('${i + 1}', style: const TextStyle(color: Colors.white)),
              ),
              title: Text('Passenger ${i + 1}'),
              subtitle: Text(i % 3 == 0 ? '✅ Present' : i % 3 == 1 ? '❌ Absent' : '⏳ Not Voted'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Driver dashboard summary card shell ────────────────────────────────────
class _DashboardShell extends StatelessWidget {
  const _DashboardShell();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Driver Dashboard')),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSummaryCard('Passengers Today', '12', Colors.green),
                _buildSummaryCard('Absent', '3', Colors.red),
                _buildSummaryCard('Pending Vote', '5', Colors.orange),
                _buildSummaryCard('Missed Payments', '2', Colors.purple),
                ...List.generate(20, (i) => _buildSummaryCard('Extra Metric $i', '$i', Colors.blue)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(label),
        trailing: Text(
          value,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}
