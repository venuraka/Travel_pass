import 'dart:async'; // Add import for Timer
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Components/InputTexts.dart';
import '../Components/Whitecard.dart';
import '../Components/Header.dart';
import '../Components/CustomSnackBar.dart';
import '../../services/Database.dart';
import '../../models/PassengerModel.dart';
import '../passenger/PendingApproval.dart';
import '../../services/NotificationService.dart';

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
  final FocusNode _plateFocusNode = FocusNode();
  final DatabaseService _dbService = DatabaseService();

  Timer? _debounce;
  bool _isChecking = false;
  String? _checkStatusMessage;
  Color _statusColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _prefillUserInfo();
  }

  Future<void> _prefillUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Force reload to ensure we get the latest displayName (especially for first-time Apple Sign-In)
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;
        if (updatedUser != null) {
          setState(() {
            _nameController.text = updatedUser.displayName ?? '';
            _emailController.text = updatedUser.email ?? '';
          });
        }
      } catch (e) {
        // Fallback to current data if reload fails
        _nameController.text = user.displayName ?? '';
        _emailController.text = user.email ?? '';
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.dispose();
    _plateController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _otherPhoneController.dispose();
    _plateFocusNode.dispose();
    super.dispose();
  }

  /// Real-time check for vehicle plate
  void _onPlateChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _checkVehiclePlate(value);
    });
  }

  /// Checks if the entered vehicle plate exists in the driver collection.
  /// If found, populates pickup locations.
  Future<void> _checkVehiclePlate(String plateInput) async {
    final plate = plateInput.trim();
    if (plate.isEmpty) {
      setState(() {
        _checkStatusMessage = null;
        _pickupLocations = [];
        _selectedLocation = null;
        _matchedDriverId = null;
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _checkStatusMessage = "Checking...";
      _statusColor = Colors.orange;
    });

    try {
      final driverData = await _dbService.getDriverByPlate(plate);

      if (driverData != null) {
        _matchedDriverId = driverData['uid'];
        // Store exact plate format
        _plateController.text = driverData['vehiclePlate'] ?? plate;
        final route = driverData['route'] as List<dynamic>?;

        if (route != null && route.isNotEmpty) {
          setState(() {
            // Filter: Exclude 'end' role, Include 'start' and 'pickup'
            _pickupLocations = route
                .where((point) => point['role'] != 'end')
                .map((point) => point['name'] as String? ?? "Unknown Point")
                .toList();
            _selectedLocation = null; // Reset selection
            _checkStatusMessage = "Vehicle Found";
            _statusColor = const Color(0xFF05A664);
          });
        } else {
          setState(() {
            _checkStatusMessage = "Vehicle found, no route.";
            _statusColor = Colors.red;
            _pickupLocations = [];
            _matchedDriverId = null;
          });
        }
      } else {
        setState(() {
          _checkStatusMessage = "Vehicle not found";
          _statusColor = Colors.red;
          _pickupLocations = [];
          _matchedDriverId = null;
          _selectedLocation = null;
        });
      }
    } catch (e) {
      setState(() {
        _checkStatusMessage = "Error checking";
        _statusColor = Colors.red;
      });
    } finally {
      if (mounted) setState(() => _isChecking = false);
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
        "Please enter a valid vehicle number plate",
      );
      return;
    }

    if (_selectedLocation == null) {
      CustomSnackBar.showError(context, "Please select a pickup location");
      return;
    }

    // Phone validation: 10-11 digits, optional leading +
    final phoneRegex = RegExp(r'^\+?[0-9]{10,11}$');
    String phone = _phoneController.text.trim();
    String otherPhone = _otherPhoneController.text.trim();

    if (!phoneRegex.hasMatch(phone)) {
      CustomSnackBar.showError(
        context,
        "Phone must be 10-11 digits (allows '+').",
      );
      return;
    }

    if (otherPhone.isNotEmpty && !phoneRegex.hasMatch(otherPhone)) {
      CustomSnackBar.showError(
        context,
        "Other Phone must be 10-11 digits (allows '+').",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create Auth User (Anon or Email/Pass? Assuming current user or new auth)
      // Since this is "UserRegistration/PassengerRegistration", it might follow SignUp?
      // Or is the user already signed in?
      // Assuming user is already signed in via Previous screens (SignUp -> UserSelection -> Here)
      User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("User must be signed in to register profile");
      }

      final token = await PushNotificationService().getToken();
      
      final newPassenger = PassengerModel(
        uid: user.uid,
        name: _nameController.text.trim(),
        vehiclePlate: _plateController.text.trim(), // Save exact string, DO NOT uppercase!
        driverId: _matchedDriverId!,
        address: _addressController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        otherPhone: _otherPhoneController.text.trim(),
        paymentType: _paymentType,
        pickupLocation: _selectedLocation!,
        role: 'passenger',
        createdAt: Timestamp.now(),
        fcmToken: token,
      );

      await _dbService.savePassengerData(newPassenger);

      // Notify Driver that a new passenger has registered
      try {
        await PushNotificationService().sendNotificationToDriver(
          driverId: _matchedDriverId!,
          title: 'New Student Registration',
          body: '${newPassenger.name} has registered for vehicle ${newPassenger.vehiclePlate}.',
          data: {
            'type': 'registration',
            'screen': 'new_passenger',
            'passengerId': newPassenger.uid,
            'vehiclePlate': newPassenger.vehiclePlate,
          },
        );
      } catch (e) {
        debugPrint('⚠️ Could not notify driver of registration: $e');
      }

      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          "Registration successful! Awaiting approval.",
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const PendingApprovalScreen(),
          ),
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
                  // Vehicle Plate Input with Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) async {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          return await _dbService.searchVehiclePlates(textEditingValue.text);
                        },
                        onSelected: (String selection) {
                          _plateController.text = selection;
                          _onPlateChanged(selection);
                          _plateFocusNode.unfocus();
                        },
                        fieldViewBuilder: (
                          BuildContext context,
                          TextEditingController textEditingController,
                          FocusNode focusNode,
                          VoidCallback onFieldSubmitted,
                        ) {
                          // Sync internal controller with _plateController so value is available on submit
                          textEditingController.addListener(() {
                            if (_plateController.text != textEditingController.text) {
                              _plateController.text = textEditingController.text;
                            }
                          });

                          return InputTextField(
                            labelText: 'Vehicle Number Plate',
                            keyboardType: TextInputType.text,
                            controller: textEditingController,
                            focusNode: focusNode,
                            onChanged: (val) {
                              _onPlateChanged(val);
                            },
                          );
                        },
                      ),
                      if (_checkStatusMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 5, left: 5),
                          child: Row(
                            children: [
                              if (_isChecking)
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                Icon(
                                  _statusColor == Colors.red
                                      ? Icons.error
                                      : Icons.check_circle,
                                  size: 16,
                                  color: _statusColor,
                                ),
                              const SizedBox(width: 5),
                              Text(
                                _checkStatusMessage!,
                                style: TextStyle(
                                  color: _statusColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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
                    height: 55.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerPassenger,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF05A664),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0.r),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2.w)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Register',
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 10.w),
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
