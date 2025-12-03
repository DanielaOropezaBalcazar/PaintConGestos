import 'package:flutter/material.dart';
import '../painting_state.dart';

class PaintingCanvas extends StatelessWidget {
  final List<PaintStroke> strokes;

  const PaintingCanvas({super.key, required this.strokes});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PaintingCanvasPainter(strokes: strokes),
      size: Size.infinite,
    );
  }
}

class _PaintingCanvasPainter extends CustomPainter {
  final List<PaintStroke> strokes;

  _PaintingCanvasPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo blanco
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Dibujar trazos
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      
      final paint = Paint()
        ..color = stroke.isErasing ? Colors.white : stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(stroke.points[0].dx, stroke.points[0].dy);
      
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}