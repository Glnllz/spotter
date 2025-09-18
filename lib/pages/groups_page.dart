import 'package:flutter/material.dart';

class GroupsPage extends StatelessWidget {
  const GroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Группы по интересам'),
      ),
      body: const Center(
        child: Text(
          'Здесь котята находят и создают свои стаи',
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Переход на страницу создания группы
          Navigator.of(context).pushNamed('/create-group');
        },
        child: const Icon(Icons.add),
      ),
    );
    // ---
    // ЗАДАЧИ ДЛЯ КОМАНДЫ:
    // 1. Реализовать переключатель (TabBar) с двумя вкладками: "Мои группы" и "Все группы".
    // 2. Для "Всех групп": сделать запрос к таблице `groups` и показать все в списке.
    // 3. Для "Моих групп": сделать сложный запрос с JOIN'ом. Нужно получить
    //    все группы, где ID текущего котенка есть в таблице `group_members`.
    // 4. Создать красивую карточку для отображения группы (обложка, название, кол-во участников).
    // 5. FAB-кнопка (+) должна вести на новую страницу `/create-group`, страница создана там код пишите.
    // 6. Нажатие на карточку группы ведет на `/group-details`, тоже создана.
    // ---
  }
}