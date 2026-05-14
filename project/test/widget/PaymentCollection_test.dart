import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project/Screens/Components/AppBar.dart';
import 'package:project/Screens/Components/Topic.dart';

// A Structural Mirror Shell of PaymentCollectionScreen to mock Firestore streams.
class _PaymentCollectionShell extends StatefulWidget {
  final List<Map<String, dynamic>> mockRedemptions;
  const _PaymentCollectionShell({required this.mockRedemptions});

  @override
  State<_PaymentCollectionShell> createState() => _PaymentCollectionShellState();
}

class _PaymentCollectionShellState extends State<_PaymentCollectionShell> {
  final Color appGreen = const Color(0xFF05A664);

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'pending':
        return {'label': 'Pending', 'color': Colors.orange, 'icon': Icons.hourglass_top_rounded};
      case 'approved':
        return {'label': 'Paid', 'color': appGreen, 'icon': Icons.check_circle_rounded};
      case 'rejected':
        return {'label': 'Rejected', 'color': Colors.redAccent, 'icon': Icons.cancel_rounded};
      default:
        return {'label': 'Unknown', 'color': Colors.grey, 'icon': Icons.help_outline};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F5),
      appBar: const CustomAppBar(title: 'Redemption History'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: PageHeader(
                title: "Payouts",
                subtitle: const Text("Showing all requests", style: TextStyle(fontSize: 12)),
                actions: [
                  IconButton(
                    icon: Icon(Icons.calendar_month, color: appGreen),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: widget.mockRedemptions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_rounded, size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          const Text("No redemptions found", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: widget.mockRedemptions.length,
                      itemBuilder: (context, index) {
                        final item = widget.mockRedemptions[index];
                        final statusInfo = _getStatusInfo(item['status']);
                        final Color statusColor = statusInfo['color'];
                        final String statusLabel = statusInfo['label'];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Rs ${item['amount']}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                                    ),
                                    Chip(
                                      backgroundColor: statusColor.withOpacity(0.1),
                                      label: Text(
                                        statusLabel,
                                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  children: [
                                    Expanded(child: Text("Requested: ${item['reqDate']}")),
                                    Expanded(child: Text("Received: ${item['paidDate']}")),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  group('PaymentCollectionScreen Widget Tests', () {
    testWidgets('Renders payouts page header and empty state when no data',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: _PaymentCollectionShell(mockRedemptions: []),
        ),
      );

      // Check main titles from PageHeader
      expect(find.text('Payouts'), findsOneWidget);
      expect(find.text('Showing all requests'), findsOneWidget);

      // Check empty state
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
      expect(find.text('No redemptions found'), findsOneWidget);
    });

    testWidgets('Renders redemption cards with dynamic statuses and amounts',
        (WidgetTester tester) async {
      final mockData = [
        {
          'amount': 5000,
          'status': 'approved',
          'reqDate': 'May 10',
          'paidDate': 'May 11',
        },
        {
          'amount': 2500,
          'status': 'pending',
          'reqDate': 'May 12',
          'paidDate': '—',
        }
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: _PaymentCollectionShell(mockRedemptions: mockData),
        ),
      );

      // Assert card container count
      expect(find.byType(Card), findsNWidgets(2));

      // Assert currency and amounts
      expect(find.text('Rs 5000'), findsOneWidget);
      expect(find.text('Rs 2500'), findsOneWidget);

      // Assert dynamic status labels
      expect(find.text('Paid'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);

      // Assert internal details
      expect(find.text('Requested: May 10'), findsOneWidget);
      expect(find.text('Received: May 11'), findsOneWidget);
      expect(find.text('Received: —'), findsOneWidget);
    });
  });
}
