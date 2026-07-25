import 'dart:async';

import 'package:flutter/material.dart';

import '../models/reservation_models.dart';
import '../services/reservation_service.dart';

/// Live countdown ("47h 59m 12s") for a 48-hour reservation hold.
class ReservationCountdown extends StatefulWidget {
  const ReservationCountdown({
    super.key,
    required this.reservation,
    this.style,
    this.prefix = '',
  });

  final ItemReservation reservation;
  final TextStyle? style;
  final String prefix;

  @override
  State<ReservationCountdown> createState() => _ReservationCountdownState();
}

class _ReservationCountdownState extends State<ReservationCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (widget.reservation.isExpired) {
        _timer?.cancel();
        ReservationService.instance.handleExpiry(widget.reservation.itemId);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _format(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m '
        '${seconds.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.reservation.remaining;
    return Text(
      '${widget.prefix}${_format(remaining)}',
      style: widget.style ??
          Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
    );
  }
}
