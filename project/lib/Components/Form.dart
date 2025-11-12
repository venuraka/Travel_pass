import 'package:flutter/material.dart';

class RegistrationFormContainer extends StatelessWidget {
  // We use a Widget list as the content to allow any widgets (fields, buttons, etc.)
  final List<Widget> children;
  final double topOffset; // How far down the container should start

  const RegistrationFormContainer({
    super.key,
    required this.children,
    this.topOffset = 250.0,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      top: topOffset, // Use the offset to start below the header
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(50.0),
            topRight: Radius.circular(50.0),
          ),
        ),
        child: SingleChildScrollView( // Keeps the content scrollable
          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children, // Inserts the form fields and buttons here
          ),
        ),
      ),
    );
  }
}