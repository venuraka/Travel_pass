import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Components/AppBar.dart';
import '../Components/Cards.dart';
import '../Components/CustomSnackBar.dart';
import 'RegisterPassenger.dart';
import '../../services/Database.dart';
import '../../models/PassengerModel.dart';
import '../../utils/PhoneUtils.dart';

class NewPassengerScreen extends StatefulWidget {
  const NewPassengerScreen({super.key});

  @override
  State<NewPassengerScreen> createState() => _NewPassengerScreenState();
}

class _NewPassengerScreenState extends State<NewPassengerScreen> {
  final Color appGreen = const Color(0xFF05A664);
  final DatabaseService _dbService = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<PassengerModel> _unregisteredPassengers = [];
  bool _isLoading = false;

  List<String> _pickupLocations = []; // Store pickup locations

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // 1. Get driver details to get vehiclePlate
        final driver = await _dbService.getDriverData(user.uid);

        if (driver != null) {
          // Extract pickup locations from driver's route
          if (driver.route != null) {
            _pickupLocations = driver.route!
                .map(
                  (stop) =>
                      stop['name'] as String? ??
                      stop['address'] as String? ??
                      '',
                )
                .where((name) => name.isNotEmpty)
                .toList();
          }

          if (driver.vehiclePlate.isNotEmpty) {
            // 2. Fetch passengers with registered == false for this vehicle
            final passengers = await _dbService.getUnregisteredPassengers(
              driver.vehiclePlate,
            );
            setState(() {
              _unregisteredPassengers = passengers;
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching unregistered passengers: $e");
      if (mounted) {
        CustomSnackBar.showError(context, "Error loading passengers: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: 'New Passenger List'),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF05A664)),
            )
          : _unregisteredPassengers.isEmpty
          ? const Center(
              child: Text(
                'No new passengers found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : SafeArea(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                itemCount: _unregisteredPassengers.length,
                itemBuilder: (context, index) {
                  final passenger = _unregisteredPassengers[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: _buildPassengerRow(passenger),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildPassengerRow(PassengerModel passenger) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Phone icon
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: IconButton(
            onPressed: () {
              PhoneUtils.makeCall(context, passenger.phone);
            },
            icon: Icon(Icons.phone, color: appGreen),
            iconSize: 28,
          ),
        ),

        // Info card with passenger details
        Expanded(
          child: InfoCard(
            title: passenger.name,
            subtitle: passenger.pickupLocation,
            showTag: false,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Accept button
                IconButton(
                  visualDensity: VisualDensity.compact,
                  splashRadius: 20,
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegisterPassengerScreen(
                          passenger: passenger,
                          pickupLocations: _pickupLocations, // Pass locations
                        ),
                      ),
                    );

                    if (result == true) {
                      _fetchData(); // Refresh list if registration successful
                    }
                  },
                  icon: Icon(
                    Icons.check_circle_outline,
                    color: appGreen,
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 12),
                // Reject button
                IconButton(
                  visualDensity: VisualDensity.compact,
                  splashRadius: 20,
                  onPressed: () {
                    // TODO: Handle reject action
                  },
                  icon: const Icon(
                    Icons.highlight_off,
                    color: Colors.red,
                    size: 28,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
