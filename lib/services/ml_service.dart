import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:app_face_recognition/locator.dart';
import 'package:app_face_recognition/services/face_detector_service.dart';
import 'package:camera/camera.dart';
import 'package:app_face_recognition/pages/db/databse_helper.dart';
import 'package:app_face_recognition/pages/models/user.model.dart';
import 'package:app_face_recognition/services/image_converter.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as imglib;

class MLService {
  Interpreter? _interpreter;
  final double threshold;
  List _predictedData = [];

  List get predictedData => _predictedData;

  MLService({this.threshold = 1.0});

  Future<void> initialize() async {
    try {
      Delegate? delegate;
      if (Platform.isAndroid) {
        delegate = GpuDelegateV2(); // Use default options
      } else if (Platform.isIOS) {
        delegate = GpuDelegate(); // iOS default
      }

      final options = InterpreterOptions();
      if (delegate != null) options.addDelegate(delegate);

      _interpreter = await Interpreter.fromAsset(
        'assets/mobilefacenet.tflite',
        options: options,
      );

      print('Interpreter initialized successfully');
    } catch (e) {
      print('Error initializing interpreter: $e');
      throw Exception('Failed to initialize TFLite interpreter');
    }
  }

  void setCurrentPrediction(CameraImage cameraImage, Face face) {
    if (_interpreter == null) throw Exception('Interpreter not initialized');
    final input = _preProcess(cameraImage, face).reshape([1, 112, 112, 3]);
    final output = List.generate(1, (_) => List.filled(192, 0.0));

    _interpreter!.run(input, output);

    _predictedData = List.from(output.reshape([192]));
  }

  Future<User?> predict() async {
    print('Predicted Data length: ${_predictedData.length}');
    print('Predicted Data sample: ${_predictedData.take(5)}');

    return _searchResult(_predictedData);
  }

  List _preProcess(CameraImage image, Face face) {
    final croppedImage = _cropFace(image, face);
    final resizedImage = imglib.copyResizeCropSquare(croppedImage, size: 112);
    return _imageToByteListFloat32(resizedImage);
  }

  imglib.Image _cropFace(CameraImage image, Face face) {
    final convertedImage = _convertCameraImage(image);
    final x = max(face.boundingBox.left - 10, 0).round();
    final y = max(face.boundingBox.top - 10, 0).round();
    final w =
        min(face.boundingBox.width + 20, convertedImage.width - x).round();
    final h =
        min(face.boundingBox.height + 20, convertedImage.height - y).round();

    return imglib.copyCrop(convertedImage, x: x, y: y, width: w, height: h);
  }

  imglib.Image _convertCameraImage(CameraImage image) {
    final img = convertToImage(image);
    return imglib.copyRotate(img, angle: -90);
  }

  List _imageToByteListFloat32(imglib.Image image) {
    final buffer = Float32List(1 * 112 * 112 * 3);
    int index = 0;

    for (int i = 0; i < 112; i++) {
      for (int j = 0; j < 112; j++) {
        final pixel = image.getPixel(j, i);

        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();

        buffer[index++] = (r - 128) / 128;
        buffer[index++] = (g - 128) / 128;
        buffer[index++] = (b - 128) / 128;
      }
    }

    return buffer.buffer.asFloat32List();
  }

  Future<User?> _searchResult(List predictedData) async {
    final db = DatabaseHelper.instance;
    final users = await db.queryAllUsers();
    print('Users count: ${users.length}');
    if (users.isNotEmpty)
      print('First user modelData length: ${users[0].modelData.length}');

    double minDist = double.infinity;
    User? matchedUser;

    for (final user in users) {
      final distance = _euclideanDistance(user.modelData, predictedData);
      print('Distance to user ${user.user}: $distance');
      if (distance < threshold && distance < minDist) {
        minDist = distance;
        matchedUser = user;
      }
    }

    return matchedUser;
  }

  Future<void> setCurrentPredictionFromPath(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final faceDetector = locator<FaceDetectorService>().faceDetector;

    final List<Face>? faces = await faceDetector?.processImage(inputImage);

    if (faces!.isEmpty) {
      throw Exception('No face found in the image.');
    }

    // Ambil wajah pertama
    final face = faces.first;

    // Baca image file sebagai imglib.Image
    final bytes = File(imagePath).readAsBytesSync();
    imglib.Image? image = imglib.decodeImage(bytes);

    if (image == null) {
      throw Exception('Failed to decode image.');
    }

    // Rotate jika diperlukan
    if (Platform.isAndroid) {
      image = imglib.copyRotate(image, angle: -90);
    }

    // Crop wajah
    final x = max(face.boundingBox.left - 10, 0).round();
    final y = max(face.boundingBox.top - 10, 0).round();
    final w = min(face.boundingBox.width + 20, image.width - x).round();
    final h = min(face.boundingBox.height + 20, image.height - y).round();

    final faceImage = imglib.copyCrop(image, x: x, y: y, width: w, height: h);

    // Resize
    final resizedImage = imglib.copyResizeCropSquare(faceImage, size: 112);
    final input = _imageToByteListFloat32(
      resizedImage,
    ).reshape([1, 112, 112, 3]);
    final output = List.generate(1, (_) => List.filled(192, 0.0));

    // Jalankan TFLite
    _interpreter?.run(input, output);
    _predictedData = List.from(output.reshape([192]));
  }

  double _euclideanDistance(List? a, List? b) {
    if (a == null || b == null) {
      throw ArgumentError('Input lists cannot be null');
    }

    double sum = 0.0;
    for (int i = 0; i < a.length; i++) {
      sum += pow((a[i] - b[i]), 2).toDouble();
    }

    return sqrt(sum);
  }

  void setPredictedData(List data) {
    _predictedData = data;
  }

  void dispose() {
    _interpreter?.close();
  }
}
