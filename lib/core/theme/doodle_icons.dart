import 'package:flutter/material.dart';

/// Flex Solid Icon System — purely filled shapes, strong geometry
class DoodleIcons {
  DoodleIcons._();

  static Widget bus({double size = 24, Color? color}) =>
      _FlexIcon(painter: _BusPainter(color: color), size: size);

  static Widget route({double size = 24, Color? color}) =>
      _FlexIcon(painter: _RoutePainter(color: color), size: size);

  static Widget map({double size = 24, Color? color}) =>
      _FlexIcon(painter: _MapPainter(color: color), size: size);

  static Widget search({double size = 24, Color? color}) =>
      _FlexIcon(painter: _SearchPainter(color: color), size: size);

  static Widget pin({double size = 24, Color? color}) =>
      _FlexIcon(painter: _PinPainter(color: color), size: size);

  static Widget clock({double size = 24, Color? color}) =>
      _FlexIcon(painter: _ClockPainter(color: color), size: size);

  static Widget walking({double size = 24, Color? color}) =>
      _FlexIcon(painter: _WalkingPainter(color: color), size: size);

  static Widget star({double size = 24, Color? color}) =>
      _FlexIcon(painter: _StarPainter(color: color), size: size);

  static Widget alert({double size = 24, Color? color}) =>
      _FlexIcon(painter: _AlertPainter(color: color), size: size);

  static Widget settings({double size = 24, Color? color}) =>
      _FlexIcon(painter: _SettingsPainter(color: color), size: size);

  static Widget swap({double size = 24, Color? color}) =>
      _FlexIcon(painter: _SwapPainter(color: color), size: size);

  static Widget people({double size = 24, Color? color}) =>
      _FlexIcon(painter: _PeoplePainter(color: color), size: size);

  static Widget heatmap({double size = 24, Color? color}) =>
      _FlexIcon(painter: _HeatmapPainter(color: color), size: size);

  static Widget play({double size = 24, Color? color}) =>
      _FlexIcon(painter: _PlayPainter(color: color), size: size);

  static Widget compass({double size = 24, Color? color}) =>
      _FlexIcon(painter: _CompassPainter(color: color), size: size);

  static Widget arrowRight({double size = 24, Color? color}) =>
      _FlexIcon(painter: _ArrowRightPainter(color: color), size: size);

  static Widget close({double size = 24, Color? color}) =>
      _FlexIcon(painter: _ClosePainter(color: color), size: size);

  static Widget compare({double size = 24, Color? color}) =>
      _FlexIcon(painter: _ComparePainter(color: color), size: size);

  static Widget timeline({double size = 24, Color? color}) =>
      _FlexIcon(painter: _TimelinePainter(color: color), size: size);
}

class _FlexIcon extends StatelessWidget {
  final CustomPainter painter;
  final double size;

  const _FlexIcon({required this.painter, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: painter),
    );
  }
}

Paint _fillPaint(Color? color) => Paint()
  ..color = color ?? const Color(0xFF0F172A)
  ..style = PaintingStyle.fill;

// ── Bus icon (Solid) ──
class _BusPainter extends CustomPainter {
  final Color? color;
  _BusPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = _fillPaint(color);
    final w = size.width, h = size.height;

