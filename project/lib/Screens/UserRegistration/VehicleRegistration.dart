import 'package:flutter/material.dart';
import '../Components/InputTexts.dart';
import '../Components/Whitecard.dart';
import '../Components/Header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/Database.dart';
import '../Components/CustomSnackBar.dart';
import 'AddRoute.dart';

class VehicleRegistrationScreen extends StatefulWidget {
  const VehicleRegistrationScreen({super.key});

  @override
  State<VehicleRegistrationScreen> createState() =>
      _DriverRegistration2ScreenState();
}

class _DriverRegistration2ScreenState extends State<VehicleRegistrationScreen> {
  String? selectedVehicle;
  final List<String> vehicleTypes = ['Car', 'Mini Van', 'Mini Bus', 'Bus'];

  // Controllers
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _seatCountController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = false;

  @override
  void dispose() {
    _vehicleModelController.dispose();
    _seatCountController.dispose();
    super.dispose();
  }

  Future<void> _handleVehicleRegistration() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      CustomSnackBar.showError(context, "User not authenticated");
      return;
    }

    String model = _vehicleModelController.text.trim();
    String seatsText = _seatCountController.text.trim();

    if (model.isEmpty) {
      CustomSnackBar.showError(context, "Vehicle model is required.");
      return;
    }

    if (seatsText.isEmpty) {
      CustomSnackBar.showError(context, "Seat count is required.");
      return;
    }

    if (selectedVehicle == null) {
      CustomSnackBar.showError(context, "Please select a vehicle type.");
      return;
    }

    // Validate seat count is a number
    final int? seats = int.tryParse(seatsText);
    if (seats == null || seats <= 0 || seats > 100) {
      CustomSnackBar.showError(
        context,
        "Please enter a valid seat count (1-100).",
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _dbService.updateDriverVehicleDetails(
        uid: user.uid,
        vehicleModel: _vehicleModelController.text.trim(),
        seatCount: seats,
        vehicleType: selectedVehicle!,
      );

      if (mounted) {
        CustomSnackBar.showSuccess(
          context,
          "Vehicle details saved successfully",
        );
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddRouteScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, "Failed to save details: \$e");
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
            title: 'Vehicle',
            subtitle: 'Registration',
            subtitleColor: Color(0xFF05A664),
            topPadding: 100,
          ),

          WhiteCard(
            topPadding: 400,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                /// ✅ Vehicle Model Field
                InputTextField(
                  labelText: 'Vehicle Model',
                  hintText: 'Yutong Bus',
                  keyboardType: TextInputType.text,
                  controller: _vehicleModelController,
                  showTrailingIcon: false,
                ),

                const SizedBox(height: 30),

                /// Seat Count Field
                InputTextField(
                  labelText: 'Seat Count',
                  keyboardType: TextInputType.number,
                  controller: _seatCountController,
                  showTrailingIcon: false,
                ),

                const SizedBox(height: 30),

                /// Vehicle Type Dropdown
                Container(
                  height: 55,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFF05A664),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedVehicle,
                      hint: const Text(
                        'Vehicle Type',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF05A664),
                      ),
                      isExpanded: true,
                      style: const TextStyle(color: Colors.black, fontSize: 16),
                      items: vehicleTypes.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedVehicle = value;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                /// Add Route Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleVehicleRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF05A664),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading)
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        else ...[
                          Text(
                            'Add Route',
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
