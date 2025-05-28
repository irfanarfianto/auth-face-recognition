import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastUtils {
  static bool _isShowing = false;

  static void show(
    String message, {
    ToastGravity gravity = ToastGravity.BOTTOM,
  }) async {
    if (_isShowing) return;

    _isShowing = true;

    await Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 16.0,
    );

    // Delay untuk reset flag sesuai durasi Toast.LENGTH_SHORT (~2 detik)
    Future.delayed(const Duration(seconds: 2), () {
      _isShowing = false;
    });
  }
}
