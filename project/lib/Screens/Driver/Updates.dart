import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Components/Topic.dart';
import '../../controllers/UpdatesController.dart';
import '../../models/UpdateModel.dart';

class UpdatesScreen extends StatefulWidget {
  const UpdatesScreen({super.key});

  @override
  State<UpdatesScreen> createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final UpdatesController _updatesController = UpdatesController();
  late Stream<List<UpdateModel>> _updatesStream;

  String get _dateString {
    final now = DateTime.now();
    return DateFormat.yMMMd().format(now);
  }

  @override
  void initState() {
    super.initState();
    _updatesStream = _updatesController.getUpdates();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    _textController.clear();
    await _updatesController.sendUpdate(content, context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0, // Scroll to top because list is reversed
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F5),
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
                color: Colors.transparent,
                child: StreamBuilder<List<UpdateModel>>(
                  stream: _updatesStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF05A664),
                        ),
                      );
                    }

                    final updates = snapshot.data!;
                    if (updates.isEmpty) {
                      return const Center(child: Text("No updates yet."));
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      itemCount: updates.length,
                      reverse:
                          true, // Show newest at the bottom naturally if we insert nicely,
                      // actually Firestore query is descending by timestamp (newest first).
                      // If we want chat-like specific behavior (bottom up), we might need reverse: true
                      // and the list order to match.
                      // Let's assume standard list for now, but usually for "updates" newest on top is fine,
                      // or newest at bottom like chat.
                      // Given the screenshot/mock had newest at bottom? No, typically feeds are top-down.
                      // But the Mock had current time at bottom. So it's chat-like.
                      // Let's do reverse: true and ensure data comes in Correct Order.
                      // Firestore: Newest First (Desc).
                      // Reverse ListView: Index 0 is bottom.
                      // So updates[0] (Newest) will be at bottom. YES.
                      itemBuilder: (context, index) {
                        final item = updates[index];
                        final bool isMe = item.role == 'admin';

                        final String timeString = DateFormat(
                          'MMM d, h:mm a',
                        ).format(item.timestamp);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment
                                      .end // Changed to End for "Me"
                                : CrossAxisAlignment.start,
                            children: [
                              // Label (Top)
                              if (item.label.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 6.0,
                                    left: 4,
                                    right: 4,
                                  ),
                                  child: Text(
                                    item.label,
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
                                padding: const EdgeInsets.only(
                                  top: 6.0,
                                  left: 4,
                                  right: 4,
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
                        );
                      },
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
                  ),
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
                          horizontal: 20,
                          vertical: 12,
                        ),
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
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
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

    if (isMe) {
      path.moveTo(size.width, size.height - 10);
      path.lineTo(size.width + 8, size.height);
      path.lineTo(size.width - 10, size.height);
      path.close();
    } else {
      path.moveTo(0, size.height - 10);
      path.lineTo(-8, size.height);
      path.lineTo(10, size.height);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
