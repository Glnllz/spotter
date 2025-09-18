// lib/pages/splash_page.dart

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
    // Мы сразу же запускаем нашу проверку и перенаправление.
    _redirect();
  }

  // Асинхронная функция для проверки сессии и перенаправления.
  Future<void> _redirect() async {
    // Мы ждем хотя бы один кадр, чтобы убедиться, что виджет
    // полностью загрузился и готов к навигации. Это best practice.
    await Future.delayed(Duration.zero);

    // Проверяем, есть ли у котенка сохраненный ключ от Дворца (сессия).
    // `currentSession` вернет данные сессии, если она есть, или `null`, если нет.
    final session = Supabase.instance.client.auth.currentSession;

    // `mounted` - это проверка, существует ли еще наш виджет на экране.
    // Она нужна, чтобы избежать ошибок, если котенок закроет приложение
    // прямо во время этой проверки.
    if (!mounted) return;

    // Если ключа нет (`session` равен `null`), котенок не авторизован.
    if (session == null) {
      // Отправляем его на страницу входа.
      // `pushReplacementNamed` заменяет текущий Splash-экран на новый,
      // чтобы котенок не смог нажать "назад" и вернуться сюда.
      Navigator.of(context).pushReplacementNamed('/login');
    } else {
      // Если ключ есть, ура! Котенок уже в системе.
      // Отправляем его прямиком на главную страницу.
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Пока идет проверка, котенок видит этот простой экран загрузки.
    return const Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: CircularProgressIndicator(
          color: primaryColor, // Сделаем крутилку нашего фирменного цвета
        ),
      ),
    );
  }
}