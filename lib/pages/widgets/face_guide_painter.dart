import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceGuidePainter extends CustomPainter {
  final Size imageSize;
  final Face? face;

  FaceGuidePainter({required this.imageSize, required this.face});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint overlayPaint = Paint()..color = Colors.black.withOpacity(0.5);

    final Offset center = Offset(size.width / 2, size.height / 2);

    final double ovalWidth = size.width * 0.6;
    final double ovalHeight = size.height * 0.4;

    final Rect ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    final Path fullScreen =
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path ovalPath = Path()..addOval(ovalRect);

    final Path masked = Path.combine(
      PathOperation.difference,
      fullScreen,
      ovalPath,
    );

    canvas.drawPath(masked, overlayPaint);

    bool isFaceInCenter = false;

    if (face != null) {
      // Hitung titik tengah wajah (boundingBox)
      final faceCenter = Offset(
        face!.boundingBox.left + face!.boundingBox.width / 2,
        face!.boundingBox.top + face!.boundingBox.height / 2,
      );

      // Konversi koordinat titik tengah wajah ke koordinat canvas
      final double scaleX = size.width / imageSize.width;
      final double scaleY = size.height / imageSize.height;

      final Offset faceCenterOnCanvas = Offset(
        faceCenter.dx * scaleX,
        faceCenter.dy * scaleY,
      );

      // Cek apakah titik tengah wajah berada di dalam oval area toleransi
      // Rumus ellipse: ((x - h)^2 / a^2) + ((y - k)^2 / b^2) <= 1
      final double dx = faceCenterOnCanvas.dx - center.dx;
      final double dy = faceCenterOnCanvas.dy - center.dy;

      final double a = ovalWidth / 2;
      final double b = ovalHeight / 2;

      final double ellipseEq = (dx * dx) / (a * a) + (dy * dy) / (b * b);

      isFaceInCenter = ellipseEq <= 1.0;
    }

    final Paint borderPaint =
        Paint()
          ..color = isFaceInCenter ? Colors.green : Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant FaceGuidePainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.face != face;
  }
}
