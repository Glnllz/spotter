import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/create_group_page.dart';
import 'pages/group_details_page.dart';
import 'pages/section_details_page.dart';
import 'pages/edit_profile_page.dart';
import 'utils/constants.dart';


Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bpagowdxdhbpxndkcvlt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJwYWdvd2R4ZGhicHhuZGtjdmx0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MzgzMDgsImV4cCI6MjA3MzUxNDMwOH0.J6b6S9RKtYkh5-PVRfhoU9E30SvUbfGbutmES_jmwkY',
  );

  runApp(const MyApp());
}

// Это главный виджет-контейнер для всего приложения.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MaterialApp - это основа, которая дает нам навигацию, темы и т.д.
    return MaterialApp(
      // Убираем надоедливую надпись "Debug" в углу.
      debugShowCheckedModeBanner: false,
      title: 'Spotter',
      // Здесь мы применяем наши фирменные цвета ко всему приложению.
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: backgroundColor,
        // Устанавливаем стиль для всех кнопок в приложении.
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white, // Цвет текста на кнопке
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      
      // initialRoute - это "входная дверь". Мы всегда начинаем со Splash Page,
      // а она уже решит, куда вести котенка дальше.
      initialRoute: '/',

      // routes - это карта всех комнат (страниц) в нашем приложении.
      // Мы даем каждой странице уникальный адрес (например, '/login').
      routes: {
        '/': (context) => const SplashPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/create-group': (context) => const CreateGroupPage(),
         '/group-details': (context) {
          final arguments = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final groupId = arguments?['groupId'] as String?;
          
          if (groupId == null) {
            return const Scaffold(
              body: Center(child: Text('Ошибка: не указан ID группы')),
            );
          }
          
          return GroupDetailsPage(groupId: groupId);
        },
        // В главном файле (где routes)
        '/section-details': (context) {
          final sectionEventId = ModalRoute.of(context)?.settings.arguments as String?;
          if (sectionEventId == null) {
            return const Scaffold(
              body: Center(child: Text('Ошибка: не указан ID события')),
            );
          }
          return SectionDetailsPage(sectionEventId: sectionEventId);
        },
        '/edit-profile': (context) => const EditProfilePage(),
      },
    );
  }
}

final supabase = Supabase.instance.client;