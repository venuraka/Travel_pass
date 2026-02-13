import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Added
import '../Components/CustomSnackBar.dart';
import '../Driver/Dashboard.dart';
import '../../services/PlaceService.dart';
import '../../services/Database.dart'; // Added

class AddRouteScreen extends StatefulWidget {
  const AddRouteScreen({super.key});

  @override
  State<AddRouteScreen> createState() => _AddRouteScreenState();
}

class _AddRouteScreenState extends State<AddRouteScreen> {
  // Services
  final PlaceService _placeService = PlaceService(
    dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '', // Use env var
  );
  late GoogleMapController mapController;
  final Uuid _uuid = const Uuid();
  String _sessionToken = '1234567890'; // Initial session token

  // Map State
  final LatLng _center = const LatLng(6.9271, 79.8612); // Colombo
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  bool _isLoading = false;

  // Controllers & Focus Nodes
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _startNameController = TextEditingController();
  final FocusNode _startFocus = FocusNode();

  final TextEditingController _endController = TextEditingController();
  final TextEditingController _endNameController = TextEditingController();
  final FocusNode _endFocus = FocusNode();

  // Pickups are dynamic, so we'll use a list of objects or parallel lists
  // Using a list of Maps to keep track of controllers and focus nodes for pickups
  final List<Map<String, dynamic>> _pickupPoints = [];

  // Autocomplete State
  List<Map<String, dynamic>> _predictions = [];
  FocusNode? _activeSearchFocus; // Track which field is currently searching

  @override
  void initState() {
    super.initState();
    _startFocus.addListener(() => _onFocusChange(_startFocus));
    _endFocus.addListener(() => _onFocusChange(_endFocus));
    _sessionToken = _uuid.v4();
  }

  @override
  void dispose() {
    _startController.dispose();
    _startNameController.dispose();
    _startFocus.dispose();
    _endController.dispose();
    _endNameController.dispose();
    _endFocus.dispose();
    for (var point in _pickupPoints) {
      point['controller'].dispose();
      point['nameController'].dispose();
      point['focusNode'].dispose();
    }
    super.dispose();
  }

