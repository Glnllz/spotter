import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart'; // Наши цвета

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  // initState - это специальный метод, который вызывается один раз,
  // когда эта страница только-только появляется на экране.
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  // Асинхронная функция для проверки сессии и перенаправления.
  Future<void> _redirect() async {

    await Future.delayed(Duration.zero);

    final session = Supabase.instance.client.auth.currentSession;

    if (!mounted) return;

    if (session == null) {

      Navigator.of(context).pushReplacementNamed('/login');
    } else {

      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: CircularProgressIndicator(
          color: primaryColor, 
        ),
      ),
    );
  }
}