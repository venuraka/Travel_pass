import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Components/CustomSnackBar.dart';
import '../Driver/Dashboard.dart';

class AddRouteScreen extends StatefulWidget {
  const AddRouteScreen({super.key});

  @override
  State<AddRouteScreen> createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  // Google Map Controller
  late GoogleMapController mapController;

  // Initial Location (Colombo, Sri Lanka as default)
  final LatLng _center = const LatLng(6.9271, 79.8612);

  // Markers
  final Set<Marker> _markers = {};

  // Controllers for Inputs
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _endController = TextEditingController();
  final List<TextEditingController> _pickupControllers = [];

  // Focus Nodes to track which field is active
  final FocusNode _startFocus = FocusNode();
  final FocusNode _endFocus = FocusNode();
  final List<FocusNode> _pickupFocusNodes = [];

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    for (var controller in _pickupControllers) {
      controller.dispose();
    }
    _startFocus.dispose();
    _endFocus.dispose();
    for (var node in _pickupFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _handleMapTap(LatLng position) {
    // Determine which field is currently focused to set the location
    if (_startFocus.hasFocus) {
      _startController.text = "${position.latitude}, ${position.longitude}";
      _addMarker(
        "Start",
        position,
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      );
      // Move focus to next if possible, or just keep it
    } else if (_endFocus.hasFocus) {
      _endController.text = "${position.latitude}, ${position.longitude}";
      _addMarker(
        "End",
        position,
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      );
    } else {
      // Check pickup points
      for (int i = 0; i < _pickupFocusNodes.length; i++) {
        if (_pickupFocusNodes[i].hasFocus) {
          _pickupControllers[i].text =
              "${position.latitude}, ${position.longitude}";
          _addMarker(
            "Pickup ${i + 1}",
            position,
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          );
          return;
        }
      }
    }
  }

  void _addMarker(String id, LatLng position, BitmapDescriptor icon) {
    setState(() {
      _markers.removeWhere((m) => m.markerId.value == id);
      _markers.add(
        Marker(
          markerId: MarkerId(id),
          position: position,
          infoWindow: InfoWindow(title: id),
          icon: icon,
        ),
      );
    });
  }

  void _addPickupPoint() {
    setState(() {
      _pickupControllers.add(TextEditingController());
      _pickupFocusNodes.add(FocusNode());
    });
  }

  void _removePickupPoint(int index) {
    setState(() {
      _pickupControllers[index].dispose();
      _pickupFocusNodes[index].dispose();
      _pickupControllers.removeAt(index);
      _pickupFocusNodes.removeAt(index);
      // Remove associated marker
      _markers.removeWhere((m) => m.markerId.value == "Pickup ${index + 1}");
      // Re-index remaining pickup markers? keeping it simple for now.
    });
  }

  void _saveRoute() {
    if (_startController.text.isEmpty || _endController.text.isEmpty) {
      CustomSnackBar.showError(context, "Start and End locations are required");
      return;
    }
    // Proceed to Dashboard
    CustomSnackBar.showSuccess(context, "Route saved successfully");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DriverDashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map Background
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center, zoom: 11.0),
            markers: _markers,
            onTap: _handleMapTap,
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          // Draggable Scrollable Sheet for Inputs
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.2,
            maxChildSize: 0.8,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Setup Route",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF121415),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Start Location
                    _buildTextField(
                      controller: _startController,
                      focusNode: _startFocus,
                      label: "Start Location",
                      icon: Icons.my_location,
                      color: const Color(0xFF05A664),
                    ),
                    const SizedBox(height: 15),

                    // Pickup Points
                    ...List.generate(_pickupControllers.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _pickupControllers[index],
                                focusNode: _pickupFocusNodes[index],
                                label: "Pickup Point ${index + 1}",
                                icon: Icons.location_on,
                                color: Colors.blue,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                              onPressed: () => _removePickupPoint(index),
                            ),
                          ],
                        ),
                      );
                    }),

                    // Add Pickup Point Button
                    TextButton.icon(
                      onPressed: _addPickupPoint,
                      icon: const Icon(Icons.add, color: Color(0xFF05A664)),
                      label: const Text(
                        "Add Pickup Point",
                        style: TextStyle(color: Color(0xFF05A664)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // End Location
                    _buildTextField(
                      controller: _endController,
                      focusNode: _endFocus,
                      label: "End Location",
                      icon: Icons.flag,
                      color: Colors.redAccent,
                    ),

                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveRoute,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF05A664),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Save Route",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Back Button
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: 2),
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.map),
          onPressed: () {
            // Request focus to enable map tap for this field
            focusNode.requestFocus();
            CustomSnackBar.showSuccess(context, "Tap on map to set location");
          },
        ),
      ),
      readOnly:
          true, // Make it read-only so users prefer map tapping, or allow typing if needed.
      // For now, let's keep it readOnly so they use the map or we need Geocoding to convert text to latlng.
      // Since we don't have python environment or complex geocoding set up easily without API,
      // let's rely on map tapping for coordinates.
    );
  }
}
