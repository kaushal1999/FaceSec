import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorPainter extends CustomPainter {
  FaceDetectorPainter(this.imageSize, this.results, this.direction);
  final Size imageSize;
  late double scaleX, scaleY;
  late dynamic results;
  CameraLensDirection direction;
  late Face face;
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.blue;
    for (String label in results.keys) {
      for (Face face in results[label]) {
        scaleX = size.width / imageSize.width;
        scaleY = size.height / imageSize.height;
        canvas.drawRRect(
            _scaleRect(
                rect: face.boundingBox,
                widgetSize: size,
                scaleX: scaleX,
                scaleY: scaleY,
                direction: direction),
            paint);
        TextSpan span = TextSpan(
            style: TextStyle(color: Colors.orange[300], fontSize: 15),
            text: label == 'UNKNOWN' ? "" : label);
        TextPainter textPainter = TextPainter(
            text: span,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr);
        textPainter.layout();
        if (direction == CameraLensDirection.front) {
          textPainter.paint(
              canvas,
              Offset(size.width - (60 + face.boundingBox.left) * scaleX,
                  (face.boundingBox.top - 10) * scaleY));
        } else {
          textPainter.paint(
              canvas,
              Offset((face.boundingBox.left) * scaleX,
                  (face.boundingBox.top - 10) * scaleY));
        }
      }
    }
  }

  @override
  bool shouldRepaint(FaceDetectorPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.results != results;
  }
}

RRect _scaleRect(
    {required Rect rect,
    required Size widgetSize,
    double? scaleX,
    double? scaleY,
    required CameraLensDirection direction}) {
  if (direction == CameraLensDirection.front) {
    return RRect.fromLTRBR(
        (widgetSize.width - rect.left * scaleX!),
        rect.top * scaleY!,
        widgetSize.width - rect.right * scaleX,
        rect.bottom * scaleY,
        const Radius.circular(10));
  }
  return RRect.fromLTRBR((rect.left * scaleX!), rect.top * scaleY!,
      rect.right * scaleX, rect.bottom * scaleY, const Radius.circular(10));
}
