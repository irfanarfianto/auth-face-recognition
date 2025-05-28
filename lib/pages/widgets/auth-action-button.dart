import 'package:app_face_recognition/locator.dart';
import 'package:app_face_recognition/pages/db/databse_helper.dart';
import 'package:app_face_recognition/pages/models/user.model.dart';
import 'package:app_face_recognition/pages/profile.dart';
import 'package:app_face_recognition/pages/widgets/app_button.dart';
import 'package:app_face_recognition/services/camera.service.dart';
import 'package:app_face_recognition/services/ml_service.dart';
import 'package:app_face_recognition/utils/toast.dart';
import 'package:flutter/material.dart';
import '../home.dart';
import 'app_text_field.dart';

class AuthActionButton extends StatefulWidget {
  const AuthActionButton({
    super.key,
    required this.onPressed,
    required this.isLogin,
    required this.reload,
  });
  final Function onPressed;
  final bool isLogin;
  final Function reload;
  @override
  _AuthActionButtonState createState() => _AuthActionButtonState();
}

class _AuthActionButtonState extends State<AuthActionButton> {
  final MLService _mlService = locator<MLService>();
  final CameraService _cameraService = locator<CameraService>();

  final TextEditingController _userTextEditingController =
      TextEditingController(text: '');
  final TextEditingController _passwordTextEditingController =
      TextEditingController(text: '');

  User? predictedUser;

  Future _signUp(context) async {
    DatabaseHelper databaseHelper = DatabaseHelper.instance;
    List predictedData = _mlService.predictedData;
    String user = _userTextEditingController.text;
    String password = _passwordTextEditingController.text;
    User userToSave = User(
      user: user,
      password: password,
      modelData: predictedData,
    );
    await databaseHelper.insert(userToSave);
    _mlService.setPredictedData([]);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (BuildContext context) => MyHomePage()),
    );
  }

  Future _signIn(context) async {
    String password = _passwordTextEditingController.text;
    if (predictedUser!.password == password) {
      context.pushNamed(
        Profile.routeName,
        queryParameters: {
          'username': predictedUser!.user,
          'imagePath': _cameraService.imagePath!,
        },
      );
    } else {
      ToastUtils.show("Password Salah",);
    }
  }

  Future<User?> _predictUser() async {
    User? userAndPass = await _mlService.predict();
    return userAndPass;
  }

  Future onTap() async {
    try {
      bool faceDetected = await widget.onPressed();
      if (faceDetected) {
        if (widget.isLogin) {
          var user = await _predictUser();
          if (user != null) {
            predictedUser = user;
          }
        }
        PersistentBottomSheetController bottomSheetController = Scaffold.of(
          context,
        ).showBottomSheet((context) => signSheet(context));
        bottomSheetController.closed.whenComplete(() => widget.reload());
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.blue[200],
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.blue.withOpacity(0.1),
              blurRadius: 1,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        width: MediaQuery.of(context).size.width * 0.8,
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('CAPTURE', style: TextStyle(color: Colors.white)),
            SizedBox(width: 10),
            Icon(Icons.camera_alt, color: Colors.white),
          ],
        ),
      ),
    );
  }

  signSheet(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          widget.isLogin && predictedUser != null
              ? Text(
                'Welcome back, ${predictedUser!.user}.',
                style: TextStyle(fontSize: 20),
              )
              : widget.isLogin
              ? Text('User not found 😞', style: TextStyle(fontSize: 20))
              : Container(),
          Column(
            children: [
              !widget.isLogin
                  ? AppTextField(
                    controller: _userTextEditingController,
                    labelText: "Your Name",
                  )
                  : Container(),
              SizedBox(height: 10),
              widget.isLogin && predictedUser == null
                  ? Container()
                  : AppTextField(
                    controller: _passwordTextEditingController,
                    labelText: "Password",
                    isPassword: true,
                  ),
              SizedBox(height: 10),
              Divider(),
              SizedBox(height: 10),
              widget.isLogin && predictedUser != null
                  ? AppButton(
                    text: 'LOGIN',
                    onPressed: () async {
                      _signIn(context);
                    },
                    icon: Icon(Icons.login, color: Colors.white),
                  )
                  : !widget.isLogin
                  ? AppButton(
                    text: 'SIGN UP',
                    onPressed: () async {
                      await _signUp(context);
                    },
                    icon: Icon(Icons.person_add, color: Colors.white),
                  )
                  : Container(),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