    // Main body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.65),
        Radius.circular(w * 0.2),
      ),
      p,
    );
    // Cutout for windshield
    final cutout = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;
    canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), Paint());
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.65),
        Radius.circular(w * 0.2),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.2, h * 0.2, w * 0.6, h * 0.25),
        Radius.circular(w * 0.08),
      ),
      cutout,
    );
    canvas.restore();

    // Wheels
    canvas.drawCircle(Offset(w * 0.3, h * 0.8), w * 0.15, p);
    canvas.drawCircle(Offset(w * 0.7, h * 0.8), w * 0.15, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Route icon (Solid) ──
class _RoutePainter extends CustomPainter {
  final Color? color;
  _RoutePainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = _fillPaint(color);
    final w = size.width, h = size.height;

    // Dots
    canvas.drawCircle(Offset(w * 0.2, h * 0.8), w * 0.15, p);
    canvas.drawCircle(Offset(w * 0.8, h * 0.2), w * 0.15, p);

    // Thick connecting line
    final pLine = Path()
      ..moveTo(w * 0.2, h * 0.8)
      ..cubicTo(w * 0.2, h * 0.5, w * 0.8, h * 0.5, w * 0.8, h * 0.2);
    canvas.drawPath(
      pLine,
      Paint()
        ..color = color ?? const Color(0xFF0F172A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.12
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Map icon (Solid) ──
class _MapPainter extends CustomPainter {
  final Color? color;
  _MapPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = _fillPaint(color);
    final w = size.width, h = size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.15, w * 0.35, h * 0.7),
        Radius.circular(w * 0.08),
      ),
      p,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.55, h * 0.15, w * 0.35, h * 0.7),
        Radius.circular(w * 0.08),
      ),
      p,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Search (Solid Ring + Bold handle) ──
class _SearchPainter extends CustomPainter {
  final Color? color;
  _SearchPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color ?? const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.15
      ..strokeCap = StrokeCap.round;

    final w = size.width, h = size.height;
    canvas.drawCircle(Offset(w * 0.45, h * 0.45), w * 0.25, p);
    canvas.drawLine(Offset(w * 0.65, h * 0.65), Offset(w * 0.85, h * 0.85), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Pin icon (Solid) ──
class _PinPainter extends CustomPainter {
  final Color? color;
  _PinPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = _fillPaint(color);
    final w = size.width, h = size.height;

    final path = Path()
      ..moveTo(w * 0.5, h * 0.95)
      ..quadraticBezierTo(w * 0.15, h * 0.6, w * 0.15, h * 0.4)
      ..arcToPoint(
        Offset(w * 0.85, h * 0.4),
        radius: Radius.circular(w * 0.35),
      )
      ..quadraticBezierTo(w * 0.85, h * 0.6, w * 0.5, h * 0.95);
    
    canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), Paint());
    canvas.drawPath(path, p);
    
    // Hole
    final cutout = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;
    canvas.drawCircle(Offset(w * 0.5, h * 0.4), w * 0.15, cutout);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Clock icon (Solid Ring) ──
class _ClockPainter extends CustomPainter {
  final Color? color;
  _ClockPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final strokeP = Paint()
      ..color = color ?? const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.15
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.35, strokeP);
    
    // Hands
    final p = _fillPaint(color);
    p.strokeCap = StrokeCap.round;
    p.strokeWidth = w * 0.15;
    p.style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.5, h * 0.5), Offset(w * 0.5, h * 0.3), p);
    canvas.drawLine(Offset(w * 0.5, h * 0.5), Offset(w * 0.65, h * 0.5), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Walking (Solid Bold Lines) ──
class _WalkingPainter extends CustomPainter {
  final Color? color;
  _WalkingPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..color = color ?? const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.12
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(w * 0.5, h * 0.15), w * 0.1, _fillPaint(color));
    canvas.drawLine(Offset(w * 0.5, h * 0.3), Offset(w * 0.5, h * 0.6), p);
    canvas.drawLine(Offset(w * 0.3, h * 0.4), Offset(w * 0.7, h * 0.4), p);
    canvas.drawLine(Offset(w * 0.5, h * 0.6), Offset(w * 0.35, h * 0.9), p);
    canvas.drawLine(Offset(w * 0.5, h * 0.6), Offset(w * 0.65, h * 0.9), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Star icon (Solid) ──
class _StarPainter extends CustomPainter {
  final Color? color;
  _StarPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p = _fillPaint(color);
    final w = size.width, h = size.height;

    final path = Path()
      ..moveTo(w * 0.5, h * 0.1)
      ..lineTo(w * 0.62, h * 0.35)
      ..lineTo(w * 0.9, h * 0.38)
      ..lineTo(w * 0.7, h * 0.58)
      ..lineTo(w * 0.76, h * 0.88)
      ..lineTo(w * 0.5, h * 0.72)
      ..lineTo(w * 0.24, h * 0.88)
      ..lineTo(w * 0.3, h * 0.58)
      ..lineTo(w * 0.1, h * 0.38)
      ..lineTo(w * 0.38, h * 0.35)
      ..close();
    canvas.drawPath(path, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Alert icon (Solid Triangle) ──
class _AlertPainter extends CustomPainter {
  final Color? color;
  _AlertPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = _fillPaint(color);

    final path = Path()
      ..moveTo(w * 0.5, h * 0.1)
      ..lineTo(w * 0.9, h * 0.85)
      ..lineTo(w * 0.1, h * 0.85)
      ..close();

    canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), Paint());
    canvas.drawPath(path, p);
    
    final cutout = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear
      ..strokeWidth = w * 0.1
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    
    canvas.drawLine(Offset(w * 0.5, h * 0.4), Offset(w * 0.5, h * 0.6), cutout);
    cutout.style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.75), w * 0.05, cutout);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Settings icon (Solid Gear) ──
class _SettingsPainter extends CustomPainter {
  final Color? color;
  _SettingsPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = _fillPaint(color);

    canvas.saveLayer(Rect.fromLTWH(0, 0, w, h), Paint());
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.25, p);
    
    final strokeP = Paint()
      ..color = color ?? const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.round;
      
    canvas.drawLine(Offset(w * 0.5, h * 0.15), Offset(w * 0.5, h * 0.85), strokeP);
    canvas.drawLine(Offset(w * 0.2, h * 0.32), Offset(w * 0.8, h * 0.68), strokeP);
    canvas.drawLine(Offset(w * 0.2, h * 0.68), Offset(w * 0.8, h * 0.32), strokeP);

    final cutout = Paint()
      ..color = Colors.transparent
      ..blendMode = BlendMode.clear;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.15, cutout);
    canvas.restore();
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Swap icon (Bold arrows) ──
class _SwapPainter extends CustomPainter {
  final Color? color;
  _SwapPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..color = color ?? const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawLine(Offset(w * 0.35, h * 0.75), Offset(w * 0.35, h * 0.25), p);
    canvas.drawLine(Offset(w * 0.35, h * 0.25), Offset(w * 0.15, h * 0.45), p);

