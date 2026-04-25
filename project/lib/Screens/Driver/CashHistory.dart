import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/Database.dart';
import '../Components/Topic.dart';
import '../Components/AppBar.dart';

class CashHistoryScreen extends StatefulWidget {
  const CashHistoryScreen({super.key});

  @override
  State<CashHistoryScreen> createState() => _CashHistoryScreenState();
}

class _CashHistoryScreenState extends State<CashHistoryScreen> {
  final DatabaseService _dbService = DatabaseService();
  final String _driverId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Color appGreen = const Color(0xFF05A664);
  DateTime? _filterDate;

  // Track which date rows are expanded
  final Set<String> _expandedDates = {};

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _filterDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: appGreen,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _filterDate) {
      setState(() {
        _filterDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F5),
      appBar: const CustomAppBar(
        title: 'Cash History',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: PageHeader(
                title: "Daily Cash",
                subtitle: _filterDate == null
                    ? const Text("Showing all history",
                        style: TextStyle(fontSize: 12, color: Colors.grey))
                    : Text(
                        "Filtered: ${_filterDate!.toLocal()}".split(' ')[0],
                        style: TextStyle(
                            fontSize: 12,
                            color: appGreen,
                            fontWeight: FontWeight.bold),
                      ),
                actions: [
                  if (_filterDate != null)
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.grey),
                      onPressed: () => setState(() => _filterDate = null),
                    ),
                  IconButton(
                    icon: Icon(Icons.calendar_month, color: appGreen),
                    onPressed: () => _selectDate(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _dbService.getDailyCashHistoryStream(_driverId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var history = snapshot.data ?? [];

                  // Apply date filter
                  if (_filterDate != null) {
                    final filterStr =
                        "${_filterDate!.year}/${_filterDate!.month.toString().padLeft(2, '0')}/${_filterDate!.day.toString().padLeft(2, '0')}";
                    history =
                        history.where((item) => item['date'] == filterStr).toList();
                  }

                  if (history.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history,
                              size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          const Text("No cash history found",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];
                      final date = item['date'] as String? ?? 'Unknown';
                      final total = (item['total'] as double?) ?? 0.0;
                      final count = (item['count'] as int?) ?? 0;
                      final passengers =
                          (item['passengers'] as List<dynamic>?) ?? [];
                      final isExpanded = _expandedDates.contains(date);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // ─── Header Row (tappable) ───
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedDates.remove(date);
                                  } else {
                                    _expandedDates.add(date);
                                  }
                                });
                              },
                              borderRadius: isExpanded
                                  ? const BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      topRight: Radius.circular(16),
                                    )
                                  : BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Date icon
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: appGreen.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.payments_outlined,
                                          color: appGreen, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    // Date & count
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            date,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            "$count passenger${count == 1 ? '' : 's'} paid",
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Total amount
                                    Text(
                                      "Rs ${total.toInt()}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: appGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Expand chevron
                                    Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // ─── Expandable Passenger List ───
                            if (isExpanded) ...[
                              Divider(
                                  color: appGreen.withOpacity(0.2),
                                  height: 1,
                                  thickness: 1),
                              ...passengers.map((p) {
                                final name =
                                    (p as Map)['name'] as String? ?? 'Unknown';
                                final amount =
                                    (p['amount'] as double?) ?? 0.0;
                                final type =
                                    p['type'] as String? ?? 'Daily';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person_outline,
                                          color: Colors.grey, size: 18),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              type,
                                              style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "Rs ${amount.toInt()}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: appGreen,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 4),
                            ],
                          ],
                        ),
                      );
                    },
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
