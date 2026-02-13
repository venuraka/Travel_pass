import 'package:flutter/material.dart';

class InputTextField extends StatelessWidget {
  final String labelText;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool showTrailingIcon;
  final String? hintText;

  const InputTextField({
    super.key,
    required this.labelText,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.showTrailingIcon = true,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,

        labelStyle: const TextStyle(
          color: Color(0xFF121415),
          fontWeight: FontWeight.w500,
        ),

        hintStyle: const TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),

        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFF05A664),
            width: 1.0,
          ),
        ),

        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Color(0xFF05A664),
            width: 2.0,
          ),
        ),
      ),
    );
  }
}