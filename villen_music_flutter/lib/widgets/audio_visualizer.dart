// Audio Visualizer Widget
// 
// Simple animated bars that react to audio playback.

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:villen_music/core/theme/app_theme.dart';

class AudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final int barCount;
  final double height;
  final Color? color;

  const AudioVisualizer({
    super.key,
    required this.isPlaying,
    this.barCount = 5,
    this.height = 40,
    this.color,
  });

  @override
  State<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends State<AudioVisualizer>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(widget.barCount, (index) {
      return AnimationController(
        duration: Duration(milliseconds: 300 + _random.nextInt(400)),
        vsync: this,
      );
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(
        begin: 0.2,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    // Start with random offsets
    for (var i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: _random.nextInt(300)), () {
        if (mounted && widget.isPlaying) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void didUpdateWidget(AudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        for (var controller in _controllers) {
          controller.repeat(reverse: true);
        }
      } else {
        for (var controller in _controllers) {
          controller.stop();
          controller.animateTo(0.2);
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.accentMagenta;
    
    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          return AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                width: 4,
                height: widget.height * _animations[index].value,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.4 + (0.6 * _animations[index].value),
                  ),
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: widget.isPlaying ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ] : null,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

/// Circular Audio Visualizer - for player screen
class CircularAudioVisualizer extends StatefulWidget {
  final bool isPlaying;
  final double size;
  final Color? color;

  const CircularAudioVisualizer({
    super.key,
    required this.isPlaying,
    this.size = 280,
    this.color,
  });

  @override
  State<CircularAudioVisualizer> createState() => _CircularAudioVisualizerState();
}

class _CircularAudioVisualizerState extends State<CircularAudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(CircularAudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.accentMagenta;
    
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _CircularVisualizerPainter(
              progress: _controller.value,
              isPlaying: widget.isPlaying,
              color: color,
            ),
            child: child,
          );
        },
      ),
    );
  }
}

class _CircularVisualizerPainter extends CustomPainter {
  final double progress;
  final bool isPlaying;
  final Color color;
  final Random _random = Random(42); // Fixed seed for consistency

  _CircularVisualizerPainter({
    required this.progress,
    required this.isPlaying,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isPlaying) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2 - 20;
    
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Draw multiple circles with varying radii
    for (var i = 0; i < 3; i++) {
      final offset = sin((progress * 2 * pi) + (i * pi / 3)) * 10;
      final radius = baseRadius + offset + (i * 8);
      
      paint.color = color.withValues(
        alpha: 0.3 - (i * 0.08),
      );
      
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_CircularVisualizerPainter oldDelegate) {
    return oldDelegate.progress != progress || 
           oldDelegate.isPlaying != isPlaying;
  }
}