    canvas.drawLine(Offset(w * 0.65, h * 0.25), Offset(w * 0.65, h * 0.75), p);
    canvas.drawLine(Offset(w * 0.65, h * 0.75), Offset(w * 0.85, h * 0.55), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── People icon (Solid) ──
class _PeoplePainter extends CustomPainter {
  final Color? color;
  _PeoplePainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = _fillPaint(color);

    canvas.drawCircle(Offset(w * 0.35, h * 0.3), w * 0.15, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.1, h * 0.55, w * 0.5, h * 0.35),
        Radius.circular(w * 0.15),
      ),
      p,
    );

    canvas.drawCircle(Offset(w * 0.7, h * 0.25), w * 0.12, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.5, h * 0.45, w * 0.4, h * 0.4),
        Radius.circular(w * 0.15),
      ),
      p,
    );
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Heatmap icon (Solid Grid) ──
class _HeatmapPainter extends CustomPainter {
  final Color? color;
  _HeatmapPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = _fillPaint(color);

    for (var r = 0; r < 2; r++) {
      for (var c = 0; c < 2; c++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              w * (0.15 + c * 0.4),
              h * (0.15 + r * 0.4),
              w * 0.3,
              h * 0.3,
            ),
            Radius.circular(w * 0.1),
          ),
          p,
        );
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Play icon (Solid) ──
class _PlayPainter extends CustomPainter {
  final Color? color;
  _PlayPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = _fillPaint(color);
    
    final path = Path()
      ..moveTo(w * 0.3, h * 0.2)
      ..lineTo(w * 0.8, h * 0.5)
      ..lineTo(w * 0.3, h * 0.8)
      ..close();
      
    // Applying rounded corners generally requires an advanced path for polygons,
    // but drawing a simple play button path filled perfectly matches flex style.
    canvas.drawPath(path, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Compass icon (Solid) ──
class _CompassPainter extends CustomPainter {
  final Color? color;
  _CompassPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..color = color ?? const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.15
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.35, p);
    
    final fill = _fillPaint(color);
    final np = Path()
      ..moveTo(w * 0.5, h * 0.25)
      ..lineTo(w * 0.45, h * 0.5)
      ..lineTo(w * 0.5, h * 0.75)
      ..lineTo(w * 0.55, h * 0.5)
      ..close();
    canvas.drawPath(np, fill);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Arrow Right (Bold) ──
class _ArrowRightPainter extends CustomPainter {
  final Color? color;
  _ArrowRightPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..color = color ?? const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.15
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawLine(Offset(w * 0.15, h * 0.5), Offset(w * 0.85, h * 0.5), p);
    canvas.drawLine(Offset(w * 0.5, h * 0.15), Offset(w * 0.85, h * 0.5), p);
    canvas.drawLine(Offset(w * 0.5, h * 0.85), Offset(w * 0.85, h * 0.5), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Close (Bold) ──
class _ClosePainter extends CustomPainter {
  final Color? color;
  _ClosePainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..color = color ?? const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.18
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.25, h * 0.25), Offset(w * 0.75, h * 0.75), p);
    canvas.drawLine(Offset(w * 0.75, h * 0.25), Offset(w * 0.25, h * 0.75), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Compare icon (Bold lines) ──
class _ComparePainter extends CustomPainter {
  final Color? color;
  _ComparePainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint()
      ..color = color ?? const Color(0xFF0F172A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.15
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(w * 0.15, h * 0.35), Offset(w * 0.85, h * 0.35), p);
    canvas.drawLine(Offset(w * 0.15, h * 0.65), Offset(w * 0.85, h * 0.65), p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Timeline icon (Solid nodes) ──
class _TimelinePainter extends CustomPainter {
  final Color? color;
  _TimelinePainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = _fillPaint(color);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.2, h * 0.1, w * 0.15, h * 0.8),
        Radius.circular(w * 0.1),
      ),
      p,
    );
    
    for (var i = 0; i < 3; i++) {
        final y = h * (0.2 + i * 0.3);
        canvas.drawCircle(Offset(w * 0.275, y), w * 0.15, p);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.5, y - w * 0.08, w * 0.4, w * 0.16),
            Radius.circular(w * 0.08),
          ),
          p,
        );
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
