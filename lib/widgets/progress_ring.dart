import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../core/app_theme.dart';

/// Donut chart: completed (orange), in process (white / dark), to do (track).
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.todo,
    required this.inProcess,
    required this.completed,
    this.size = 220,
  });

  final int todo;
  final int inProcess;
  final int completed;
  final double size;

  @override
  Widget build(BuildContext context) {
    final total = todo + inProcess + completed;
    final percent = total == 0 ? 0 : (completed / total * 100).round();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              completed: total == 0 ? 0 : completed / total,
              inProcess: total == 0 ? 0 : inProcess / total,
              track: AppColors.track.resolveFrom(context),
              processColor: CupertinoColors.label.resolveFrom(context),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w700),
              ),
              Text(
                'Complete',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.secondaryText(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.completed,
    required this.inProcess,
    required this.track,
    required this.processColor,
  });

  final double completed; // 0..1
  final double inProcess; // 0..1
  final Color track;
  final Color processColor;

  static const double _stroke = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(_stroke / 2);
    const start = -math.pi / 2;

    Paint stroke(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round
      ..color = color;

    canvas.drawArc(arcRect, 0, 2 * math.pi, false, stroke(track));

    if (completed > 0) {
      final paint = stroke(AppColors.orange)
        ..shader = AppColors.orangeGradient.createShader(rect);
      canvas.drawArc(arcRect, start, 2 * math.pi * completed, false, paint);
    }
    if (inProcess > 0) {
      canvas.drawArc(
        arcRect,
        start + 2 * math.pi * completed,
        2 * math.pi * inProcess,
        false,
        stroke(processColor),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.completed != completed ||
      old.inProcess != inProcess ||
      old.track != track ||
      old.processColor != processColor;
}
