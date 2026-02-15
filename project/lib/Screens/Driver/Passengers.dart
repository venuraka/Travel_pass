import 'package:flutter/material.dart';
import '../Components/Cards.dart';
import '../Components/Topic.dart';
import 'NewPassenger.dart';
import 'EditPassenger.dart'; // Import the EditPassenger screen
import '../../controllers/PassengerController.dart';
import '../../models/PassengerModel.dart';

class PassengerScreen extends StatefulWidget {
  const PassengerScreen({super.key});

  @override
  State<PassengerScreen> createState() => _PassengerScreenState();
}

class _PassengerScreenState extends State<PassengerScreen> {
  final Color appGreen = const Color(0xFF05A664);
  final PassengerController _controller = PassengerController();

  List<PassengerModel> _passengers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPassengers();
  }

  Future<void> _fetchPassengers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final passengers = await _controller.getRegisteredPassengers();
      if (mounted) {
        setState(() {
          _passengers = passengers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load passengers: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header using the PageHeader component ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: PageHeader(
                title: "Passenger Details",
                actions: [
                  IconButton(
                    icon: Icon(
                      Icons.person_add_alt_1,
                      color: appGreen,
                      size: 28,
                    ),
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewPassengerScreen(),
                        ),
                      );
                      // Refresh list when returning from new passenger screen
                      _fetchPassengers();
                    },
                  ),
                ],
              ),
            ),

            // --- Scrollable List of InfoCards ---
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: appGreen))
                  : _errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : _passengers.isEmpty
                  ? const Center(
                      child: Text(
                        "No registered passengers found.",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      // Add padding around the list itself
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _passengers.length,
                      itemBuilder: (context, index) {
                        final passenger = _passengers[index];
                        return Padding(
                          // Add space between cards
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InfoCard(
                            title: passenger.name,
                            subtitleWidget: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  passenger.pickupLocation,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFE8F5E9,
                                    ), // Light Green
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "Rs ${passenger.paymentAmount}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: appGreen,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            showTag: passenger.paymentType == 'Monthly',
                            tagText: 'Monthly',
                            trailing: IconButton(
                              icon: Icon(Icons.more_vert, color: appGreen),
                              onPressed: () async {
                                // Navigate to EditPassenger screen on tap
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => EditPassengerScreen(
                                      passenger: passenger,
                                    ),
                                  ),
                                );
                                if (result == true) {
                                  _fetchPassengers();
                                }
                              },
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
