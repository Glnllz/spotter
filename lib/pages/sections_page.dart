import 'package:flutter/material.dart';

class SectionsPage extends StatelessWidget {
  const SectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Университетские секции'),
      ),
      body: const Center(
        child: Text(
          'Здесь котята смотрят расписание и записываются на официальные занятия',
        ),
      ),
    );
    // ---
    // ЗАДАЧИ ДЛЯ КОМАНДЫ:
    // 1. Реализовать календарь или фильтр по дням недели.
    // 2. Сделать запрос к таблице `section_events` в Supabase, фильтруя по выбранной дате.
    // 3. Создать карточку для секции (название, время, место, тренер, кол-во свободных мест).
    // 4. Отобразить все в виде списка.
    // 5. Нажатие на карточку ведет на `/section-details` страница создана там пишете код.
    // ---
  }
}