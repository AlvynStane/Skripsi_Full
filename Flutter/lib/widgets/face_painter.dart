import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FacePainter extends CustomPainter {
  FacePainter(this.faces, this.imageSize, {this.sensorOrientation = 0, this.isFrontCamera = true});

  final List<Face> faces;
  final Size imageSize;
  final int sensorOrientation;
  final bool isFrontCamera;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    double scaleX, scaleY;

    if (sensorOrientation == 90 || sensorOrientation == 270) {
      scaleX = size.width / imageSize.height;
      scaleY = size.height / imageSize.width;
    } else {
      scaleX = size.width / imageSize.width;
      scaleY = size.height / imageSize.height;
    }

    for (final face in faces) {
      Rect bbox = face.boundingBox;

      double left = bbox.left * scaleX;
      double top = bbox.top * scaleY;
      double right = bbox.right * scaleX;
      double bottom = bbox.bottom * scaleY;

      if (isFrontCamera && sensorOrientation != 90) {
        final double tempLeft = left;
        left = size.width - right;
        right = size.width - tempLeft;
      }

      final Rect scaledRect = Rect.fromLTRB(left, top, right, bottom);
      canvas.drawRect(scaledRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
