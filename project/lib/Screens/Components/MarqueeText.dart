import 'dart:async';
import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Axis scrollDirection;
  final Duration scrollDuration;
  final Duration pauseDuration;

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.scrollDirection = Axis.horizontal,
    this.scrollDuration = const Duration(seconds: 5),
    this.pauseDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late ScrollController _scrollController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  @override
  void didUpdateWidget(covariant MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _scrollController.jumpTo(0);
      _startScrolling();
    }
  }

  void _startScrolling() async {
    if (!_scrollController.hasClients) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    if (maxScrollExtent <= 0) return;

    // Wait for the pause duration before starting
    await Future.delayed(widget.pauseDuration);
    if (!mounted || !_scrollController.hasClients) return;

    // Animate to the end
    await _scrollController.animateTo(
      maxScrollExtent,
      duration: widget.scrollDuration,
      curve: Curves.linear,
    );

    if (!mounted || !_scrollController.hasClients) return;

    // Wait for the pause duration at the end
    await Future.delayed(widget.pauseDuration);
    if (!mounted || !_scrollController.hasClients) return;

    // Jump back to the start and repeat
    _scrollController.jumpTo(0);
    _startScrolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: widget.scrollDirection,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
      ),
    );
  }
}
