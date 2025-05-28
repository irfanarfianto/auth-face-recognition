import 'package:app_face_recognition/pages/widgets/face_guide_painter.dart';
import 'package:camera/camera.dart';
import 'package:app_face_recognition/locator.dart';
import 'package:app_face_recognition/services/camera.service.dart';
import 'package:app_face_recognition/services/face_detector_service.dart';
import 'package:flutter/material.dart';

class CameraDetectionPreview extends StatefulWidget {
  CameraDetectionPreview({super.key});

  @override
  State<CameraDetectionPreview> createState() => _CameraDetectionPreviewState();
}

class _CameraDetectionPreviewState extends State<CameraDetectionPreview> {
  final CameraService _cameraService = locator<CameraService>();
  final FaceDetectorService _faceDetectorService =
      locator<FaceDetectorService>();

  @override
  Widget build(BuildContext context) {
    final controller = _cameraService.cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

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
              height: width * controller.value.aspectRatio,
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
