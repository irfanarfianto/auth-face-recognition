import 'package:app_face_recognition/locator.dart';
import 'package:app_face_recognition/pages/models/user.model.dart';
import 'package:app_face_recognition/pages/profile.dart';
import 'package:app_face_recognition/pages/widgets/app_button.dart';
import 'package:app_face_recognition/pages/widgets/app_text_field.dart';
import 'package:app_face_recognition/services/camera.service.dart';
import 'package:app_face_recognition/utils/toast.dart';
import 'package:flutter/material.dart';

class SignInSheet extends StatelessWidget {
  SignInSheet({super.key, required this.user});
  final User user;

  final _passwordController = TextEditingController();
  final _cameraService = locator<CameraService>();

  Future _signIn(context, user) async {
    if (user.password == _passwordController.text) {
      context.pushNamed(
        Profile.routeName,
        queryParameters: {
          'username': user.user,
          'imagePath': _cameraService.imagePath!,
        },
      );
    } else {
      ToastUtils.show("Password salah");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Welcome back, ${user.user}.', style: TextStyle(fontSize: 20)),
          Column(
            children: [
              SizedBox(height: 10),
              AppTextField(
                controller: _passwordController,
                labelText: "Password",
                isPassword: true,
              ),
              SizedBox(height: 10),
              Divider(),
              SizedBox(height: 10),
              AppButton(
                text: 'LOGIN',
                onPressed: () async {
                  _signIn(context, user);
                },
                icon: Icon(Icons.login, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
