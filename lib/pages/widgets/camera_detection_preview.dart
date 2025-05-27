import 'package:app_face_recognition/pages/widgets/face_guide_painter.dart';
import 'package:camera/camera.dart';
import 'package:app_face_recognition/locator.dart';
import 'package:app_face_recognition/services/camera.service.dart';
import 'package:app_face_recognition/services/face_detector_service.dart';
import 'package:flutter/material.dart';

class CameraDetectionPreview extends StatelessWidget {
  CameraDetectionPreview({super.key});

  final CameraService _cameraService = locator<CameraService>();
  final FaceDetectorService _faceDetectorService =
      locator<FaceDetectorService>();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Transform.scale(
      scale: 1.0,
      child: AspectRatio(
        aspectRatio: MediaQuery.of(context).size.aspectRatio,
        child: OverflowBox(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.fitHeight,
            child: SizedBox(
              width: width,
              height:
                  width * _cameraService.cameraController!.value.aspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  CameraPreview(_cameraService.cameraController!),
                  if (_faceDetectorService.faceDetected)
                    CustomPaint(
                      painter: FaceGuidePainter(
                        face: _faceDetectorService.faces[0],
                        imageSize: _cameraService.getImageSize(),
                      ),
                      child: Container(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
