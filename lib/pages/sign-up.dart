import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:app_face_recognition/utils/toast.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'package:app_face_recognition/pages/db/databse_helper.dart';
import 'package:app_face_recognition/pages/models/user.model.dart';
import 'package:app_face_recognition/pages/widgets/face_guide_painter.dart';
import 'package:app_face_recognition/pages/widgets/camera_header.dart';
import 'package:app_face_recognition/services/face_detector_service.dart';
import 'package:app_face_recognition/services/camera.service.dart';
import 'package:app_face_recognition/services/ml_service.dart';
import 'package:app_face_recognition/locator.dart';

class SignUp extends StatefulWidget {
  static const String routeName = 'signup';
  static const String routePath = '/signup';
  const SignUp({super.key});

  @override
  State<SignUp> createState() => SignUpState();
}

class SignUpState extends State<SignUp> {
  String? imagePath;
  Face? faceDetected;
  Size? imageSize;

  bool _detectingFaces = false;
  bool pictureTaken = false;
  bool _initializing = false;
  bool _saving = false;
  bool _hasAutoCaptured = false;

  Timer? _centerTimer;
  int _centerHoldSeconds = 0;

  final FaceDetectorService _faceDetectorService =
      locator<FaceDetectorService>();
  final CameraService _cameraService = locator<CameraService>();
  final MLService _mlService = locator<MLService>();

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  @override
  void dispose() {
    _centerTimer?.cancel();
    _cameraService.dispose();
    _faceDetectorService.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    setState(() => _initializing = true);
    await _cameraService.initialize();
    setState(() => _initializing = false);

    imageSize = _cameraService.getImageSize();
    _startImageStream();
  }

  void _startImageStream() {
    _cameraService.cameraController?.startImageStream((image) async {
      if (_detectingFaces || _saving) return;

      _detectingFaces = true;
      try {
        await _faceDetectorService.detectFacesFromStream(image);

        if (!mounted) return;

        if (_faceDetectorService.faces.isNotEmpty) {
          final face = _faceDetectorService.faces.first;
          final faceBox = face.boundingBox;
          final imageWidth = imageSize?.width ?? 0;
          final imageHeight = imageSize?.height ?? 0;
          final faceCenterX = faceBox.left + faceBox.width / 2;
          final faceCenterY = faceBox.top + faceBox.height / 2;
          const tolerance = 50.0;

          final isCentered =
              (faceCenterX - imageWidth / 2).abs() < tolerance &&
              (faceCenterY - imageHeight / 2).abs() < tolerance;

          setState(() {
            faceDetected = face;
          });

          if (isCentered && !_hasAutoCaptured) {
            _centerTimer ??= Timer.periodic(const Duration(seconds: 1), (
              timer,
            ) {
              _centerHoldSeconds++;
              if (_centerHoldSeconds >= 3) {
                _centerTimer?.cancel();
                _centerTimer = null;
                _hasAutoCaptured = true;
                onShot();
              }
            });
          } else {
            _resetTimer();
          }
        } else {
          setState(() => faceDetected = null);
          _resetTimer();
        }
      } catch (e) {
        debugPrint('Face detection error: $e');
      } finally {
        _detectingFaces = false;
      }
    });
  }

  void _resetTimer() {
    _centerTimer?.cancel();
    _centerTimer = null;
    _centerHoldSeconds = 0;
  }

  Future<bool> onShot() async {
    if (faceDetected == null) {
      ToastUtils.show("No face detected!");
      return false;
    }

    try {
      setState(() => _saving = true);
      final file = await _cameraService.takePicture();
      imagePath = file?.path;

      if (file == null || imagePath == null) {
        setState(() => _saving = false);
        return false;
      }

      setState(() => pictureTaken = true);

      await _mlService.setCurrentPredictionFromPath(imagePath!);
      final embedding = _mlService.predictedData;

      if (embedding.isEmpty) {
        ToastUtils.show("Face embedding gagal dibuat.");
        setState(() => _saving = false);
        return false;
      }

      final result = await _showInputDialog();
      if (result == null) {
        setState(() {
          _saving = false;
          pictureTaken = false;
          imagePath = null;
          _hasAutoCaptured = false;
        });
        _startImageStream();
        return false;
      }

      final newUser = User(
        user: result['name']!,
        password: result['password']!,
        modelData: embedding,
      );

      await DatabaseHelper.instance.insert(newUser);
      ToastUtils.show("Data wajah berhasil disimpan!");

      setState(() => _saving = false);
      return true;
    } catch (e) {
      debugPrint('Error saving face data: $e');
      setState(() => _saving = false);
      return false;
    }
  }

  Future<Map<String, String>?> _showInputDialog() {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Lengkapi Data"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Batal"),
              ),
              TextButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final password = passwordController.text.trim();
                  if (name.isNotEmpty && password.isNotEmpty) {
                    Navigator.of(
                      context,
                    ).pop({'name': name, 'password': password});
                  }
                },
                child: const Text("Simpan"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final double mirror = math.pi;

    Widget body;

    if (_initializing) {
      body = const Center(child: CircularProgressIndicator());
    } else if (pictureTaken && imagePath != null) {
      body = SizedBox(
        width: width,
        height: height,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(mirror),
          child: FittedBox(
            fit: BoxFit.cover,
            child: Image.file(File(imagePath!)),
          ),
        ),
      );
    } else {
      body = Transform.scale(
        scale: 1.0,
        child: AspectRatio(
          aspectRatio: MediaQuery.of(context).size.aspectRatio,
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: width,
                height:
                    width *
                    (_cameraService.cameraController?.value.aspectRatio ?? 1.0),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_cameraService.cameraController != null)
                      CameraPreview(_cameraService.cameraController!),
                    if (faceDetected != null && imageSize != null)
                      CustomPaint(
                        painter: FaceGuidePainter(
                          face: faceDetected!,
                          imageSize: imageSize!,
                        ),
                      ),
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Text(
                        faceDetected != null
                            ? (_centerHoldSeconds > 0
                                ? 'Tahan posisi wajah... $_centerHoldSeconds/3 detik'
                                : 'Posisikan wajah di dalam oval')
                            : 'Mencari wajah...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          backgroundColor: Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          body,
          CameraHeader(
            "SIGN UP",
            onBackPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
