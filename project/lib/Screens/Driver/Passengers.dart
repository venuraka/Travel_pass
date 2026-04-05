import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Components/Cards.dart';
import '../Components/CustomSnackBar.dart';
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

  Future<void> _deletePassenger(String uid) async {
    try {
      await FirebaseFirestore.instance.collection('passenger').doc(uid).delete();
      if (mounted) {
        CustomSnackBar.showSuccess(context, "Passenger deleted successfully.");
        _fetchPassengers(); // Refresh list automatically
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, "Failed to delete passenger: $e");
      }
    }
  }

  void _showDeleteDialog(PassengerModel passenger) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: const Text('Delete Passenger'),
          content: Text('Are you sure you want to delete ${passenger.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close dialog precisely
                _deletePassenger(passenger.uid); // Pass the uid to delete
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
                            trailing: PopupMenuButton<String>(
                              icon: Icon(Icons.more_vert, color: appGreen),
                              onSelected: (String value) async {
                                if (value == 'edit') {
                                  // Navigate to EditPassenger screen
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
                                } else if (value == 'delete') {
                                  _showDeleteDialog(passenger);
                                }
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                PopupMenuItem<String>(
                                  value: 'edit',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.edit, color: Colors.blue, size: 20),
                                      SizedBox(width: 10),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem<String>(
                                  value: 'delete',
                                  child: Row(
                                    children: const [
                                      Icon(Icons.delete, color: Colors.red, size: 20),
                                      SizedBox(width: 10),
                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
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
