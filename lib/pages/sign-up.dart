import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:app_face_recognition/pages/db/databse_helper.dart';
import 'package:app_face_recognition/pages/models/user.model.dart';
import 'package:app_face_recognition/pages/widgets/face_guide_painter.dart';
import 'package:app_face_recognition/services/face_detector_service.dart';
import 'package:app_face_recognition/locator.dart';
import 'package:app_face_recognition/pages/widgets/auth-action-button.dart';
import 'package:app_face_recognition/pages/widgets/camera_header.dart';
import 'package:app_face_recognition/services/camera.service.dart';
import 'package:app_face_recognition/services/ml_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  SignUpState createState() => SignUpState();
}

class SignUpState extends State<SignUp> {
  String? imagePath;
  Face? faceDetected;
  Size? imageSize;

  bool _detectingFaces = false;
  bool pictureTaken = false;

  bool _initializing = false;

  bool _saving = false;
  bool _bottomSheetVisible = false;
  bool _hasAutoCaptured = false;

  // service injection
  final FaceDetectorService _faceDetectorService =
      locator<FaceDetectorService>();
  final CameraService _cameraService = locator<CameraService>();
  final MLService _mlService = locator<MLService>();

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _faceDetectorService.dispose();
    super.dispose();
  }

  _start() async {
    setState(() => _initializing = true);
    await _cameraService.initialize();
    setState(() => _initializing = false);

    _frameFaces();
  }

  Future<bool> onShot() async {
    if (faceDetected == null) {
      showDialog(
        context: context,
        builder:
            (context) => const AlertDialog(content: Text('No face detected!')),
      );
      return false;
    }

    try {
      setState(() => _saving = true);
      await Future.delayed(const Duration(milliseconds: 500));
      XFile? file = await _cameraService.takePicture();
      imagePath = file?.path;

      if (file == null || imagePath == null) {
        setState(() => _saving = false);
        return false;
      }

      // Simpan sementara state UI
      setState(() {
        pictureTaken = true;
        _bottomSheetVisible = true;
      });

      // Dapatkan embedding wajah
      await _mlService.setCurrentPredictionFromPath(imagePath!);
      final List embedding = _mlService.predictedData;

      if (embedding.isEmpty) {
        showDialog(
          context: context,
          builder:
              (context) => const AlertDialog(
                content: Text('Face embedding gagal dibuat.'),
              ),
        );
        setState(() => _saving = false);
        return false;
      }

      // Pop-up form untuk input nama & password
      final result = await showDialog<Map<String, String>>(
        context: context,
        builder: (context) {
          final nameController = TextEditingController();
          final passwordController = TextEditingController();

          return AlertDialog(
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
                child: const Text("Batal"),
                onPressed: () => Navigator.of(context).pop(null),
              ),
              TextButton(
                child: const Text("Simpan"),
                onPressed: () {
                  final name = nameController.text.trim();
                  final password = passwordController.text.trim();
                  if (name.isNotEmpty && password.isNotEmpty) {
                    Navigator.of(
                      context,
                    ).pop({'name': name, 'password': password});
                  }
                },
              ),
            ],
          );
        },
      );

      if (result == null) {
        setState(() => _saving = false);
        return false;
      }

      final newUser = User(
        user: result['name']!,
        password: result['password']!,
        modelData: embedding,
      );

      await DatabaseHelper.instance.insert(newUser);

      showDialog(
        context: context,
        builder:
            (context) => const AlertDialog(
              content: Text('Data wajah berhasil disimpan!'),
            ),
      );

      setState(() => _saving = false);
      return true;
    } catch (e) {
      print('Error saving face data: $e');
      setState(() => _saving = false);
      return false;
    }
  }

  _frameFaces() {
    imageSize = _cameraService.getImageSize();

    _cameraService.cameraController?.startImageStream((image) async {
      if (_cameraService.cameraController != null) {
        if (_detectingFaces) return;

        _detectingFaces = true;

        try {
          await _faceDetectorService.detectFacesFromStream(image);

          // Penting: Periksa apakah widget masih mounted sebelum setState
          if (!mounted) {
            _detectingFaces = false;
            return; // Keluar jika widget sudah tidak mounted
          }

          if (_faceDetectorService.faces.isNotEmpty) {
            setState(() {
              // Sekarang aman karena sudah ada cek 'mounted'
              faceDetected = _faceDetectorService.faces[0];
            });
            final faceBox = faceDetected!.boundingBox;
            final imageWidth = imageSize?.width ?? 0;
            final imageHeight = imageSize?.height ?? 0;
            final centerX = imageWidth / 2;
            final centerY = imageHeight / 2;
            final faceCenterX = faceBox.left + faceBox.width / 2;
            final faceCenterY = faceBox.top + faceBox.height / 2;
            const double tolerance = 50.0;

            final isCentered =
                (faceCenterX - centerX).abs() < tolerance &&
                (faceCenterY - centerY).abs() < tolerance;
            print(
              'Face center: ($faceCenterX, $faceCenterY), '
              'Frame center: ($centerX, $centerY), '
              'isCentered: $isCentered',
            );

            if (isCentered && !_hasAutoCaptured && !_saving && mounted) {
              _hasAutoCaptured = true;
              onShot();
            }
            if (_saving) {
              // Jika _mlService.setCurrentPrediction juga async dan ada setState di callbacknya,
              // pastikan ada cek 'mounted' di sana juga atau di callbacknya.
              _mlService.setCurrentPrediction(image, faceDetected!);
              if (mounted) {
                // Cek lagi jika ada setState setelah operasi _mlService
                setState(() {
                  _saving = false;
                });
              }
            }
          } else {
            print('face is null');
            setState(() {
              // Sekarang aman
              faceDetected = null;
            });
          }

          _detectingFaces = false;
        } catch (e) {
          print('Error _faceDetectorService face => $e');
          _detectingFaces = false;
        }
      }
    });
  }

  _onBackPressed() {
    Navigator.of(context).pop();
  }

  _reload() {
    setState(() {
      _bottomSheetVisible = false;
      pictureTaken = false;
      _hasAutoCaptured = false;
    });
    _start();
  }

  @override
  Widget build(BuildContext context) {
    final double mirror = math.pi;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    late Widget body;
    if (_initializing) {
      body = Center(child: CircularProgressIndicator());
    }

    if (!_initializing && pictureTaken) {
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
    }

    if (!_initializing && !pictureTaken) {
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
                    width * _cameraService.cameraController!.value.aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CameraPreview(_cameraService.cameraController!),
                    CustomPaint(
                      painter: FaceGuidePainter(
                        face: faceDetected,
                        imageSize: imageSize!,
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

    return Scaffold(
      body: Stack(
        children: [
          body,
          CameraHeader("SIGN UP", onBackPressed: _onBackPressed),
        ],
      ),
    );
  }
}
