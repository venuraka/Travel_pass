import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Ensure you have this for date formatting
import '../Components/Topic.dart'; // Keeping your import

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final TextEditingController _textController = TextEditingController();
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
      "content": "Vestibulum quam purus, scelerisque vitae lorem et, congue ultrices purus.",
      "time": DateTime.now().subtract(const Duration(minutes: 15)),
    },
  ];

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      _announcements.add({
        "role": "admin",
        "label": "You",
        "content": _textController.text.trim(),
        "time": DateTime.now(), // Capture current time
      });
      _textController.clear();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: PageHeader(
                title: "Updates",
                subtitle: Text(
                  _dateString,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),

            // The List of Messages
            Expanded(
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _announcements.length,
                  itemBuilder: (context, index) {
                    final item = _announcements[index];
                    final bool isMe = item['role'] == 'admin';

                    // Format the time
                    final DateTime msgTime = item['time'] ?? DateTime.now();
                    final String timeString = DateFormat('MMM d, h:mm a').format(msgTime);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Column(
                        crossAxisAlignment: isMe
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.end,
                        children: [
                          // Label (Top)
                          if (item['label'] != "")
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 6.0, left: 4, right: 4),
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
                            padding: const EdgeInsets.only(top: 6.0, left: 4, right: 4),
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
                    );
                  },
                ),
              ),
            ),

            // The Input Area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: "Type an announcement...",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _handleSend,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Color(0xFF05A664),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
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
            bottomLeft: isMe ? Radius.zero : const Radius.circular(12),
            bottomRight: isMe ? const Radius.circular(12) : Radius.zero,
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, height: 1.4),
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

    if (isMe) {
      path.moveTo(0, size.height - 10);
      path.lineTo(-8, size.height);
      path.lineTo(10, size.height);
      path.close();
    } else {
      path.moveTo(size.width, size.height - 10);
      path.lineTo(size.width + 8, size.height);
      path.lineTo(size.width - 10, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}