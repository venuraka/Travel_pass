import 'package:flutter/material.dart';

class WhiteCard extends StatelessWidget {
  final Widget child; // This allows us to pass any content inside the card
  final double topPadding; // Top position in the Stack

  const WhiteCard({
    super.key,
    required this.child,
    this.topPadding = 250, // Default value if not provided
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      top: topPadding,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(50.0),
            topRight: Radius.circular(50.0),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40.0),
          child: child,
        ),
      ),
    );
  }
}