// lib/pages/search_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spotter/main.dart';
import 'package:spotter/pages/profile_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];

  // --- Состояние фильтров ---
  // Используем Set для хранения уникальных интересов
  Set<String> _selectedInterests = {};
  String? _selectedSkillLevel;

  // Возможные значения для фильтров (в реальном приложении их можно загружать с сервера)
  final List<String> _availableInterests = [
    'Футбол', 'Баскетбол', 'Теннис', 'Бег', 'Йога', 'Плавание', 'Велоспорт'
  ];
  final List<String> _availableSkillLevels = ['Новичок', 'Любитель', 'Профи'];

  @override
  void initState() {
    super.initState();
    // Слушатель для текстового поля для поиска с задержкой (debounce)
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Вызывается при изменении текста в поле поиска
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  // Основная функция для выполнения запроса к Supabase
  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserId = supabase.auth.currentUser?.id;
      // Начинаем строить запрос
      var query = supabase.from('profiles').select().not('id', 'eq', currentUserId!);

      // 1. Фильтр по имени
      final searchQuery = _searchController.text.trim();
      if (searchQuery.isNotEmpty) {
        query = query.ilike('full_name', '%$searchQuery%');
      }

      // 2. Фильтр по уровню подготовки
      if (_selectedSkillLevel != null) {
        query = query.eq('skill_level', _selectedSkillLevel!);
      }
      
      // 3. Фильтр по интересам
      // Создаем строку для 'or' фильтра: "interests.ilike.%Футбол%,interests.ilike.%Бег%"
      if (_selectedInterests.isNotEmpty) {
        final interestFilters = _selectedInterests
            .map((interest) => 'interests.ilike.%$interest%')
            .join(',');
        query = query.or(interestFilters);
      }

      final data = await query;
      
      setState(() {
        _searchResults = List<Map<String, dynamic>>.from(data);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка поиска: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Функция для открытия модального окна с фильтрами
  void _showFilterBottomSheet() {
    // Временные переменные, чтобы изменения применялись только по кнопке "Применить"
    Set<String> tempSelectedInterests = Set.from(_selectedInterests);
    String? tempSkillLevel = _selectedSkillLevel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Позволяет занимать больше половины экрана
      builder: (context) {
        // StatefulBuilder нужен, чтобы обновлять состояние только внутри BottomSheet
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Wrap(
                runSpacing: 16,
                children: [
                  const Text('Фильтры', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  
                  // --- Фильтр по интересам ---
                  const Text('Интересы', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: _availableInterests.map((interest) {
                      return FilterChip(
                        label: Text(interest),
                        selected: tempSelectedInterests.contains(interest),
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              tempSelectedInterests.add(interest);
                            } else {
                              tempSelectedInterests.remove(interest);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),

                  // --- Фильтр по уровню подготовки ---
                  const Text('Уровень подготовки', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ..._availableSkillLevels.map((level) {
                    return RadioListTile<String>(
                      title: Text(level),
                      value: level,
                      groupValue: tempSkillLevel,
                      onChanged: (value) {
                        setModalState(() {
                          tempSkillLevel = value;
                        });
                      },
                    );
                  }).toList(),

                  // --- Кнопки управления ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          // Сбрасываем фильтры и применяем
                           setModalState(() {
                            tempSelectedInterests.clear();
                            tempSkillLevel = null;
                          });
                          setState(() {
                            _selectedInterests.clear();
                            _selectedSkillLevel = null;
                          });
                          _performSearch();
                          Navigator.pop(context);
                        },
                        child: const Text('Сбросить'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          // Применяем выбранные фильтры к основному состоянию страницы
                          setState(() {
                            _selectedInterests = tempSelectedInterests;
                            _selectedSkillLevel = tempSkillLevel;
                          });
                          _performSearch(); // Выполняем поиск с новыми фильтрами
                          Navigator.pop(context); // Закрываем окно
                        },
                        child: const Text('Применить'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск партнеров'),
      ),
      body: Column(
        children: [
          // --- Панель поиска и фильтров ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск по имени...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterBottomSheet,
                  tooltip: 'Фильтры',
                ),
              ],
            ),
          ),

          // --- Результаты поиска ---
          Expanded(
            child: _buildResults(),
          ),
        ],
      ),
    );
  }

  // Виджет для отображения результатов
  Widget _buildResults() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Если поиск еще не выполнялся и нет текста
    if (_searchResults.isEmpty && _searchController.text.isEmpty) {
       return const Center(
        child: Text(
          'Введите имя или используйте фильтры,\nчтобы найти партнеров для тренировок.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    
    // Если по результатам поиска ничего не найдено
    if (_searchResults.isEmpty) {
      return const Center(child: Text('Ничего не найдено'));
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final profile = _searchResults[index];
        return _UserCard(profile: profile);
      },
    );
  }
}

// Отдельный виджет для карточки пользователя в результатах поиска
class _UserCard extends StatelessWidget {
  final Map<String, dynamic> profile;

  const _UserCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = profile['avatar_url'] as String?;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => ProfilePage.navigateTo(context, userId: profile['id']),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage:
                    avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null || avatarUrl.isEmpty ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile['full_name'] ?? 'Без имени',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (profile['skill_level'] != null && profile['skill_level'].isNotEmpty)
                      Text(
                        'Уровень: ${profile['skill_level']}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    if (profile['interests'] != null && profile['interests'].isNotEmpty)
                      Text(
                        'Интересы: ${profile['interests']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}