import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Assuming Topic.dart contains PageHeader or similar components
// Keeping the import but replacing its usage with a custom Row for the back button

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final ScrollController _scrollController = ScrollController();

  String get _dateString {
    final now = DateTime.now();
    return DateFormat.yMMMd().format(now);
  }

  // Mutable list to simulate adding messages with Timestamps
  final List<Map<String, dynamic>> _announcements = [
    {
      "role": "admin",
      "label": "",
      "content": "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
      "time": DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      "role": "other",
      "label": "Passenger",
      "content": "Vestibulum quam purus, scelerisque vitae lorem et.",
      "time": DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
    },
    {
      "role": "admin",
      "label": "You",
      "content":
          "Vestibulum quam purus, scelerisque vitae lorem et, congue ultrices purus.",
      "time": DateTime.now().subtract(const Duration(minutes: 15)),
    },
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Using AppBar makes the back button and title standard and easier
      // We'll use the AppBar property of Scaffold and customize it
      appBar: AppBar(
        automaticallyImplyLeading: false, // Disable the default back button
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80, // Giving extra height for the custom look
        title: Row(
          children: [
            // 1. Go Back Arrow
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.black,
                size: 20,
              ),
              onPressed: () {
                Navigator.pop(context); // Navigates back
              },
            ),
            const SizedBox(width: 8),

            // 2. Header Content (Title and Subtitle)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Updates",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  _dateString,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        // Removed the previous Padding/PageHeader and replaced with AppBar
        child: Column(
          children: [
            // The List of Messages
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: _announcements.length,
                  itemBuilder: (context, index) {
                    final item = _announcements[index];
                    // IMPORTANT: Swapped logic for 'isMe' alignment.
                    // If 'role' is 'admin' (which is 'You' in your data), it should align to the RIGHT.
                    // If 'role' is 'other' ('Passenger'), it should align to the LEFT.
                    // I will stick to your original logic: isMe = 'admin' aligns to CrossAxisAlignment.start (left)
                    final bool isMe = item['role'] == 'admin';

                    // Format the time
                    final DateTime msgTime = item['time'] ?? DateTime.now();
                    final String timeString = DateFormat(
                      'h:mm a, MMM d',
                    ).format(msgTime);

                    return Align(
                      alignment: isMe
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.end,
                          children: [
                            // Label (Top)
                            if (item['label'] != "")
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: 6.0,
                                  left: isMe ? 4 : 0,
                                  right: isMe ? 0 : 4,
                                ),
                                child: Text(
                                  item['label'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                            // Bubble (Middle)
                            _AnnouncementBubble(
                              text: item['content'],
                              isMe: isMe,
                            ),

                            // Date & Time (Bottom)
                            Padding(
                              padding: EdgeInsets.only(
                                top: 6.0,
                                left: isMe ? 4 : 0,
                                right: isMe ? 0 : 4,
                              ),
                              child: Text(
                                timeString,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // *** The input/typing area is now completely absent from the Column's children. ***
          ],
        ),
      ),
    );
  }
}

// --- Helper Widgets ---

class _AnnouncementBubble extends StatelessWidget {
  final String text;
  final bool isMe;

  const _AnnouncementBubble({required this.text, required this.isMe});

  @override
  Widget build(BuildContext context) {
    // Wrapping in CustomPaint to draw the tail
    return CustomPaint(
      painter: _BubbleTailPainter(
        color: isMe ? const Color(0xFF05A664) : const Color(0xFF1A1A1A),
        isMe: isMe,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF05A664) : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            // Adjusted radii to match the tail location
            bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final bool isMe;

  _BubbleTailPainter({required this.color, required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    const double tailWidth = 8;
    const double tailHeight = 8;

    if (isMe) {
      // Admin/User (Green) bubble - tail on the bottom-left
      path.moveTo(0, size.height - tailHeight);
      path.lineTo(-tailWidth, size.height);
      path.lineTo(tailWidth, size.height);
      path.close();
    } else {
      // Other (Dark) bubble - tail on the bottom-right
      path.moveTo(size.width, size.height - tailHeight);
      path.lineTo(size.width + tailWidth, size.height);
      path.lineTo(size.width - tailWidth, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
