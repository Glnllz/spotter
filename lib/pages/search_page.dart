import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск партнеров'),
      ),
      body: const Center(
        child: Text(
          'Здесь котята ищут себе друзей для тренировок',
        ),
      ),
    );
    // ---
    // ЗАДАЧИ ДЛЯ КОМАНДЫ:
    // 1. Реализовать строку поиска (TextField) для поиска по имени.
    // 2. Сделать кнопку "Фильтры", которая открывает модальное окно (BottomSheet).
    // 3. В фильтрах должны быть:
    //    - Выбор интересов (чипы/checkbox'ы).
    //    - Уровень подготовки (радио-кнопки).
    // 4. При поиске или применении фильтров делать запрос к таблице `profiles`
    //    в Supabase, используя `.ilike()` для имени и `.in()` для интересов.
    // 5. Отображать результаты в виде сетки или списка карточек пользователей.
    // 6. Нажатие на карточку ведет на `ProfilePage`.
    // ---
  }
}