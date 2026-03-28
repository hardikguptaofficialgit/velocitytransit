import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

class SvgShapeBorder extends ShapeBorder {
  final String svgPath;
  final double viewBoxW;
  final double viewBoxH;

  const SvgShapeBorder({
    required this.svgPath,
    required this.viewBoxW,
    required this.viewBoxH,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => getOuterPath(rect);
  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final path = parseSvgPathData(svgPath);
    final double scaleFactor = (rect.width / viewBoxW < rect.height / viewBoxH) 
        ? rect.width / viewBoxW 
        : rect.height / viewBoxH;
        
    final double dx = (rect.width - viewBoxW * scaleFactor) / 2;
    final double dy = (rect.height - viewBoxH * scaleFactor) / 2;

    final matrix = Matrix4.identity();
    matrix.scaleByDouble(scaleFactor, scaleFactor, 1.0, 1.0);
    return path.transform(matrix.storage).shift(rect.topLeft.translate(dx, dy));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}

