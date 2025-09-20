// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:spotter/main.dart';
import 'package:spotter/utils/constants.dart';

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
  final GlobalKey<ProfilePageState> _profilePageKey =
      GlobalKey<ProfilePageState>();

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
        items: <BottomNavigationBarItem>[
          _buildNavItem(icon: Icons.home, index: 0),
          _buildNavItem(icon: Icons.search, index: 1),
          _buildNavItem(icon: Icons.groups_outlined, index: 2), // Новая иконка
          _buildNavItem(icon: Icons.flash_on, index: 3), // Новая иконка
          _buildNavItem(icon: Icons.person_outline, index: 4),
        ],
        currentIndex: _selectedIndex, // Какая вкладка сейчас активна
        onTap: _onItemTapped, // Что делать при нажатии
        type: BottomNavigationBarType.fixed, // Чтобы все вкладки были видны
        showSelectedLabels: false, // Убираем подписи
        showUnselectedLabels: false,
        backgroundColor: const Color(0xFFF0F0E8), // Цвет фона как в макете
        elevation: 0, // Убираем тень
      ),
    );
  }

  // Вспомогательный метод для создания элемента навигации
  BottomNavigationBarItem _buildNavItem(
      {required IconData icon, required int index}) {
    final bool isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      label: '', // Пустой label
      icon: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[300] : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.black, // Все иконки черные
          size: 28,
        ),
      ),
    );
  }
}