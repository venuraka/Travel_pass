import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/DriverModel.dart';
import '../Components/InputTexts.dart';
import '../Components/Whitecard.dart';
import '../Components/Header.dart';
import '';
import '../Database.dart';
import 'VehicleRegistration.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({super.key});

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User not authenticated. Please sign in again.")),
      );
      return;
    }

    if (_nameController.text.isEmpty || _plateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final driver = DriverModel(
        uid: user.uid,
        name: _nameController.text.trim(),
        vehiclePlate: _plateController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
      );

      await _dbService.saveDriverData(driver);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VehicleRegistrationScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Register', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 20),
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