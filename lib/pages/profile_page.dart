// lib/pages/profile_page.dart

import 'package:flutter/material.dart';
import '../main.dart'; // для кнопки выхода

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Эта страница должна принимать userId как аргумент,
    // чтобы понимать, чей профиль показывать - свой или чужой.
    final myProfile = true; // Временная заглушка

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          // Показываем кнопку "Выход" только в своем профиле
          if (myProfile)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await supabase.auth.signOut();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (route) => false);
              },
            )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Здесь будет детальная информация о котенке',
            ),
            const SizedBox(height: 20),
            if (myProfile)
              ElevatedButton(
                onPressed: () {
                  // TODO: Переход на страницу редактирования профиля
                },
                child: const Text('Редактировать профиль'),
              )
            else
              ElevatedButton(
                onPressed: () {
                  // TODO: Реализовать функцию "Написать сообщение"
                },
                child: const Text('Написать сообщение'),
              )
          ],
        ),
      ),
    );
  } 
  // ---
  // ЗАДАЧИ ДЛЯ КОМАНДЫ:
  // 1. Научить страницу принимать `userId` через аргументы навигации.
  // 2. Сделать запрос к таблице `profiles` по `userId`, чтобы получить все данные.
  // 3. Сверстать красивый профиль: аватар, имя, био, теги интересов, уровень.
  // 4. Реализовать логику: если `userId` совпадает с ID текущего котенка
  //    (supabase.auth.currentUser!.id), то показываем кнопку "Редактировать".
  // 5. Если `userId` чужой - показываем кнопку "Написать сообщение".
  // 6. Сделать запрос к `group_members`, чтобы показать, в каких группах состоит котенок.
  // ---
}