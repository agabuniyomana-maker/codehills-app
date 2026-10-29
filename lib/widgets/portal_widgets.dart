import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Gold-bordered rounded container used for every portal card.
class PortalCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final Color border;
  final Color? background;

  const PortalCard({
    super.key,
    required this.child,
    this.radius = 26,
    this.border = AppColors.gold,
    this.background = AppColors.cream,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: border, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 2),
          child: child,
        ),
      );
}

/// Decorative Imigongo-inspired band (Rwanda's classic geometric art):
/// alternating triangles and diamonds in earth tones.
class ImigongoBand extends StatelessWidget {
  final double height;

  const ImigongoBand({super.key, this.height = 22});

  @override
  Widget build(BuildContext context) => SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(painter: _ImigongoPainter()),
      );
}

class _ImigongoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final step = h * 1.15;
    final count = (size.width / step).ceil() + 1;

    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.darkBrown,
    );

    final gold = Paint()..color = AppColors.gold;
    final cream = Paint()..color = AppColors.cream;
    final yellow = Paint()..color = AppColors.yellow;

    for (var i = 0; i < count; i++) {
      final x = i * step;
      final up = i.isEven;
      final triangle = Path()
        ..moveTo(x, h)
        ..lineTo(x + step / 2, up ? 0 : h)
        ..lineTo(x + step, h)
        ..close();
      canvas.drawPath(triangle, i % 4 == 0 ? cream : gold);

      // small diamond accent between triangles
      final cx = x + step / 2;
      final diamond = Path()
        ..moveTo(cx, h * 0.25)
        ..lineTo(cx + h * 0.22, h * 0.55)
        ..lineTo(cx, h * 0.85)
        ..lineTo(cx - h * 0.22, h * 0.55)
        ..close();
      canvas.drawPath(diamond, i % 2 == 0 ? yellow : cream);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Round gold button matching the original `createActionButton`.
class PortalButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  const PortalButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) => filled
      ? ElevatedButton(onPressed: onPressed, child: Text(label))
      : OutlinedButton(onPressed: onPressed, child: Text(label));
}

/// Uppercase section heading with the muted brown style.
class PortalHeading extends StatelessWidget {
  final String text;
  final double size;
  final Color color;

  const PortalHeading(
    this.text, {
    super.key,
    this.size = 20,
    this.color = AppColors.darkBrown,
  });

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
          color: color,
        ),
      );
}

/// Simple deterministic Imigongo-style avatar for a username.
class ImigongoAvatar extends StatelessWidget {
  final String seed;
  final double radius;

  const ImigongoAvatar({super.key, required this.seed, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    final palette = [
      AppColors.gold,
      AppColors.darkBrown,
      AppColors.mutedBrown,
      AppColors.yellow,
    ];
    final hash = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    final color = palette[hash % palette.length];
    final angle = (hash % 4) * math.pi / 4;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.darkBrown, width: 1),
      ),
      child: Transform.rotate(
        angle: angle,
        child: Icon(Icons.diamond, size: radius, color: AppColors.cream),
      ),
    );
  }
}
