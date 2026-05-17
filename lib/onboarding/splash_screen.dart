import 'dart:async';
import 'package:flutter/material.dart';
import '../auth/login_page.dart';
import '../screens/connection_setup.dart';
import '../services/supabase.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final loggedIn = await SupabaseService().getLoginState();

      Timer(const Duration(seconds: 3), () {
        if (loggedIn) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const ConnectionSetupPage()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff0F172A), Color(0xff1E293B)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home, size: size.width * 0.25, color: Colors.blue),
              SizedBox(height: size.height * 0.03),
              Text(
                "Smart Home",
                style: TextStyle(
                  fontSize: size.width * 0.07,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: size.height * 0.02),
              const CircularProgressIndicator(color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }
}
