import 'package:flutter/material.dart';

class PaintingState extends ChangeNotifier {
  List<PaintStroke> _strokes = [];
  Color _currentColor = Colors.blue;
  double _currentStrokeWidth = 5.0;
  bool _isErasing = false;
  String _currentGesture = 'En espera...';

  List<PaintStroke> get strokes => List.unmodifiable(_strokes);
  Color get currentColor => _currentColor;
  double get currentStrokeWidth => _currentStrokeWidth;
  bool get isErasing => _isErasing;
  String get currentGesture => _currentGesture;

  void addStroke(PaintStroke stroke) {
    _strokes.add(stroke);
    notifyListeners();
  }

  void addStrokeFromPoints(List<Offset> points, {required Color color, required double strokeWidth, bool isErasing = false}) {
    if (points.length < 2) return;
    
    _strokes.add(PaintStroke(
      points: points,
      color: isErasing ? Colors.white : color,
      strokeWidth: strokeWidth,
      isErasing: isErasing,
    ));
    notifyListeners();
  }

  void clearCanvas() {
    _strokes.clear();
    notifyListeners();
  }

  void setColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double width) {
    _currentStrokeWidth = width;
    notifyListeners();
  }

  void toggleEraser() {
    _isErasing = !_isErasing;
    notifyListeners();
  }

  void undo() {
    if (_strokes.isNotEmpty) {
      _strokes.removeLast();
      notifyListeners();
    }
  }

  void setGesture(String gesture) {
    _currentGesture = gesture;
    notifyListeners();
  }
}

class PaintStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isErasing;

  PaintStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isErasing = false,
  });
}