import 'package:flutter/material.dart';

// Эта страница будет StatefulWidget, так как нам нужно будет
// управлять текстовыми полями и состоянием загрузки.
class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание новой группы'),
      ),
      body: const Center(
        child: Text(
          'Здесь будет форма для создания новой стаи котят',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
// ---
// ЗАДАЧИ ДЛЯ КОМАНДЫ:
// 1. Сверстать форму с полями:
//    - TextFormField для "Названия группы".
//    - TextFormField (многострочный) для "Описания".
//    - Кнопка "Загрузить обложку" для выбора изображения.
//    - Большая кнопка "Создать группу".
// 2. Реализовать логику загрузки обложки в Supabase Storage.
// 3. При нажатии на "Создать группу":
//    - Сначала загрузить картинку (если выбрана) и получить ее URL.
//    - Затем создать новую запись в таблице `groups` в базе данных.
//      - В `name` и `description` записать данные из полей.
//      - В `cover_url` записать URL картинки.
//      - В `creator_id` записать ID текущего котенка (supabase.auth.currentUser!.id).
//    - **ВАЖНО:** Сразу после создания группы, создатель должен стать
//      ее участником. Создайте новую запись в таблице `group_members`,
//      связав ID нового котенка и ID только что созданной группы.
//    - После успеха - вернуться на предыдущую страницу (GroupsPage).
// ---