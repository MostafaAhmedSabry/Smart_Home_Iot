import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_home/services/supabase.dart';
import 'onboarding/splash_screen.dart';
import 'screens/mqtt_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SupabaseService().init(
    'https://gprhgkgxcdefzxffclhi.supabase.co',
    'sb_publishable_lNOar9l078bhCNyXD6pbLA_bEr-7Gx9',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MqttProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Home',
      theme: ThemeData.dark(),
      home: const SplashScreen(),
    );

  }
}
