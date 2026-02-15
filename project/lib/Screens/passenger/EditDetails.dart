import 'package:flutter/material.dart';
import '../Components/InputTexts.dart';
import '../Components/Whitecard.dart';
import '../Components/Header.dart';
import 'Dashboard.dart';
import '../../controllers/PassengerEditDetailsController.dart';
import '../../models/PassengerModel.dart';

class EditDetailsScreen extends StatefulWidget {
  const EditDetailsScreen({super.key});

  @override
  State<EditDetailsScreen> createState() => _EditDetailsScreenState();
}

class _EditDetailsScreenState extends State<EditDetailsScreen> {
  final PassengerEditDetailsController _controller =
      PassengerEditDetailsController();
  final TextEditingController _phoneController = TextEditingController();

  // ignore: unused_field
  String? _selectedLocation;
  bool _isLoading = true;

  final List<String> pickupLocations = [
    'Colombo',
    'Gampaha',
    'Kandy',
    'Negombo',
    'Matara',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    PassengerModel? passenger = await _controller.loadPassengerDetails();
    if (mounted && passenger != null) {
      setState(() {
        _phoneController.text = passenger.phone;
        _selectedLocation = passenger.pickupLocation;
        // Ensure the selected location is in the list, or add it/handle it
        if (!pickupLocations.contains(_selectedLocation)) {
          if (_selectedLocation != null && _selectedLocation!.isNotEmpty) {
            pickupLocations.add(_selectedLocation!);
          } else {
            _selectedLocation = null;
          }
        }
        _isLoading = false;
      });
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load passenger details')),
        );
      }
    }
  }

  Future<void> _updateDetails() async {
    if (_phoneController.text.isEmpty || _selectedLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _controller.updateDetails(
      _phoneController.text,
      _selectedLocation!,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (result.containsKey('success')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Details updated successfully')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const PassengerDashboardApp(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Update failed')),
        );
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121415),
      body: Stack(
        children: [
          const RegistrationHeader(
            title: 'Edit',
            subtitle: 'Details',
            subtitleColor: Color(0xFF05A664),
            topPadding: 20,
          ),
          WhiteCard(
            topPadding: 400,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        InputTextField(
                          labelText: 'Phone Number',
                          keyboardType: TextInputType.phone,
                          controller: _phoneController,
                          // Note: InputTextField needs to support controller
                        ),
                        const SizedBox(height: 30),
                        // ===== Pickup Location Dropdown =====
                        Align(
                          alignment: Alignment.centerLeft,
                          child: const Text(
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
                              hint: const Text('Select Pickup Location'),
                              isExpanded: true,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF05A664),
                              ),
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Colors.black),
                              items: pickupLocations.map((location) {
                                return DropdownMenuItem<String>(
                                  value: location,
                                  child: Text(location),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedLocation = value;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),

                        // ===== Update Button =====
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _updateDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF05A664),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Update',
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
