// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:spotter/main.dart';

// Импортируем все страницы, которые будут в навигации
import 'home_feed_widget.dart';
import 'search_page.dart';
import 'groups_page.dart';
import 'sections_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Индекс выбранной вкладки (начинаем с 0 - Лента)
  int _selectedIndex = 0;

  // Список всех виджетов/страниц для навигации
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeFeedWidget(), // Индекс 0
    const SearchPage(),     // Индекс 1
    const GroupsPage(),     // Индекс 2
    const SectionsPage(),   // Индекс 3

    // Используем УУИД в качестве параметра
    // Определение "своего" профиля берется исходя из юзера в свойстве auth
    // добавлена юзинг директива main.dart для возможности вызова supabase
    ProfilePage(userId: supabase.auth.currentUser!.id), // Индекс 4
  ];

  // Функция, которая вызывается при нажатии на вкладку
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // В качестве тела показываем виджет из списка по текущему индексу
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      // А вот и сама панель навигации
      bottomNavigationBar: BottomNavigationBar(
        // Иконки для каждой вкладки
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Лента',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Поиск',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Группы',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_basketball),
            label: 'Секции',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
        currentIndex: _selectedIndex, // Какая вкладка сейчас активна
        selectedItemColor: Theme.of(context).primaryColor, // Цвет активной иконки
        unselectedItemColor: Colors.grey, // Цвет неактивных иконок
        onTap: _onItemTapped, // Что делать при нажатии
        showUnselectedLabels: true, // Показывать подписи у неактивных иконок
        type: BottomNavigationBarType.fixed, // Чтобы все вкладки были видны
      ),
    );
  }
}