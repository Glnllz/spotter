import 'package:flutter/material.dart';
import '../main.dart'; // Импортируем для доступа к supabase

// Это временная заглушка для главной страницы.
// Здесь будет лента, поиск и все остальное.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Главная'),
        actions: [
          // Добавим кнопку выхода, чтобы можно было легко тестировать вход/выход.
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Команда "Дворец, я ухожу".
              await supabase.auth.signOut();

              // Отправляем котенка обратно на страницу входа.
              // pushAndRemoveUntil удаляет все экраны "под" новым,
              // чтобы котенок не мог вернуться на главный экран кнопкой "назад".
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          )
        ],
      ),
      body: const Center(
        child: Text('Привет, котенок! Ты вошел в свой домик.'),
      ),
    );
  }
}