import 'dart:math';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Canvas-based particle burst — triggered on a correct match.
// 16 circles fan out radially, decelerating and fading over 600ms.
// ---------------------------------------------------------------------------

class ParticleBurst extends StatefulWidget {
  const ParticleBurst({
    super.key,
    required this.color,
    required this.onComplete,
  });

  final Color color;
  final VoidCallback onComplete;

  @override
  State<ParticleBurst> createState() => _ParticleBurstState();
}

class _ParticleData {
  _ParticleData(Random rng, Color baseColor)
      : angle  = rng.nextDouble() * 2 * pi,
        speed  = 55 + rng.nextDouble() * 75,
        radius = 3.0 + rng.nextDouble() * 3.5,
        color  = Color.lerp(baseColor, Colors.white, rng.nextDouble() * 0.4)!;

  final double angle;
  final double speed;
  final double radius;
  final Color color;
}

class _ParticleBurstState extends State<ParticleBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_ParticleData> _particles;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _particles = List.generate(16, (_) => _ParticleData(rng, widget.color));
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    )
      ..addListener(() => setState(() {}))
      ..forward().whenComplete(widget.onComplete);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _BurstPainter(_particles, _ctrl.value),
        size: const Size(140, 140),
      ),
    );
  }
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter(this.particles, this.progress);

  final List<_ParticleData> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    // Decelerate with easeOut so particles slow as they expand.
    final eased = Curves.easeOut.transform(progress);

    for (final p in particles) {
      final dist    = p.speed * eased;
      final x       = cx + cos(p.angle) * dist;
      final y       = cy + sin(p.angle) * dist;
      final opacity = (1.0 - eased).clamp(0.0, 1.0);
      final r       = p.radius * (1.0 - eased * 0.5);

      canvas.drawCircle(
        Offset(x, y),
        r,
        Paint()..color = p.color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.progress != progress;
}
