import 'package:flutter/material.dart';
import '../Components/Cards.dart';

// 1. Changed from StatelessWidget to StatefulWidget
class MoneyScreen extends StatefulWidget {
  const MoneyScreen({super.key});

  @override
  State<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends State<MoneyScreen> {
  final Color appGreen = const Color(0xFF00C853);

  // 2. Variable to store the selected date
  DateTime _selectedDate = DateTime.now();

  // 3. Function to open the Calendar
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate, // Opens with current selection
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      // Customize the calendar colors to match your appGreen
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: appGreen, // Header background color
              onPrimary: Colors.white, // Header text color
              onSurface: Colors.black, // Body text color
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        // TODO: Add logic here to filter your data based on 'picked' date
        print("Date Selected: $_selectedDate");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  children: [
                    // --- Header ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Payment details",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                            // Optional: Show the selected date below the title
                            Text(
                              "${_selectedDate.toLocal()}".split(' ')[0],
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),

                        // 4. Replaced static Icon with IconButton
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100, // Light background for button
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.calendar_today_outlined, color: appGreen, size: 28),
                            onPressed: () => _selectDate(context), // Calls the calendar
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // --- Late Payment Section ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Late Payment",
                        style: TextStyle(
                          color: appGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                    _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),
                    _buildLatePaymentRow(appGreen, "Vethum Ranasinghe", "Miriswatta"),

                    const SizedBox(height: 20),

                    // --- Paid Passengers Section ---
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Paid Passengers",
                        style: TextStyle(
                          color: appGreen,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    InfoCard(
                      title: "Vethum Ranasinghe",
                      subtitle: "Miriswatta",
                      showTag: true,
                      trailing: _buildPaidTrailing(appGreen, "Rs 1000", "2 Days Ago"),
                    ),

                    InfoCard(
                      title: "Vethum Ranasinghe",
                      subtitle: "Miriswatta",
                      showTag: false,
                      trailing: _buildPaidTrailing(appGreen, "Rs 1000", "2 Days Ago"),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Helper Methods ----------------
  // (These remain exactly the same as your original code)

  Widget _buildLatePaymentRow(Color color, String name, String location) {
    return Row(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1),
            color: Colors.white,
          ),
          child: Icon(Icons.notifications_none, color: color, size: 22),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        location,
                        style: const TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      Text(
                        "Rs 1000",
                        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        "2 weeks late",
                        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.phone, color: color),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaidTrailing(Color color, String price, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          price,
          style: TextStyle(color: color, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}