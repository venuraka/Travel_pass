import 'package:flutter/material.dart';

class InputTextField extends StatelessWidget {
  final String labelText;
  final TextInputType keyboardType;
  final bool showTrailingIcon;

  const InputTextField({
    super.key,
    required this.labelText,
    this.keyboardType = TextInputType.text,
    this.showTrailingIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(
          color: Color(0xFF121415),
          fontWeight: FontWeight.w500,
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide( color: Color(0xFF05A664), width: 1.0),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF05A664), width: 2.0),
        ),
        suffixIcon: showTrailingIcon
            ? Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.pinkAccent,
                width: 2,
              ),
            ),
          ),
        )
            : null,
      ),
    );
  }
}