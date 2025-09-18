import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование профиля'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // TODO: Реализовать сохранение данных
            },
          )
        ],
      ),
      body: const Center(
        child: Text(
          'Здесь котенок сможет изменить информацию о себе',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
// ---
// ЗАДАЧИ ДЛЯ КОМАНДЫ:
// 1. При загрузке страницы сделать запрос к таблице `profiles`, чтобы
//    получить текущие данные котенка (по его ID).
// 2. Сверстать форму, поля которой уже заполнены текущими данными:
//    - Аватар с кнопкой "Изменить фото".
//    - TextFormField для `full_name`.
//    - TextFormField для `about`.
//    - Выбор интересов (`interests`) в виде кликабельных чипов.
//    - Выбор уровня подготовки (`skill_level`) в виде радио-кнопок.
// 3. При нажатии на кнопку "Сохранить" (в AppBar):
//    - Если было выбрано новое фото, загрузить его в Supabase Storage и получить URL.
//    - Отправить запрос `update` к таблице `profiles`, чтобы обновить
//      все поля новыми данными из формы.
//    - После успеха - вернуться на страницу профиля.
// ---