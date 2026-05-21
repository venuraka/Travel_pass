import 'package:flutter/material.dart';
import '../Components/AppBar.dart';
import '../Components/Cards.dart';
import '../../controllers/TodayPassengersController.dart'; // Added
import '../../models/PassengerModel.dart'; // Added
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/Database.dart'; // Added

class TodaypassengersScreen extends StatefulWidget {
  const TodaypassengersScreen({super.key});

  @override
  State<TodaypassengersScreen> createState() => _TodaypassengersScreenState();
}

class _TodaypassengersScreenState extends State<TodaypassengersScreen> {
  final TodayPassengersController _controller =
      TodayPassengersController(); // Added

  List<PassengerModel> _boarded = [];
  List<PassengerModel> _absent = [];
  List<PassengerModel> _notVoted = [];
  bool _isLoading = true;
  bool _noPoll = false;
  String? _errorMessage;
  String _badgePreference = "Both";
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _noPoll = false;
    });

    final data = await _controller.loadTodayData();
    
    // Fetch Badge Preference
    String preference = "Both";
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final driver = await _dbService.getDriverData(user.uid);
      if (driver != null) {
        preference = driver.badgePreference;
      }
    }

    if (mounted) {
      if (data.containsKey('error')) {
        setState(() {
          _errorMessage = data['error'];
          _isLoading = false;
        });
      } else if (data.containsKey('noPoll') && data['noPoll'] == true) {
        setState(() {
          _noPoll = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _boarded = List<PassengerModel>.from(data['boarded']);
          _absent = List<PassengerModel>.from(data['absent']);
          _notVoted = List<PassengerModel>.from(data['notVoted']);
          _badgePreference = preference;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAttendance(PassengerModel passenger, String status) async {
    // Optimistic Update
    setState(() {
      if (status == 'Present') {
        _notVoted.remove(passenger);
        _boarded.insert(0, passenger); // Add to top
      } else if (status == 'Absent') {
        _notVoted.remove(passenger);
        _absent.insert(0, passenger);
      }
    });

    try {
      await _controller.markAttendance(passenger.uid, status);
    } catch (e) {
      // Revert if error (simple reload for now)
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error marking attendance: $e")));
      }
    }
  }

  Future<void> _makeCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) return;
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

  @override
  Widget build(BuildContext context) {
    final Color appGreen = const Color(0xFF05A664);
    final Color bgGreenTint = const Color(0xFFF1F8F5);

    return Scaffold(
      backgroundColor: bgGreenTint,
      appBar: const CustomAppBar(title: 'Today Passengers'),
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
            : _noPoll
            ? const Center(
                child: Text(
                  "No active poll for today.",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    children: [
                      // --- Section 1: Not Voted ---
                      if (_notVoted.isNotEmpty) ...[
                        _buildSectionHeader("Not Voted", appGreen),
                        for (var passenger in _notVoted)
                          Dismissible(
                            key: Key("notvoted_${passenger.uid}"),
                            direction: DismissDirection.horizontal,
                            onDismissed: (direction) {
                              if (direction == DismissDirection.startToEnd) {
                                _markAttendance(passenger, 'Present');
                              } else {
                                _markAttendance(passenger, 'Absent');
                              }
                            },
                            background: Container(
                              color: const Color(0xFF05A664),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                              ),
                            ),
                            secondaryBackground: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                            child: InfoCard(
                              title: passenger.name,
                              subtitle: passenger.pickupLocation,
                              showTag: true,
                              tagText: passenger.paymentType,
                              overallPreference: _badgePreference,
                              trailing: _buildPhoneIcon(
                                appGreen,
                                passenger.phone,
                              ),
                            ),
                          ),
                        const SizedBox(height: 30),
                      ],

                      // --- Section 2: Boarded (Present) ---
                      if (_boarded.isNotEmpty) ...[
                        _buildSectionHeader("Today's Passengers", appGreen),
                        for (var passenger in _boarded)
                          InfoCard(
                            title: passenger.name,
                            subtitle: passenger.pickupLocation,
                            showTag: true,
                            tagText: passenger.paymentType,
                            overallPreference: _badgePreference,
                            trailing: _buildPhoneIcon(
                              appGreen,
                              passenger.phone,
                            ),
                          ),
                        const SizedBox(height: 10),
                      ],

                      // --- Section 3: Absent ---
                      if (_absent.isNotEmpty) ...[
                        _buildSectionHeader("Absent Passengers", Colors.red),
                        for (var passenger in _absent)
                          InfoCard(
                            title: passenger.name,
                            subtitle: passenger.pickupLocation,
                            showTag: true,
                            tagText: passenger.paymentType,
                            overallPreference: _badgePreference,
                            trailing: _buildPhoneIcon(
                              appGreen,
                              passenger.phone,
                            ),
                          ),
                      ],

                      if (_notVoted.isEmpty &&
                          _boarded.isEmpty &&
                          _absent.isEmpty)
                        const Center(child: Text("No passengers found.")),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // Helper widget for section titles
  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Align(
        // Align left
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // Helper widget for the phone icon
  Widget _buildPhoneIcon(Color color, String phoneNumber) {
    if (phoneNumber.isEmpty) return const SizedBox.shrink();
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
