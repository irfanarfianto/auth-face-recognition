import 'package:app_face_recognition/locator.dart';
import 'package:app_face_recognition/services/camera.service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceDetectorService {
  final CameraService _cameraService = locator<CameraService>();

  FaceDetector? _faceDetector;

  List<Face> _faces = [];

  /// Public getters
  List<Face> get faces => _faces;
  bool get faceDetected => _faces.isNotEmpty;
  FaceDetector? get faceDetector => _faceDetector;

  /// Initialize face detector
  void initialize() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
        enableContours: true,
        enableClassification: true,
      ),
    );
  }

  /// Detect faces from real-time CameraImage (only if YUV_420_888)
  Future<void> detectFacesFromStream(CameraImage image) async {
    if (image.format.group != ImageFormatGroup.yuv420) {
      debugPrint("Unsupported image format: ${image.format.group}");
      _faces = [];
      return;
    }

    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final InputImage inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation:
              _cameraService.cameraRotation ?? InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      _faces = (await _faceDetector?.processImage(inputImage))!;
    } catch (e) {
      debugPrint("Error during stream face detection: $e");
      _faces = [];
    }
  }

  /// Detect faces from captured image file (more stable & reliable)
  Future<void> detectFacesFromFile() async {
    try {
      final XFile? file = await _cameraService.cameraController?.takePicture();
      if (file == null) {
        debugPrint("No picture captured.");
        _faces = [];
        return;
      }

      final InputImage inputImage = InputImage.fromFilePath(file.path);
      _faces = (await _faceDetector?.processImage(inputImage))!;
    } catch (e) {
      debugPrint("Error during file face detection: $e");
      _faces = [];
    }
  }

  /// Utility method to detect once (optionally with custom rotation)
  Future<List<Face>?> detectOnce(
    CameraImage image,
    InputImageRotation rotation,
  ) async {
    if (image.format.group != ImageFormatGroup.yuv420) {
      debugPrint("Unsupported image format for one-time detection.");
      return [];
    }

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final InputImage inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.yuv_420_888,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    try {
      return await _faceDetector?.processImage(inputImage);
    } catch (e) {
      debugPrint("Error during one-time face detection: $e");
      return [];
    }
  }

  /// Dispose face detector instance
  void dispose() {
    _faceDetector?.close();
  }
}
