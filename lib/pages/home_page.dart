// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:spotter/main.dart';

// Импортируем все страницы, которые будут в навигации
import 'home_feed_widget.dart';
import 'search_page.dart';
import 'groups_page.dart';
import 'sections_page.dart';

// Импортируем profile_page.dart
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  // Используем публичный тип состояния
  final GlobalKey<ProfilePageState> _profilePageKey = GlobalKey<ProfilePageState>();

  // Обновляем список виджетов, передаём key
  late final List<Widget> _widgetOptions;

  @override
  void initState() {
    super.initState();
    _widgetOptions = <Widget>[
      const HomeFeedWidget(),
      const SearchPage(),
      const GroupsPage(),
      const SectionsPage(),
      ProfilePage(
        key: _profilePageKey,
        initialUserId: supabase.auth.currentUser!.id,
      ),
    ];
  }

  // Функция, которая вызывается при нажатии на вкладку
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Если нажали на вкладку "Профиль" (индекс 4), обновляем профиль
    if (index == 4) {
      _profilePageKey.currentState?.showMyProfile();
    }
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