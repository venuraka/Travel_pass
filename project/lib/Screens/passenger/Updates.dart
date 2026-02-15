import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/Database.dart';
import '../../models/UpdateModel.dart';
import '../../controllers/PassengerDashboardController.dart';

class UpdatesScreen extends StatefulWidget {
  final String? driverId;
  const UpdatesScreen({super.key, this.driverId});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _dbService = DatabaseService();
  final PassengerDashboardController _controller =
      PassengerDashboardController();

  Stream<List<UpdateModel>>? _updatesStream;

  String get _dateString {
    final now = DateTime.now();
    return DateFormat.yMMMd().format(now);
  }

  @override
  void initState() {
    super.initState();
    if (widget.driverId != null) {
      _updatesStream = _dbService.getUpdates(widget.driverId!);
    }
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    await _controller.markAlertsAsRead();
  }

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
                child: _updatesStream == null
                    ? const Center(child: Text("No driver assigned."))
                    : StreamBuilder<List<UpdateModel>>(
                        stream: _updatesStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF05A664),
                              ),
                            );
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          final updates = snapshot.data ?? [];

                          if (updates.isEmpty) {
                            return const Center(
                              child: Text(
                                "No updates yet.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 20,
                            ),
                            itemCount: updates.length,
                            itemBuilder: (context, index) {
                              final item = updates[index];
                              // Logic: 'admin' (driver) is the sender.
                              // If role == 'passenger', it is "me".
                              final bool isMe = item.role == 'passenger';

                              // Format the time
                              final String timeString = DateFormat(
                                'h:mm a, MMM d',
                              ).format(item.timestamp);

                              // Label logic
                              String label = item.label;
                              if (item.role == 'admin') {
                                label = "Driver";
                              }

                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 24.0),
                                  child: Column(
                                    crossAxisAlignment: isMe
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      // Label (Top)
                                      if (label.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            bottom: 6.0,
                                            left: isMe ? 0 : 4,
                                            right: isMe ? 4 : 0,
                                          ),
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),

                                      // Bubble (Middle)
                                      _AnnouncementBubble(
                                        text: item.content,
                                        isMe: isMe,
                                      ),

                                      // Date & Time (Bottom)
                                      Padding(
                                        padding: EdgeInsets.only(
                                          top: 6.0,
                                          left: isMe ? 0 : 4,
                                          right: isMe ? 4 : 0,
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
