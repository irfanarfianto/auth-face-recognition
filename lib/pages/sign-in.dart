import 'dart:async';

import 'package:app_face_recognition/locator.dart';
import 'package:app_face_recognition/pages/models/user.model.dart';
import 'package:app_face_recognition/pages/widgets/auth_button.dart';
import 'package:app_face_recognition/pages/widgets/camera_detection_preview.dart';
import 'package:app_face_recognition/pages/widgets/camera_header.dart';
import 'package:app_face_recognition/pages/widgets/signin_form.dart';
import 'package:app_face_recognition/pages/widgets/single_picture.dart';
import 'package:app_face_recognition/services/camera.service.dart';
import 'package:app_face_recognition/services/ml_service.dart';
import 'package:app_face_recognition/services/face_detector_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  SignInState createState() => SignInState();
}

class SignInState extends State<SignIn> {
  late final CameraService _cameraService;
  late final FaceDetectorService _faceDetectorService;
  late final MLService _mlService;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isPictureTaken = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _cameraService = locator<CameraService>();
    _faceDetectorService = locator<FaceDetectorService>();
    _mlService = locator<MLService>();
    _start();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _mlService.dispose();
    _faceDetectorService.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _isInitializing = true);
    await _mlService.initialize();
    await _cameraService.initialize();
    setState(() => _isInitializing = false);
    _startImageStream();
  }

  void _startImageStream() {
    bool processing = false;

    _cameraService.cameraController?.startImageStream((
      CameraImage image,
    ) async {
      if (processing) return; // Prevent overlapping processing
      processing = true;

      await _processCameraImage(image);

      processing = false;
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    await _faceDetectorService.detectFacesFromStream(image);
    if (_faceDetectorService.faceDetected) {
      _mlService.setCurrentPrediction(image, _faceDetectorService.faces[0]);
    }
    if (mounted) setState(() {});
  }

  Future<void> _takePicture() async {
    if (_faceDetectorService.faceDetected) {
      await _cameraService.takePicture();
      if (mounted) setState(() => _isPictureTaken = true);
    } else {
      await showDialog(
        context: context,
        builder:
            (context) => const AlertDialog(content: Text('No face detected!')),
      );
    }
  }

  void _onBackPressed() {
    Navigator.of(context).pop();
  }

  void _reload() {
    if (mounted) setState(() => _isPictureTaken = false);
    _start();
  }

  Future<void> _onAuthButtonTap() async {
    await _takePicture();

    if (_faceDetectorService.faceDetected) {
      User? user = await _mlService.predict();
      final bottomSheetController = _scaffoldKey.currentState?.showBottomSheet(
        (context) => signInSheet(user: user),
      );
      bottomSheetController?.closed.whenComplete(_reload);
    }
  }

  Widget _buildBody() {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_isPictureTaken && _cameraService.imagePath != null) {
      return SinglePicture(imagePath: _cameraService.imagePath!);
    }
    return CameraDetectionPreview();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          _buildBody(),
          CameraHeader("LOGIN", onBackPressed: _onBackPressed),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          !_isPictureTaken ? AuthButton(onTap: _onAuthButtonTap) : null,
    );
  }

  Widget signInSheet({required User? user}) {
    if (user == null) {
      return Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(20),
        child: const Text('User not found 😞', style: TextStyle(fontSize: 20)),
      );
    }
    return SignInSheet(user: user);
  }
}