  void _onFocusChange(FocusNode node) {
    if (node.hasFocus) {
      setState(() {
        _activeSearchFocus = node;
        _predictions = []; // Clear previous predictions
      });
    } else {
      // Small delay to allow tap on suggestion before clearing
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_activeSearchFocus == node) {
          setState(() {
            _activeSearchFocus = null;
            _predictions = [];
          });
        }
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // --- Map Interaction ---
  Future<void> _handleMapTap(LatLng position) async {
    // 1. Identify active field
    TextEditingController? activeController;
    String markerId = "";
    BitmapDescriptor icon = BitmapDescriptor.defaultMarker;

    if (_startFocus.hasFocus) {
      activeController = _startController;
      markerId = "Start";
      icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    } else if (_endFocus.hasFocus) {
      activeController = _endController;
      markerId = "End";
      icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    } else {
      for (int i = 0; i < _pickupPoints.length; i++) {
        if (_pickupPoints[i]['focusNode'].hasFocus) {
          activeController = _pickupPoints[i]['controller'];
          markerId = "Pickup ${i + 1}";
          icon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          );
          break;
        }
      }
    }

    if (activeController != null) {
      setState(() => _isLoading = true);
      try {
        final address = await _placeService.getAddressFromLatLng(position);
        activeController.text = address;
        _addMarker(markerId, position, icon);
      } catch (e) {
        if (!mounted) return;
        CustomSnackBar.showError(context, "Failed to get address: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
    // Animate camera to the marker
    mapController.animateCamera(CameraUpdate.newLatLng(position));

    // Attempt to draw route if we have enough points
    _getRoute();
  }

  // --- Autocomplete Logic ---
  void _onSearchChanged(String query) {
    if (_activeSearchFocus == null) return;
    // Debounce can be added here if needed, but for now direct call
    _placeService
        .getPlaceSuggestions(query, _sessionToken)
        .then((results) {
          if (mounted) {
            setState(() {
              _predictions = results;
            });
          }
        })
        .catchError((error) {
          debugPrint("Autocomplete error: $error");
        });
  }

  Future<void> _selectSuggestion(Map<String, dynamic> prediction) async {
    final placeId = prediction['place_id'];
    final description = prediction['description'];

    setState(() {
      _isLoading = true;
      _predictions = []; // Close list
    });

    try {
      final details = await _placeService.getPlaceDetails(
        placeId,
        _sessionToken,
      );
      final lat = details['lat'];
      final lng = details['lng'];
      final position = LatLng(lat, lng);

      // Identify which controller to update
      if (_activeSearchFocus == _startFocus) {
        _startController.text = description;
        _addMarker(
          "Start",
          position,
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        );
      } else if (_activeSearchFocus == _endFocus) {
        _endController.text = description;
        _addMarker(
          "End",
          position,
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        );
      } else {
        for (int i = 0; i < _pickupPoints.length; i++) {
          if (_pickupPoints[i]['focusNode'] == _activeSearchFocus) {
            _pickupPoints[i]['controller'].text = description;
            _addMarker(
              "Pickup ${i + 1}",
              position,
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
            );
            break;
          }
        }
      }

      _sessionToken = _uuid.v4(); // Reset session token
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.showError(context, "Failed to get place details: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Current Location Logic ---
  Future<void> _useCurrentLocation(
    TextEditingController controller,
    String markerId,
    BitmapDescriptor icon,
  ) async {
    setState(() => _isLoading = true);
    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }

      Position position = await Geolocator.getCurrentPosition();
      final latLng = LatLng(position.latitude, position.longitude);

      final address = await _placeService.getAddressFromLatLng(latLng);
      controller.text = address;
      _addMarker(markerId, latLng, icon);
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.showError(context, "Location Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- Pickup Points Management ---
  void _addPickupPoint() {
    final controller = TextEditingController();
    final nameController = TextEditingController();
    final focusNode = FocusNode();
    focusNode.addListener(() => _onFocusChange(focusNode));

    setState(() {
      _pickupPoints.add({
        'controller': controller,
        'nameController': nameController,
        'focusNode': focusNode,
      });
    });
  }

  void _removePickupPoint(int index) {
    setState(() {
      _pickupPoints[index]['controller'].dispose();
      _pickupPoints[index]['nameController'].dispose();
      _pickupPoints[index]['focusNode'].dispose();
      _pickupPoints.removeAt(index);

      // Use coordinates from text controller if possible, otherwise rely on map markers
      // But since we don't store LatLng in controllers, we need to look up markers
      // or just re-fetch address...
      // A better way is to store the LatLng in the _pickupPoints map.
      // For now, let's just re-draw if we have markers for Start and End.
      _getRoute();

      // Update markers: Remove this one
      _markers.removeWhere((m) => m.markerId.value == "Pickup ${index + 1}");

      // Rename subsequent pickup markers to keep sequence correct?
      // Complex without a proper model. Let's just remove logic for now.
    });
  }

  Future<void> _getRoute() async {
    // Check if we have at least Start and End markers
    LatLng? startPos;
    LatLng? endPos;
    List<LatLng> waypoints = [];

    for (var marker in _markers) {
      if (marker.markerId.value == "Start") {
        startPos = marker.position;
      } else if (marker.markerId.value == "End") {
        endPos = marker.position;
      } else if (marker.markerId.value.startsWith("Pickup")) {
        waypoints.add(marker.position);
      }
    }

    if (startPos != null && endPos != null) {
      setState(() => _isLoading = true);
      try {
        final routePoints = await _placeService.getDirections(
          startPos,
          endPos,
          waypoints,
        );
        setState(() {
          _polylines.add(
            Polyline(
              polylineId: const PolylineId("route"),
              points: routePoints,
              color: const Color(0xFF121415),
              width: 5,
            ),
          );
        });

        // Fit bounds
        _fitBounds(routePoints);
      } catch (e) {
        if (!mounted) return;
        CustomSnackBar.showError(context, "Failed to get route: $e");
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Clear polylines if start or end is removed
      setState(() {
        _polylines.clear();
      });
    }
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        50, // padding
      ),
    );
  }

  Future<void> _saveRoute() async {
    // --- Validation Checks ---

    // 1. Check for basic Start/End existence (Pre-existing check)
    if (_startController.text.isEmpty || _endController.text.isEmpty) {
      CustomSnackBar.showError(context, "Start and End locations are required");
      return;
    }

    // 2. Check at least one pickup point exist
    if (_pickupPoints.isEmpty) {
      CustomSnackBar.showError(
        context,
        "At least one pickup point is required",
      );
      return;
    }

    // 3. Helper to find marker position by ID
    LatLng? getMarkerPos(String id) {
      for (var m in _markers) {
        if (m.markerId.value == id) return m.position;
      }
      return null;
    }

    // 4. Validate Start Point (Name, Address, LatLng)
    final startPos = getMarkerPos("Start");
    if (startPos == null) {
      CustomSnackBar.showError(
        context,
        "Please select a valid Start Location on the map",
      );
      return;
    }
    if (_startNameController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, "Please name the Start Location");
      return;
    }

    // 5. Validate End Point (Name, Address, LatLng)
    final endPos = getMarkerPos("End");
    if (endPos == null) {
      CustomSnackBar.showError(
        context,
        "Please select a valid End Location on the map",
      );
      return;
    }
    if (_endNameController.text.trim().isEmpty) {
      CustomSnackBar.showError(context, "Please name the End Location");
      return;
    }

    // 6. Validate Pickup Points (Name, Address, LatLng for EACH)
    for (int i = 0; i < _pickupPoints.length; i++) {
      final point = _pickupPoints[i];
      final id = "Pickup ${i + 1}";
      final pos = getMarkerPos(
        id,
      ); // Assuming marker IDs are consistent with index logic

      if (point['controller'].text.isEmpty) {
        CustomSnackBar.showError(context, "Address missing for $id");
        return;
      }
      if (point['nameController'].text.trim().isEmpty) {
        CustomSnackBar.showError(context, "Please name $id");
        return;
      }
      if (pos == null) {
        CustomSnackBar.showError(
          context,
          "Please select a valid location on map for $id",
        );
        return;
      }
    }

    // --- End Validation ---

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // Construct Route Data
      List<Map<String, dynamic>> routeData = [];

      // 1. Start Point
      routeData.add({
        'role': 'start',
        'address': _startController.text,
        'name': _startNameController.text,
        'lat': startPos.latitude,
        'lng': startPos.longitude,
      });

      // 2. Pickup Points
      for (int i = 0; i < _pickupPoints.length; i++) {
        final point = _pickupPoints[i];
        final id = "Pickup ${i + 1}";
        // Position is guaranteed valid by validation above
        final pickupPos = getMarkerPos(id)!;

        routeData.add({
          'role': 'pickup',
          'address': point['controller'].text,
          'name': point['nameController'].text,
          'lat': pickupPos.latitude,
          'lng': pickupPos.longitude,
        });
      }

      // 3. End Point
      routeData.add({
        'role': 'end',
        'address': _endController.text,
        'name': _endNameController.text,
        'lat': endPos.latitude,
        'lng': endPos.longitude,
      });

      // Save to Firestore
      final dbService = DatabaseService();
      await dbService.updateDriverRoute(user.uid, routeData);

      if (mounted) {
        CustomSnackBar.showSuccess(context, "Route saved successfully!");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const DriverDashboardScreen(),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, "Failed to save route: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(target: _center, zoom: 11.0),
            markers: _markers,
            polylines: _polylines,
            onTap: _handleMapTap,
            zoomControlsEnabled: false,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          // Loading Indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF05A664)),
            ),

          // UI Panel
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.2,
            maxChildSize: 0.85,
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
                    _buildLocationInputGroup(
                      label: "Start Location",
                      controller: _startController,
                      nameController: _startNameController,
                      focusNode: _startFocus,
                      icon: Icons.location_pin,
                      color: const Color(0xFF05A664),
                      markerId: "Start",
                    ),
                    const SizedBox(height: 15),

                    // Pickup Points
                    ...List.generate(_pickupPoints.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildLocationInputGroup(
                                label: "Pickup ${index + 1}",
                                controller: _pickupPoints[index]['controller'],
                                nameController:
                                    _pickupPoints[index]['nameController'],
                                focusNode: _pickupPoints[index]['focusNode'],
                                icon: Icons.location_on,
                                color: Colors.blue,
                                markerId: "Pickup ${index + 1}",
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

                    // Add Pickup Button
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
                    _buildLocationInputGroup(
                      label: "End Location",
                      controller: _endController,
                      nameController: _endNameController,
                      focusNode: _endFocus,
                      icon: Icons.flag,
                      color: Colors.redAccent,
                      markerId: "End",
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
                    // Space for keyboard
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
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

  Widget _buildLocationInputGroup({
    required String label,
    required TextEditingController controller,
    required TextEditingController nameController,
    required FocusNode focusNode,
    required IconData icon,
    required Color color,
    required String markerId,
  }) {
    return Column(
      children: [
        // Location Search Input
        TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: color),
            suffixIcon: IconButton(
              icon: const Icon(Icons.my_location, color: Colors.grey),
              onPressed: () => _useCurrentLocation(
                controller,
                markerId,
                BitmapDescriptor.defaultMarkerWithHue(
                  label == "Start Location"
                      ? BitmapDescriptor.hueGreen
                      : label == "End Location"
                      ? BitmapDescriptor.hueRed
                      : BitmapDescriptor.hueBlue,
                ),
              ),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: color, width: 2),
            ),
          ),
        ),

        // Autocomplete Predictions List (Visible only when focused)
        if (_activeSearchFocus == focusNode && _predictions.isNotEmpty)
          Container(
            height: 150,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  leading: const Icon(
                    Icons.place,
                    size: 20,
                    color: Colors.grey,
                  ),
                  title: Text(
                    prediction['description'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14),
                  ),
                  onTap: () => _selectSuggestion(prediction),
                );
              },
            ),
          ),

        const SizedBox(height: 8),

        // Custom Name Input
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: "Name the Location",
            prefixIcon: const Icon(Icons.edit, size: 18, color: Colors.grey),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
