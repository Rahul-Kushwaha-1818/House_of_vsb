import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimerWidget extends StatefulWidget {
  final DateTime targetTime;
  final bool isStartTime;
  final TextStyle? style;
  final VoidCallback? onFinished;

  const CountdownTimerWidget({
    super.key,
    required this.targetTime,
    this.isStartTime = false,
    this.style,
    this.onFinished,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final difference = widget.targetTime.difference(now);

    if (difference.isNegative) {
      if (_remaining != Duration.zero) {
        setState(() {
          _remaining = Duration.zero;
        });
        widget.onFinished?.call();
      }
    } else {
      setState(() {
        _remaining = difference;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return 'Time up';

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '${days}d ${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m';
    }
    return '${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final text = _formatDuration(_remaining);
    final isUrgent = !widget.isStartTime && _remaining.inHours == 0 && _remaining.inMinutes < 15 && _remaining > Duration.zero;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.timer_outlined,
          size: 15,
          color: isUrgent ? Colors.red : (widget.style?.color ?? Colors.grey.shade700),
        ),
        const SizedBox(width: 4),
        Text(
          widget.isStartTime ? 'Starts in $text' : text,
          style: widget.style ??
              TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isUrgent ? Colors.red : Colors.grey.shade800,
              ),
        ),
      ],
    );
  }
}
