import 'package:flutter/material.dart';
import 'DriverRegistration1.dart';


// You would use this in your main.dart or a dedicated screen file
class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[

              // 1. Header Section
              const SizedBox(height: 50),
              const Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF121415),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose How you want to continue',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF05A664),
                ),
              ),

              // Add spacing before the selection tiles
              const SizedBox(height: 50),

              // 2. Driver Selection Tile (using the new overlapping design)
              SelectionTile(
                icon: Icons.directions_bus,
                title: 'Driver',
                subtitle: 'Register As a Driver',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DriverRegistrationScreen()),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 3. Passenger Selection Tile (using the new overlapping design)
              SelectionTile(
                icon: Icons.person,
                title: 'Passenger',
                subtitle: 'Register As a Passenger',
                onTap: () {
                  print('Passenger selected');
                },
              ),

              // 4. Spacer to push the Terms to the bottom
              const Spacer(),

              // 5. Terms of Service Footer
              InkWell(
                onTap: () {
                  print('Terms of Service clicked');
                },
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 20.0),
                  child: Text(
                    'By continuing, you agree to our Terms of Service',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                        color: Color(0xFF05A664),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// FIX 2: Custom Widget for the Driver/Passenger selection tiles using Stack for overlap
class SelectionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SelectionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  // Constants for sizing the overlapping elements
  static const double iconCircleSize = 75.0; // Diameter of the black circle
  static const double cardHeight = 150.0;
  static const double totalTileHeight = cardHeight + (iconCircleSize / 2);

  @override
  Widget build(BuildContext context) {
    // Determine the width of the tile
    final double tileWidth = MediaQuery.of(context).size.width * 0.75;

    return InkWell(
      onTap: onTap,
      // Wrap the Stack in a SizedBox to define its boundaries for alignment
      child: SizedBox(
        width: tileWidth,
        height: totalTileHeight,

        child: Stack(
          // Allows the top half of the icon to draw outside the main container
          clipBehavior: Clip.none,
          // Center everything horizontally
          alignment: Alignment.topCenter,
          children: <Widget>[

            // 1. The Main Card (Rounded Box)
            Positioned(
              // Positioned down by half the icon size to create the overlap
              top: iconCircleSize / 2,
              left: 0,
              right: 0,
              child: Container(
                height: cardHeight,
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Color(0xFF05A664),
                    width: 1.5,
                  ),
                  color: Colors.white, // Explicit white background for the card
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF121415),
                      ),
                    ),
                    // Subtitle/Registration Text
                    const SizedBox(height: 12),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF05A664),
                      ),
                    ),
                    const SizedBox(height: 20), // Bottom padding
                  ],
                ),
              ),
            ),

            // 2. The Overlapping Icon Circle
            Positioned(
              top: 0, // Placed at the very top of the Stack
              child: Container(
                width: iconCircleSize,
                height: iconCircleSize,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF121415),
                ),
                child: Icon(
                  icon,
                  size: 50,
                  color: Color(0xFF05A664),// Icon color is green inside the black circle
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
