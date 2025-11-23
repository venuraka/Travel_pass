import 'package:flutter/material.dart';

class PageHeader extends StatelessWidget {
  final String title;                 // Main title (topic name)
  final List<Widget>? actions;        // Any number of buttons/icons
  final Widget? subtitle;             // Optional subtitle (date, description etc.)

  const PageHeader({
    super.key,
    required this.title,
    this.actions,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [

        // ---------- LEFT: Title + Subtitle ----------
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.black,
              ),
            ),

            if (subtitle != null) ...[
              const SizedBox(height: 3),
              subtitle!,
            ],
          ],
        ),

        // ---------- RIGHT: Icons / Buttons ----------
        if (actions != null && actions!.isNotEmpty)
          Row(
            children: actions!.map((icon) {
              return Container(
                margin: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: icon,
              );
            }).toList(),
          ),
      ],
    );
  }
}