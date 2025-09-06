import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:lagbe_lagbe/home_page.dart';
import 'package:lottie/lottie.dart';

class AnimatedScWidget extends StatelessWidget {
  const AnimatedScWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: Center(child: Lottie.asset('assets/animated.json')),
      nextScreen: SplashScreen(),
      splashIconSize: 300,
      backgroundColor: Color.fromRGBO(246, 246, 246, 1),
      duration: 4000,
    );
  }
}
