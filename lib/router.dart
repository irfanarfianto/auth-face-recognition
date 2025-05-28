import 'package:app_face_recognition/pages/profile.dart';
import 'package:app_face_recognition/pages/sign-in.dart';
import 'package:app_face_recognition/pages/sign-up.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/home.dart';

final GoRouter router = GoRouter(
  initialLocation: MyHomePage.routePath,
  routes: [
    GoRoute(
      path: MyHomePage.routePath,
      name: MyHomePage.routeName,
      builder: (context, state) => const MyHomePage(),
    ),
    GoRoute(
      path: SignIn.routePath,
      name: SignIn.routeName,
      builder: (context, state) => const SignIn(),
    ),
    GoRoute(
      path: SignUp.routePath,
      name: SignUp.routeName,
      builder: (context, state) => const SignUp(),
    ),
    GoRoute(
      path: Profile.routePath,
      name: Profile.routeName,
      pageBuilder: (context, state) {
        return MaterialPage(
          key: state.pageKey,
          child: Profile.fromState(state),
        );
      },
    ),
  ],
);
