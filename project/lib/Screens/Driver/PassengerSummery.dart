import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Components/AppBar.dart';
import '../Components/Cards.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/Database.dart';
import '../../controllers/DriverAttendanceController.dart';
import '../../models/PassengerModel.dart';


class PassengersummeryScreen extends StatefulWidget {
  final DateTime selectedDay;
  const PassengersummeryScreen({
    super.key,
    required this.selectedDay,
  });

  @override
  State<PassengersummeryScreen> createState() => _PassengersummeryScreenState();
}

class _PassengersummeryScreenState extends State<PassengersummeryScreen> {
  final DatabaseService _dbService = DatabaseService();
  final DriverAttendanceController _attendanceController = DriverAttendanceController();
  
  String _badgePreference = "Both";
  bool _isLoading = true;
  List<PassengerModel> _boarded = [];
  List<PassengerModel> _absent = [];
  List<PassengerModel> _notVoted = [];
  bool _isPollActive = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 1. Load Badge Preference
      final driver = await _dbService.getDriverData(user.uid);
      if (driver != null) {
        _badgePreference = driver.badgePreference;
      }

      // 2. Load Attendance Data for the selected day
      final attendanceData = await _attendanceController.loadAttendanceData(widget.selectedDay);
      
      if (mounted) {
        setState(() {
          _boarded = List<PassengerModel>.from(attendanceData['boarded'] ?? []);
          _absent = List<PassengerModel>.from(attendanceData['absent'] ?? []);
          _notVoted = List<PassengerModel>.from(attendanceData['notVoted'] ?? []);
          _isPollActive = attendanceData['isPollActive'] ?? false;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Define the green color used throughout the app
    final Color appGreen = const Color(0xFF00C853);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Summary: ${DateFormat('MMM dd, yyyy').format(widget.selectedDay)}',
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C853)))
            : SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),

              // --- Date Display Section ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: appGreen.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: appGreen.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: appGreen, size: 28),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE').format(widget.selectedDay),
                            style: TextStyle(
                              fontSize: 14,
                              color: appGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            DateFormat('MMMM dd, yyyy').format(widget.selectedDay),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF121415),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 5),

              // --- Section 1: Confirmed Passengers ---
              if (_boarded.isNotEmpty) ...[
                _buildSectionHeader("Confirmed Passengers", appGreen),
                ..._boarded.map((p) => InfoCard(
                  title: p.name,
                  subtitle: p.pickupLocation,
                  showTag: true,
                  tagText: p.paymentType,
                  overallPreference: _badgePreference,
                  trailing: _buildPhoneIcon(appGreen, p.phone),
                )),
                const SizedBox(height: 10),
              ],

              // --- Section 2: Absent Passengers ---
              if (_absent.isNotEmpty) ...[
                _buildSectionHeader("Absent Passengers", Colors.redAccent),
                ..._absent.map((p) => InfoCard(
                  title: p.name,
                  subtitle: p.pickupLocation,
                  showTag: true,
                  tagText: p.paymentType,
                  overallPreference: _badgePreference,
                  trailing: _buildPhoneIcon(appGreen, p.phone),
                )),
                const SizedBox(height: 10),
              ],

              // --- Section 3: Not Voted ---
              if (_notVoted.isNotEmpty) ...[
                _buildSectionHeader("Not Voted", Colors.orangeAccent),
                ..._notVoted.map((p) => InfoCard(
                  title: p.name,
                  subtitle: p.pickupLocation,
                  showTag: true,
                  tagText: p.paymentType,
                  overallPreference: _badgePreference,
                  trailing: _buildPhoneIcon(appGreen, p.phone),
                )),
              ],

              if (_boarded.isEmpty && _absent.isEmpty && _notVoted.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Center(
                    child: Text(
                      _isPollActive 
                        ? "No passengers recorded for this day." 
                        : "No added poll on that day",
                      style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),

              const SizedBox(height: 30), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for the Green Section Titles
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
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

  // Helper widget for the Phone Icon
  Widget _buildPhoneIcon(Color color, String phoneNumber) {
    return InkWell(
      onTap: () => _makeCall(phoneNumber),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Icon(
          Icons.phone,
          color: color,
          size: 24,
        ),
      ),
    );
  }
}