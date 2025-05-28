import 'dart:async';
import 'package:app_face_recognition/utils/toast.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

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

class SignIn extends StatefulWidget {
  static const String routeName = 'signin';
  static const String routePath = '/signin';
  const SignIn({super.key});

  @override
  State<SignIn> createState() => SignInState();
}

class SignInState extends State<SignIn> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late final CameraService _cameraService;
  late final FaceDetectorService _faceDetectorService;
  late final MLService _mlService;

  bool _isPictureTaken = false;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _cameraService = locator<CameraService>();
    _faceDetectorService = locator<FaceDetectorService>();
    _mlService = locator<MLService>();

    _initializeServices();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _mlService.dispose();
    _faceDetectorService.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    setState(() => _isInitializing = true);
    try {
      await _mlService.initialize();
      await _cameraService.initialize();
      _startImageStream();
    } catch (e) {
      debugPrint("Initialization failed: $e");
    } finally {
      if (mounted) setState(() => _isInitializing = false);
    }
  }

  void _startImageStream() {
    final controller = _cameraService.cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    bool processing = false;

    controller.startImageStream((CameraImage image) async {
      if (processing) return;
      processing = true;

      await _processCameraImage(image);

      processing = false;
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    await _faceDetectorService.detectFacesFromStream(image);

    if (_faceDetectorService.faceDetected) {
      _mlService.setCurrentPrediction(image, _faceDetectorService.faces.first);
    }

    if (mounted) setState(() {});
  }

  Future<User?> _takePictureAndPredict() async {
    if (_faceDetectorService.faceDetected) {
      await _cameraService.takePicture();
      if (!mounted) return null;

      setState(() => _isPictureTaken = true);

      return await _mlService.predict();
    } else {
      ToastUtils.show("No face detected. Please try again.");
      return null;
    }
  }

  void _onBackPressed() {
    Navigator.of(context).pop();
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _isPictureTaken = false);
    _startImageStream();
  }

  Future<void> _onAuthButtonTap() async {
    final user = await _takePictureAndPredict();

    if (user != null) {
      final bottomSheetController = _scaffoldKey.currentState?.showBottomSheet(
        (_) => _buildSignInSheet(user: user),
      );

      bottomSheetController?.closed.whenComplete(_reload);
    }
  }

  Widget _buildSignInSheet({required User? user}) {
    if (user == null) {
      return Container(
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(20),
        child: const Text('User not found 😞', style: TextStyle(fontSize: 20)),
      );
    }
    return SignInSheet(user: user);
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
}
