import 'dart:io';

import 'package:app_face_recognition/pages/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'home.dart';

class Profile extends StatelessWidget {
  static const String routeName = 'profile';
  static const String routePath = '/profile';

  final String username;
  final String imagePath;

  const Profile({super.key, required this.username, required this.imagePath});

  factory Profile.fromState(GoRouterState state) {
    final username = state.uri.queryParameters['username'] ?? 'Unknown';
    final imagePath = state.uri.queryParameters['imagePath'] ?? '';
    return Profile(username: username, imagePath: imagePath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black,
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(File(imagePath)),
                    ),
                  ),
                  margin: const EdgeInsets.all(20),
                  width: 50,
                  height: 50,
                ),
                Text(
                  'Hi $username!',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEFFC1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning_amber_outlined, size: 30),
                  const SizedBox(height: 10),
                  const Text(
                    '''If you think this project seems interesting and you want to contribute or need some help implementing it, don't hesitate and let’s get in touch!''',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.left,
                  ),
                  const Divider(height: 30),
                  InkWell(
                    onTap: () {
                      // TODO: Handle GitHub link
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.black,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.1),
                            blurRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'CONTRIBUTE',
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(width: 10),
                          FaIcon(FontAwesomeIcons.github, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            AppButton(
              text: "LOG OUT",
              onPressed: () {
                context.go(MyHomePage.routePath); // <- replace push with go
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              color: const Color(0xFFFF6161),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
