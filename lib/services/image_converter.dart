import 'package:image/image.dart' as imglib;
import 'package:camera/camera.dart';

imglib.Image convertToImage(CameraImage image) {
  try {
    if (image.format.group == ImageFormatGroup.yuv420) {
      return _convertYUV420(image);
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      return _convertBGRA8888(image);
    }
    throw Exception('Image format not supported');
  } catch (e) {
    rethrow;
  }
}

imglib.Image _convertBGRA8888(CameraImage image) {
  final bytes = image.planes[0].bytes;
  return imglib.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: bytes.buffer,
    order: imglib.ChannelOrder.bgra,
    format: imglib.Format.uint8,
  );
}

imglib.Image _convertYUV420(CameraImage image) {
  final width = image.width;
  final height = image.height;
  final img = imglib.Image(width: width, height: height);

  final uvRowStride = image.planes[1].bytesPerRow;
  final uvPixelStride = image.planes[1].bytesPerPixel!;

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);

      final int yp = image.planes[0].bytes[y * width + x];
      final int up = image.planes[1].bytes[uvIndex];
      final int vp = image.planes[2].bytes[uvIndex];

      final int r = (yp + vp * 1.370705).round().clamp(0, 255);
      final int g = (yp - up * 0.337633 - vp * 0.698001).round().clamp(0, 255);
      final int b = (yp + up * 1.732446).round().clamp(0, 255);

      img.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  return img;
}
