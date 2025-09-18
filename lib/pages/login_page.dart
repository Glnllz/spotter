// lib/pages/login_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart'; // Наши цвета и стили
import '../widgets/bottom_wave_clipper.dart'; // Наша волна
import '../main.dart'; // Чтобы получить доступ к 'supabase'

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // Функция для входа котенка.
  Future<void> _signIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      // Отправляем голубя с данными для входа.
      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Если Дворец пустил, отправляем котенка на главный экран.
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on AuthException catch (error) {
      // Если Дворец не пустил, показываем ошибку.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Наша верная зеленая волна внизу.
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: BottomWaveClipper(),
              child: Container(
                height: 200,
                color: primaryColor,
              ),
            ),
          ),
          // Основной контент страницы.
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- Логотип ---
                  const Text(
                    'Spotter',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // --- Заголовок "SIGN IN" ---
                  const Text('SIGN IN',
                      textAlign: TextAlign.center, style: headerTextStyle),
                  const SizedBox(height: 30),

                  // --- Поля ввода (такие же, как на регистрации) ---
                  TextFormField(
                    controller: _emailController,
                    decoration: formInputDecoration.copyWith(labelText: 'EMAIL'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: formInputDecoration.copyWith(labelText: 'PASSWORD'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 30),

                  // --- Кнопка "LOG IN" ---
                  ElevatedButton(
                    onPressed: _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'LOG IN',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                  const SizedBox(height: 20),

                  // --- Ссылки "Создать аккаунт" и "Сбросить пароль" ---
                  Column(
                    children: [
                      TextButton(
                        onPressed: () {
                          // Переход на страницу регистрации
                          Navigator.of(context).pushReplacementNamed('/register');
                        },
                        child: const Text(
                          'No account? Create now',
                          style: TextStyle(color: textColor),
                        ),
                      ),
                     TextButton(
  // БЫЛО: onPressed: () { /* TODO: */ },
  // СТАЛО:
  onPressed: () {
    // Эта команда говорит: "Открой страницу по адресу '/forgot-password'".
    // Мы используем pushNamed, чтобы котенок мог нажать "назад"
    // и вернуться на страницу входа.
    Navigator.of(context).pushNamed('/forgot-password');
  },
  child: Text(
    'Reset password',
    style: TextStyle(color: Colors.grey[600]),
  ),
),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}