import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:face_recognition/screens/home_page.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      splash: splash(),
      backgroundColor: Colors.black,
      splashIconSize: MediaQuery.of(context).size.height,
      centered: false,
      nextScreen: const HomePage(),
      splashTransition: SplashTransition.fadeTransition,
    );
  }

  Widget splash() {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          Image.asset(
            'splash-min.jpg',
          ),
          Padding(
              padding: EdgeInsets.only(top: size.height * 0.1),
              child: const Text(
                'FaceSec',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic),
              )),
          Padding(
            padding: EdgeInsets.all(size.height * 0.025),
            child: const Text(
              'Criminal Detector',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}
