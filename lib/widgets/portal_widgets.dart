import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/imigongo_identity.dart';
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
        // Flutter asserts when a ListTile paints ink on a Material that sits
        // above a coloured DecoratedBox (the splash would be invisible).
        // Giving the card its own transparent Material keeps ListTiles legal.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - 2),
          child: Material(
            type: MaterialType.transparency,
            child: child,
          ),
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

/// Full Imigongo composition generated from an account's stable identity.
///
/// The artwork is decorative — [ImigongoIdentity.code] is what lets the user
/// (and screen readers) tell identities apart without relying on colour.
class ImigongoIdentityBadge extends StatelessWidget {
  final ImigongoIdentity identity;
  final double size;

  const ImigongoIdentityBadge({
    super.key,
    required this.identity,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        label: '${ImigongoIdentity.label} ${identity.code}',
        image: true,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _IdentityPainter(identity)),
        ),
      );
}

class _IdentityPainter extends CustomPainter {
  _IdentityPainter(this.identity);

  final ImigongoIdentity identity;

  static const List<Color> _palette = [
    AppColors.gold,
    AppColors.darkBrown,
    AppColors.mutedBrown,
    AppColors.yellow,
  ];

  static Color _tint(int index) => _palette[index % _palette.length];

  static Color _contrast(int index) => _palette[(index + 2) % _palette.length];

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final outer = Rect.fromLTWH(0, 0, side, side);
    final corner = Radius.circular(side * 0.18);

    canvas.drawRRect(
      RRect.fromRectAndRadius(outer, corner),
      Paint()..color = AppColors.cream,
    );

    final pad = side * 0.10;
    final grid = Rect.fromLTWH(pad, pad, side - pad * 2, side - pad * 2);
    final cellWidth = grid.width / 3;
    final cellHeight = grid.height / 3;

    for (var i = 0; i < identity.cells.length && i < 9; i++) {
      final cellRect = Rect.fromLTWH(
        grid.left + (i % 3) * cellWidth,
        grid.top + (i ~/ 3) * cellHeight,
        cellWidth,
        cellHeight,
      ).deflate(cellWidth * 0.07);
      canvas.save();
      canvas.clipRect(cellRect);
      _paintMotif(canvas, cellRect, identity.cells[i]);
      canvas.restore();
    }

    final frameWidth = math.max(1.2, side * 0.035);
    canvas.drawRRect(
      RRect.fromRectAndRadius(outer.deflate(frameWidth / 2), corner),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = frameWidth
        ..color = AppColors.gold,
    );
    if (identity.frame.isOdd) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(outer.deflate(frameWidth * 1.9), corner),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.8, frameWidth * 0.45)
          ..color = AppColors.darkBrown,
      );
    }
  }

  void _paintMotif(Canvas canvas, Rect rect, ImigongoCell cell) {
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    canvas.rotate(cell.rotation * math.pi / 2);
    canvas.translate(-rect.center.dx, -rect.center.dy);

    final fill = Paint()..color = _tint(cell.tint);
    final accent = Paint()..color = _contrast(cell.tint);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.9, rect.shortestSide * 0.11)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = _contrast(cell.tint);

    final w = rect.width;
    final h = rect.height;
    final cx = rect.center.dx;
    final cy = rect.center.dy;

    switch (cell.motif) {
      case ImigongoMotif.diamond:
        canvas.drawPath(
          Path()
            ..moveTo(cx, rect.top)
            ..lineTo(rect.right, cy)
            ..lineTo(cx, rect.bottom)
            ..lineTo(rect.left, cy)
            ..close(),
          fill,
        );
        canvas.drawPath(
          Path()
            ..moveTo(cx, rect.top + h * 0.3)
            ..lineTo(rect.left + w * 0.3, cy)
            ..lineTo(cx, rect.bottom - h * 0.3)
            ..lineTo(rect.right - w * 0.3, cy)
            ..close(),
          accent,
        );
        break;
      case ImigongoMotif.triangle:
        canvas.drawPath(
          Path()
            ..moveTo(rect.left, rect.bottom)
            ..lineTo(cx, rect.top)
            ..lineTo(rect.right, rect.bottom)
            ..close(),
          fill,
        );
        canvas.drawPath(
          Path()
            ..moveTo(rect.left, rect.top)
            ..lineTo(cx, rect.bottom)
            ..lineTo(rect.right, rect.top)
            ..close(),
          accent,
        );
        break;
      case ImigongoMotif.chevron:
        canvas.drawPath(
          Path()
            ..moveTo(rect.left, cy + h * 0.2)
            ..lineTo(cx, cy - h * 0.2)
            ..lineTo(rect.right, cy + h * 0.2),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(rect.left, cy + h * 0.45)
            ..lineTo(cx, cy + h * 0.05)
            ..lineTo(rect.right, cy + h * 0.45),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke.strokeWidth
            ..strokeCap = StrokeCap.round
            ..color = _tint(cell.tint),
        );
        break;
      case ImigongoMotif.zigzag:
        const peaks = 3;
        final path = Path()..moveTo(rect.left, cy);
        for (var i = 0; i < peaks; i++) {
          path
            ..lineTo(rect.left + w * (i + 0.5) / peaks, cy - h * 0.28)
            ..lineTo(rect.left + w * (i + 1) / peaks, cy + h * 0.12);
        }
        canvas.drawPath(path, stroke);
        break;
      case ImigongoMotif.spiral:
        canvas.drawRect(rect, fill);
        var inset = 0.0;
        for (var i = 0; i < 3; i++) {
          canvas.drawRect(
            Rect.fromLTWH(
              rect.left + w * 0.12 + inset,
              rect.top + h * 0.12 + inset,
              w * 0.76 - inset * 2,
              h * 0.76 - inset * 2,
            ),
            i.isEven ? accent : (Paint()..color = AppColors.cream),
          );
          inset += w * 0.11;
        }
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _IdentityPainter oldDelegate) =>
      oldDelegate.identity != identity;
}

/// Compact Imigongo-style avatar derived from [seed] — pass the account id
/// for a user's own avatar, or a username for comment authors.
class ImigongoAvatar extends StatelessWidget {
  final String seed;
  final double radius;

  const ImigongoAvatar({super.key, required this.seed, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    // Same stable hash as the full identity, so the small avatar never
    // disagrees with the account's own pattern.
    final identity = ImigongoIdentity.forAccount(seed);
    final palette = [
      AppColors.gold,
      AppColors.darkBrown,
      AppColors.mutedBrown,
      AppColors.yellow,
    ];
    final color = palette[identity.palette % palette.length];
    final angle = identity.cells.first.rotation * math.pi / 4;
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
