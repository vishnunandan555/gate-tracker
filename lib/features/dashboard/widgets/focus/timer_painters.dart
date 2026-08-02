import 'package:flutter/material.dart';
import 'package:gateletics/providers/providers.dart';

Widget buildMethodIcon(FocusMethodDetails details, Color color, {double size = 18}) {
  return Image.asset(
    details.iconPath,
    width: size,
    height: size,
    color: color,
  );
}


class PulsingIndicatorNode extends StatefulWidget {
  final Color accentColor;
  final bool isPulsing;

  const PulsingIndicatorNode({
    super.key,
    required this.accentColor,
    required this.isPulsing,
  });

  @override
  State<PulsingIndicatorNode> createState() => _PulsingIndicatorNodeState();
}

class _PulsingIndicatorNodeState extends State<PulsingIndicatorNode>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(_controller);

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant PulsingIndicatorNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsing && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: widget.accentColor, width: 2),
            ),
          ),
        );
      },
    );
  }
}

class DottedLineConnection extends StatefulWidget {
  final Color accentColor;
  final bool isFlashing;

  const DottedLineConnection({
    super.key,
    required this.accentColor,
    required this.isFlashing,
  });

  @override
  State<DottedLineConnection> createState() => _DottedLineConnectionState();
}

class _DottedLineConnectionState extends State<DottedLineConnection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0.2, end: 1.0).animate(_controller);

    if (widget.isFlashing) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant DottedLineConnection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlashing && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isFlashing && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: SizedBox(
            width: 32,
            height: 2,
            child: CustomPaint(
              painter: DottedPainter(color: widget.accentColor),
            ),
          ),
        );
      },
    );
  }
}

class DottedPainter extends CustomPainter {
  final Color color;

  DottedPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 3;
    const dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SquircleTimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  SquircleTimerPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  Path _bottomCenterStartRoundedRectPath(Rect rect, double radius) {
    final path = Path();
    final left = rect.left;
    final top = rect.top;
    final width = rect.width;
    final height = rect.height;

    final startX = left + width / 2;
    final startY = top + height;

    path.moveTo(startX, startY);
    path.lineTo(left + radius, top + height);
    path.arcToPoint(
      Offset(left, top + height - radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(left, top + radius);
    path.arcToPoint(
      Offset(left + radius, top),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(left + width - radius, top);
    path.arcToPoint(
      Offset(left + width, top + radius),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(left + width, top + height - radius);
    path.arcToPoint(
      Offset(left + width - radius, top + height),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    path.lineTo(startX, startY);

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final inset = strokeWidth / 2 + 1;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );

    final fullPath = _bottomCenterStartRoundedRectPath(rect, 24);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fullPath, trackPaint);

    if (progress < 0.005) return;

    final metric = fullPath.computeMetrics().first;
    final progressPath = metric.extractPath(0, metric.length * progress);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(progressPath, progressPaint);
  }

  @override
  bool shouldRepaint(SquircleTimerPainter old) =>
      old.progress != progress || old.color != color;
}
