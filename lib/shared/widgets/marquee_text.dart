import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration animationDuration;
  final Duration backDuration;
  final Duration pauseDuration;
  final bool alwaysScroll;

  const MarqueeText({
    super.key,
    required this.text,
    this.style,
    this.animationDuration = const Duration(seconds: 8),
    this.backDuration = const Duration(seconds: 3),
    this.pauseDuration = const Duration(seconds: 2),
    this.alwaysScroll = true,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  @override
  void didUpdateWidget(MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0.0);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
    }
  }

  Future<void> _startScrolling() async {
    if (!mounted || !_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0 && !widget.alwaysScroll) return;

    while (mounted && _scrollController.hasClients) {
      await Future.delayed(widget.pauseDuration);
      if (!mounted || !_scrollController.hasClients) break;

      final currentMax = _scrollController.position.maxScrollExtent;
      if (currentMax <= 0) break;

      await _scrollController.animateTo(
        currentMax,
        duration: widget.animationDuration,
        curve: Curves.linear,
      );

      await Future.delayed(widget.pauseDuration);
      if (!mounted || !_scrollController.hasClients) break;

      await _scrollController.animateTo(
        0.0,
        duration: widget.backDuration,
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isGeneric = widget.text.trim() == 'Canlı Yayın' ||
        widget.text.trim() == 'Canlı Yayın Yükleniyor...' ||
        widget.text.trim().isEmpty;

    if (isGeneric) {
      return SizedBox(
        width: double.infinity,
        child: Text(
          widget.text,
          style: widget.style,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final displayText = widget.alwaysScroll
        ? '${widget.text}    🎵    ${widget.text}'
        : widget.text;

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        displayText,
        style: widget.style,
        maxLines: 1,
      ),
    );
  }
}
