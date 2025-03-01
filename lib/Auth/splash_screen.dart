import 'package:fast_money_app/Auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> _checkLoginStatus() async {
    // Load your image assets or do any initialization if needed
    await Future.delayed(const Duration(seconds: 3));

    // Check if user is already logged in by checking SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();

    bool isLoggedIn = prefs.containsKey('name');

    if (isLoggedIn) {
      // Navigate to the MainScreen if logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } else {
      // Navigate to AuthPage if not logged in
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  LoginScreen()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus(); // Check login status during splash screen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/fast_money.jpg', width: 200, height: 200), // Your image asset
            SpinKitChasingDots(color: Colors.deepPurple[400]),
          ],
        ),
      ),
    );
  }
}
