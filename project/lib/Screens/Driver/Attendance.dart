import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../Components/Cards.dart';
import '../Components/Topic.dart';
import '../../controllers/DriverAttendanceController.dart';
import '../../models/PassengerModel.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final Color appGreen = const Color(0xFF05A664);
  final Color bgGreenTint = const Color(0xFFF1F8F5);
  final DriverAttendanceController _controller = DriverAttendanceController();

  DateTime? _selectedDate;
  bool _isLoading = true;
  String? _errorMessage;

  List<PassengerModel> _boarded = [];
  List<PassengerModel> _absent = [];
  List<PassengerModel> _notVoted = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final data = await _controller.loadAttendanceData(_selectedDate);

    if (mounted) {
      if (data.containsKey('error')) {
        setState(() {
          _errorMessage = data['error'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _selectedDate = data['targetDate'] as DateTime;
          _boarded = List<PassengerModel>.from(data['boarded']);
          _absent = List<PassengerModel>.from(data['absent']);
          _notVoted = List<PassengerModel>.from(data['notVoted']);
          _isLoading = false;
        });
      }
    }
  }

  // 2. Function to show the Date Picker
  Future<void> _selectDate(BuildContext context) async {
    // If we have available dates, we might want to restrict picking to those
    // or just let them pick any date.
    // For better UX given the requirement "nearest poll dates", let's use standard picker
    // but maybe highlight active dates if we could (standard picker doesn't easily support that).

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
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

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number not available.")),
      );
      return;
    }
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch dialer.")),
        );
      }
    }
  }

  // Helper to format date string
  String get _dateString => _selectedDate != null
      ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
      : 'Loading...';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGreenTint,
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: appGreen))
            : _errorMessage != null
            ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- HEADER ---
                    PageHeader(
                      title: "Attendance History",
                      subtitle: Text(
                        _dateString,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      actions: [
                        IconButton(
                          icon: Icon(
                            Icons.calendar_today_outlined,
                            color: appGreen,
                            size: 28,
                          ),
                          onPressed: () => _selectDate(context),
                        ),
                      ],
                    ),

                    // --------------
                    const SizedBox(height: 20),

                    // --- Section 1: Boarded (Present) ---
                    if (_boarded.isNotEmpty) ...[
                      _buildSectionHeader(
                        "Passengers Boarded on $_dateString",
                        appGreen,
                      ),
                      for (var p in _boarded)
                        InfoCard(
                          title: p.name,
                          subtitle: p.pickupLocation,
                          showTag: true,
                          tagText: p.paymentType,
                          trailing: _buildPhoneIcon(appGreen, p.phone),
                        ),
                      const SizedBox(height: 30),
                    ],

                    // --- Section 2: Absent ---
                    if (_absent.isNotEmpty) ...[
                      _buildSectionHeader(
                        "Absent Passengers on $_dateString",
                        Colors.red,
                      ),
                      for (var p in _absent)
                        InfoCard(
                          title: p.name,
                          subtitle: p.pickupLocation,
                          showTag: true,
                          tagText: p.paymentType,
                          trailing: _buildPhoneIcon(appGreen, p.phone),
                        ),
                      const SizedBox(height: 30),
                    ],

                    // --- Section 3: Not Voted (Pending) ---
                    if (_notVoted.isNotEmpty) ...[
                      _buildSectionHeader(
                        "Not Voted Passengers on $_dateString",
                        Colors.orange,
                      ),
                      for (var p in _notVoted)
                        InfoCard(
                          title: p.name,
                          subtitle: p.pickupLocation,
                          showTag: true,
                          tagText: p.paymentType,
                          trailing: _buildPhoneIcon(appGreen, p.phone),
                        ),
                      const SizedBox(height: 30),
                    ],

                    if (_boarded.isEmpty &&
                        _absent.isEmpty &&
                        _notVoted.isEmpty)
                      const Center(
                        child: Text("No passengers found for this date."),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPhoneIcon(Color color, String phoneNumber) {
    return InkWell(
      onTap: () => _makeCall(phoneNumber),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(Icons.phone, color: color, size: 24),
      ),
    );
  }
}
