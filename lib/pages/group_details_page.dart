import 'package:flutter/material.dart';

class GroupDetailsPage extends StatefulWidget {
  // Эта страница должна принимать ID группы, чтобы знать, что показывать.
  // final String groupId;
  // const GroupDetailsPage({super.key, required this.groupId});

  const GroupDetailsPage({super.key});

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TODO: Название группы будет загружаться из базы данных
        title: const Text('Детали группы'),
      ),
      body: const Center(
        child: Text(
          'Здесь будет вся информация о конкретной группе',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
// ---
// ЗАДАЧИ ДЛЯ КОМАНДЫ:
// 1. Научить страницу принимать `groupId` через аргументы навигации.
// 2. При загрузке страницы сделать запрос к Supabase, чтобы получить:
//    - Данные о группе из таблицы `groups` по `groupId`.
//    - Список участников из таблицы `group_members`, отфильтровав по `groupId`.
// 3. Сверстать страницу:
//    - Большая обложка группы сверху.
//    - Название и описание.
//    - Счетчик участников.
//    - Горизонтальный список аватарок участников.
// 4. Реализовать кнопку "Вступить в группу" / "Выйти из группы":
//    - Проверить, есть ли ID текущего котенка в списке участников.
//    - Если нет - показать кнопку "Вступить". При нажатии - добавить запись в `group_members`.
//    - Если есть - показать кнопку "Выйти". При нажатии - удалить запись из `group_members`.
//    - После нажатия состояние кнопки должно обновиться.
// ---