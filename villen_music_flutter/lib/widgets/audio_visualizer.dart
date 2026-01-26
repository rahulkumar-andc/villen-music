import 'dart:math';
import 'package:flutter/material.dart';

class AudioVisualizer extends StatefulWidget {
  final List<double> amplitudes;
  final Color color;
  final int barCount;
  final double width;
  final double height;

  const AudioVisualizer({
    super.key,
    required this.amplitudes,
    this.color = Colors.blue,
    this.barCount = 32,
    this.width = 200,
    this.height = 60,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          final amplitude = widget.amplitudes.isNotEmpty
              ? widget.amplitudes[min(index, widget.amplitudes.length - 1)]
              : 0.0;

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final height = amplitude * widget.height * (0.5 + 0.5 * _controller.value);
              return Container(
                width: widget.width / widget.barCount - 2,
                height: max(height, 2),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class CircularAudioVisualizer extends StatefulWidget {
  final List<double> amplitudes;
  final Color color;
  final double size;

  const CircularAudioVisualizer({
    super.key,
    required this.amplitudes,
    this.color = Colors.blue,
    this.size = 100,
  });

  @override
  State<CircularAudioVisualizer> createState() => _CircularAudioVisualizerState();
}

class _CircularAudioVisualizerState extends State<CircularAudioVisualizer>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CustomPaint(
        painter: CircularVisualizerPainter(
          amplitudes: widget.amplitudes,
          color: widget.color,
          animation: _controller,
        ),
      ),
    );
  }
}

class CircularVisualizerPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;
  final Animation<double> animation;

  CircularVisualizerPainter({
    required this.amplitudes,
    required this.color,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const barCount = 64;
    final angleStep = 2 * pi / barCount;

    for (int i = 0; i < barCount; i++) {
      final amplitude = amplitudes.isNotEmpty
          ? amplitudes[min(i, amplitudes.length - 1)]
          : 0.0;

      final animatedAmplitude = amplitude * (0.3 + 0.7 * animation.value);

      final angle = i * angleStep;
      final innerRadius = radius * 0.6;
      final outerRadius = innerRadius + (radius * 0.4 * animatedAmplitude);

      final startPoint = Offset(
        center.dx + innerRadius * cos(angle),
        center.dy + innerRadius * sin(angle),
      );

      final endPoint = Offset(
        center.dx + outerRadius * cos(angle),
        center.dy + outerRadius * sin(angle),
      );

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(CircularVisualizerPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes ||
           oldDelegate.color != color;
  }
}