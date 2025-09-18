// lib/pages/forgot_password_page.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';
import '../widgets/bottom_wave_clipper.dart';
import '../main.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  // Функция, которая просит Дворец отправить письмо-помощник.
  Future<void> _sendResetLink() async {
    // 1. Проверяем, ввел ли котенок свой email.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Показываем индикатор загрузки.
    setState(() => _isLoading = true);

    try {
      // 3. Просим Дворец отправить письмо.
      // Supabase сам позаботится о создании ссылки и отправке.
      await supabase.auth.resetPasswordForEmail(
        _emailController.text.trim(),
      );

      // 4. Если письмо успешно отправлено, хвалим котенка.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ссылка для сброса пароля отправлена на вашу почту!'),
            backgroundColor: Colors.green,
          ),
        );
        // Возвращаем котенка на страницу входа.
        Navigator.of(context).pop();
      }
    } on AuthException catch (error) {
      // 5. Если Дворец не нашел котенка с таким email, ругаемся.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      // 6. В любом случае убираем индикатор загрузки.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Наша верная волна
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: BottomWaveClipper(),
              child: Container(height: 200, color: primaryColor),
            ),
          ),
          // Контент страницы
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Spotter', textAlign: TextAlign.center, style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 50),
                    const Text('RESET PASSWORD', textAlign: TextAlign.center, style: headerTextStyle),
                    const SizedBox(height: 15),
                    Text(
                      'Введите email, и мы отправим вам ссылку для восстановления доступа.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 30),
                    
                    // Поле для ввода Email
                    TextFormField(
                      controller: _emailController,
                      decoration: formInputDecoration.copyWith(labelText: 'EMAIL'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Пожалуйста, введите email';
                        }
                        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Введите корректный email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 30),
                    
                    // Кнопка отправки
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendResetLink,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('SEND RESET LINK'),
                    ),
                    const SizedBox(height: 20),
                    
                    // Кнопка "Назад"
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Back to Login', style: TextStyle(color: textColor)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}