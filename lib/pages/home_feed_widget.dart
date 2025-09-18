import 'package:flutter/material.dart';

// Этот виджет будет отвечать за отображение ленты на главной странице.
class HomeFeedWidget extends StatelessWidget {
  const HomeFeedWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotter'),
        centerTitle: false,
      ),
      body: const Center(
        child: Text(
          'Здесь будет лента рекомендаций для котенка:\n'
          '- Карточки с пользователями по интересам\n'
          '- Карточки с популярными группами\n'
          '- Карточки с ближайшими секциями',
          textAlign: TextAlign.center,
        ),
      ),
    );
    // ---
    // ЗАДАЧИ ДЛЯ КОМАНДЫ:
    // 1. Сделать запрос к Supabase, чтобы получить данные для ленты.
    //    - profiles: отфильтровать по `interests` текущего пользователя.
    //    - groups: отсортировать по количеству участников.
    //    - section_events: отфильтровать по ближайшей дате.
    // 2. Создать красивые виджеты-карточки для каждого типа контента.
    // 3. Собрать все в один прокручиваемый список (ListView.builder).
    // 4. Каждая карточка должна быть кликабельной и вести на соответствующую
    //    страницу деталей (профиль, группа, секция).
    // ---
  }
}