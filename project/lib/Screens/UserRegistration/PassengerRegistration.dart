import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Components/InputTexts.dart';
import '../Components/Whitecard.dart';
import '../Components/Header.dart';
import '../Components/CustomSnackBar.dart';
import '../../services/Database.dart';
import '../../models/PassengerModel.dart';
import '../passenger/Updates.dart';

class PassengerRegistrationScreen extends StatefulWidget {
  const PassengerRegistrationScreen({super.key});

  @override
  State<PassengerRegistrationScreen> createState() =>
      _PassengerRegistrationScreenState();
}

class _PassengerRegistrationScreenState
    extends State<PassengerRegistrationScreen> {
  // Use unique variable names to avoid shadowing or confusion
  String _paymentType = 'Daily Payment';
  String? _selectedLocation;
  List<String> _pickupLocations = [];
  bool _isLoading = false;
  String? _matchedDriverId;

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otherPhoneController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otherPhoneController.dispose();
    super.dispose();
  }

  /// Checks if the entered vehicle plate exists in the driver collection.
  /// If found, populates pickup locations.
  /// If not, shows an error.
  Future<void> _checkVehiclePlate() async {
    final plate = _plateController.text.trim();
    if (plate.isEmpty) {
      CustomSnackBar.showError(context, "Please enter a vehicle number plate");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final driverData = await _dbService.getDriverByPlate(plate);
      if (driverData != null) {
        _matchedDriverId = driverData['uid'];
        final route = driverData['route'] as List<dynamic>?;

        if (route != null && route.isNotEmpty) {
          setState(() {
            // Extract names of pickup points (and Start/End if allowed as pickups)
            // Filtering for 'pickup' role specifically, or all points?
            // Requirement says "pickup locations on pickup location dropdown"
            // Let's include all points that have a name.
            _pickupLocations = route
                .map((point) => point['name'] as String? ?? "Unknown Point")
                .toList();
            _selectedLocation = null; // Reset selection
          });
          if (mounted) {
            CustomSnackBar.showSuccess(
              context,
              "Vehicle found! Select a pickup location.",
            );
          }
        } else {
          if (mounted) {
            CustomSnackBar.showError(
              context,
              "Vehicle found, but no route defined.",
            );
          }
          setState(() {
            _pickupLocations = [];
            _matchedDriverId = null;
          });
        }
      } else {
        if (mounted) {
          CustomSnackBar.showError(
            context,
            "Vehicle matches not found for plate: $plate",
          );
        }
        setState(() {
          _pickupLocations = [];
          _matchedDriverId = null;
          _selectedLocation = null;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, "Error checking vehicle: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerPassenger() async {
    if (_nameController.text.isEmpty ||
        _plateController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      CustomSnackBar.showError(context, "Please fill in all required fields");
      return;
    }

    if (_matchedDriverId == null || _pickupLocations.isEmpty) {
      CustomSnackBar.showError(
        context,
        "Please verify vehicle number plate first",
      );
      return;
    }

    if (_selectedLocation == null) {
      CustomSnackBar.showError(context, "Please select a pickup location");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create Auth User (Anon or Email/Pass? Assuming current user or new auth)
      // Since this is "UserRegistration/PassengerRegistration", it might follow SignUp?
      // Or is the user already signed in?
      // Assuming user is already signed in via Previous screens (SignUp -> UserSelection -> Here)
      User? user = FirebaseAuth.instance.currentUser;

      // If no user is signed in, we might need to rely on the passed data to create one?
      // But typically registration happens AFTER auth.
      // Let's assume user is signed in.
      if (user == null) {
        throw Exception("User must be signed in to register profile");
      }

      final newPassenger = PassengerModel(
        uid: user.uid,
        name: _nameController.text.trim(),
        vehiclePlate: _plateController.text.trim(),
        driverId: _matchedDriverId!,
        address: _addressController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        otherPhone: _otherPhoneController.text.trim(),
        paymentType: _paymentType,
        pickupLocation: _selectedLocation!,
        role: 'passenger',
        createdAt: Timestamp.now(),
      );

      await _dbService.savePassengerData(newPassenger);

      if (mounted) {
        CustomSnackBar.showSuccess(context, "Registration successful!");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const UpdatesScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, "Registration failed: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121415),
      body: Stack(
        children: [
          const RegistrationHeader(
            title: 'passenger',
            subtitle: 'Registration',
            subtitleColor: Color(0xFF05A664),
            topPadding: 30,
          ),
          WhiteCard(
            topPadding: 250,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  InputTextField(
                    labelText: 'Name',
                    keyboardType: TextInputType.name,
                    controller: _nameController,
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: InputTextField(
                          labelText: 'Vehicle Number Plate',
                          keyboardType: TextInputType.text,
                          controller: _plateController,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _checkVehiclePlate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF05A664),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 15,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Check",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  InputTextField(
                    labelText: 'Address',
                    keyboardType: TextInputType.text,
                    controller: _addressController,
                  ),
                  const SizedBox(height: 30),
                  InputTextField(
                    labelText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                  ),
                  const SizedBox(height: 30),
                  InputTextField(
                    labelText: 'Phone Number',
                    keyboardType: TextInputType.phone,
                    controller: _phoneController,
                  ),
                  const SizedBox(height: 30),
                  InputTextField(
                    labelText: 'Other Phone Number',
                    keyboardType: TextInputType.phone,
                    controller: _otherPhoneController,
                  ),
                  const SizedBox(height: 30),

                  // ===== Payment Type Radio Buttons =====
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Payment Type',
                      style: TextStyle(
                        color: Color(0xFF121415),
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Daily'),
                          value: 'Daily Payment',
                          groupValue: _paymentType,
                          activeColor: const Color(0xFF05A664),
                          onChanged: (value) {
                            setState(() => _paymentType = value!);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Monthly'),
                          value: 'Monthly Payment',
                          groupValue: _paymentType,
                          activeColor: const Color(0xFF05A664),
                          onChanged: (value) {
                            setState(() => _paymentType = value!);
                          },
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ===== Pickup Location Dropdown =====
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Pickup Location',
                      style: TextStyle(
                        color: Color(0xFF121415),
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF05A664),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedLocation,
                        hint: Text(
                          _pickupLocations.isEmpty
                              ? 'Enter Vehicle Number First'
                              : 'Select Pickup Location',
                          style: TextStyle(
                            color: _pickupLocations.isEmpty
                                ? Colors.grey
                                : Colors.black,
                          ),
                        ),
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Color(0xFF05A664),
                        ),
                        dropdownColor: Colors.white,
                        style: const TextStyle(color: Colors.black),
                        items: _pickupLocations.map((location) {
                          return DropdownMenuItem<String>(
                            value: location,
                            child: Text(location),
                          );
                        }).toList(),
                        onChanged: _pickupLocations.isEmpty
                            ? null
                            : (value) {
                                setState(() {
                                  _selectedLocation = value;
                                });
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),

                  // ===== Register Button =====
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerPassenger,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF05A664),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 10),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
