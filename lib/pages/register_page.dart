// lib/pages/register_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';
import '../widgets/bottom_wave_clipper.dart';
import '../main.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // --- Переменные для онбординга ---
  String? _selectedSkillLevel;
  final Set<String> _selectedInterests = {};

  final List<String> _availableSkillLevels = ['Новичок', 'Любитель', 'Профи'];
  final List<String> _availableInterests = [
    'Футбол', 'Баскетбол', 'Теннис', 'Бег', 'Йога', 'Плавание', 'Велоспорт', 'Зал'
  ];

  bool _isPasswordObscured = true;
  bool _isConfirmPasswordObscured = true;
  bool _isLoading = false;

  Future<void> _signUp() async {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    // --- Валидация интересов ---
    if (_selectedInterests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите хотя бы один интерес'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // --- Добавляем данные онбординга в `data` ---
      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': _fullNameController.text.trim(),
          'skill_level': _selectedSkillLevel,
          // Сохраняем интересы как строку, разделенную запятыми
          'interests': _selectedInterests.join(', '),
        },
      );
      
      final newUserId = response.user?.id;
      if (newUserId == null) {
        throw 'Не удалось создать пользователя.';
      }

      // --- Добавляем все данные в таблицу profiles ---
      await supabase.from('profiles').insert({
        'id': newUserId,
        'full_name': _fullNameController.text.trim(),
        'skill_level': _selectedSkillLevel,
        'interests': _selectedInterests.join(', '),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Успешно! Если нужно, подтвердите почту.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } on AuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (error) {
        if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Произошла непредвиденная ошибка: $error'),
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
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipPath(
              clipper: BottomWaveClipper(),
              child: Container(height: 200, color: primaryColor),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Spotter',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: textColor),
                    ),
                    const SizedBox(height: 50),
                    const Text('WELCOME', textAlign: TextAlign.center, style: headerTextStyle),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: formInputDecoration.copyWith(labelText: 'FULL NAME'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Пожалуйста, введите ваше имя';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: formInputDecoration.copyWith(labelText: 'EMAIL'),
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
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
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isPasswordObscured,
                      decoration: formInputDecoration.copyWith(
                        labelText: 'PASSWORD',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordObscured = !_isPasswordObscured;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите пароль';
                        }
                        if (value.length < 6) {
                          return 'Пароль должен быть не менее 6 символов';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _isConfirmPasswordObscured,
                      decoration: formInputDecoration.copyWith(
                        labelText: 'CONFIRM PASSWORD',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordObscured ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordObscured = !_isConfirmPasswordObscured;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Пароли не совпадают';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: _selectedSkillLevel,
                      decoration: formInputDecoration.copyWith(labelText: 'УРОВЕНЬ ПОДГОТОВКИ'),
                      items: _availableSkillLevels.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedSkillLevel = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Выберите ваш уровень' : null,
                    ),
                    const SizedBox(height: 20),
                    const Text('ИНТЕРЕСЫ', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _availableInterests.map((interest) {
                        final isSelected = _selectedInterests.contains(interest);
                        return FilterChip(
                          label: Text(interest),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedInterests.add(interest);
                              } else {
                                _selectedInterests.remove(interest);
                              }
                            });
                          },
                          selectedColor: primaryColor.withOpacity(0.8),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('CREATE'),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'Do you have an account already? ',
                          style: const TextStyle(color: textColor),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Sign In',
                              style: const TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.of(context).pushReplacementNamed('/login');
                                },
                            ),
                          ],
                        ),
                      ),
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