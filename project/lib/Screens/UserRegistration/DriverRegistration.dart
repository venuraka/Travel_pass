import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/DriverModel.dart';
import '../Components/InputTexts.dart';
import '../Components/Whitecard.dart';
import '../Components/Header.dart';
import '../../services/Database.dart';
import 'VehicleRegistration.dart';
import '../Components/CustomSnackBar.dart';
import '../../services/NotificationService.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  // MVC: Controllers to capture user input
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleRegistration() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      CustomSnackBar.showError(
        context,
        "User not authenticated. Please sign in again.",
      );
      return;
    }

    String name = _nameController.text.trim();
    String plate = _plateController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();

    if (name.isEmpty) {
      CustomSnackBar.showError(context, "Name is required.");
      return;
    }

    // Name validation: Letters only
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(name)) {
      CustomSnackBar.showError(context, "Name must contain only letters.");
      return;
    }

    if (plate.isEmpty) {
      CustomSnackBar.showError(context, "Vehicle plate number is required.");
      return;
    }

    // Plate validation: Max 8 chars
    if (plate.length > 8) {
      CustomSnackBar.showError(
        context,
        "Vehicle plate must be 8 characters or less.",
      );
      return;
    }

    // Phone validation: 10-11 digits, optional leading +
    // User requested: "allow only 10 numbers if we add country code it can be 11 maximum but it only can be add + symble only"
    // Interpreted as: Optional +, followed by 10 to 11 digits.
    final phoneRegex = RegExp(r'^\+?[0-9]{10,11}$');
    if (!phoneRegex.hasMatch(phone)) {
      CustomSnackBar.showError(
        context,
        "Phone must be 10-11 digits (allows '+').",
      );
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      CustomSnackBar.showError(context, "Please enter a valid email address.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await PushNotificationService().getToken();
      
      final driver = DriverModel(
        uid: user.uid,
        name: _nameController.text.trim(),
        vehiclePlate: _plateController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        fcmToken: token,
      );

      await _dbService.saveDriverData(driver);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VehicleRegistrationScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, e.toString());
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
            title: 'Driver',
            subtitle: 'Registration',
            subtitleColor: Color(0xFF05A664),
          ),
          WhiteCard(
            topPadding: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InputTextField(
                  labelText: 'Name',
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 30),
                InputTextField(
                  labelText: 'Vehicle Number Plate',
                  controller: _plateController,
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 30),
                InputTextField(
                  labelText: 'Phone',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 30),
                InputTextField(
                  labelText: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF05A664),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
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
                              Icon(
                                Icons.arrow_forward,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
