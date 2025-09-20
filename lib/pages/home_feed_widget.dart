// lib/pages/home_feed_widget.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:spotter/main.dart';
import 'package:spotter/pages/group_details_page.dart';
import 'package:spotter/pages/profile_page.dart';
import 'package:spotter/pages/section_details_page.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HomeFeedWidget extends StatefulWidget {
  const HomeFeedWidget({super.key});

  @override
  State<HomeFeedWidget> createState() => _HomeFeedWidgetState();
}

class _HomeFeedWidgetState extends State<HomeFeedWidget> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _feedItems = [];
  bool _isForYouSelected = true; // Для переключателя

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) throw 'Пользователь не авторизован';

      // Загружаем данные (логика остается прежней)
      final profiles = await supabase
          .from('profiles')
          .select()
          .not('id', 'eq', currentUserId)
          .limit(15);
      final groups = await supabase
          .from('groups')
          .select()
          .order('created_at', ascending: false)
          .limit(8);
      final sections = await supabase
          .from('section_events')
          .select('*, sections:section_id(*)')
          .gte('created_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: true)
          .limit(8);

      final List<Map<String, dynamic>> combinedItems = [
        ...profiles.map((p) => {'type': 'profile', 'data': p}),
        ...groups.map((g) => {'type': 'group', 'data': g}),
        ...sections.map((s) => {'type': 'section', 'data': s}),
      ];

      combinedItems.shuffle(Random());
      setState(() => _feedItems = combinedItems);
    } catch (e) {
      setState(() => _errorMessage = 'Ошибка загрузки ленты: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0E8), // Светло-бежевый фон
      body: Stack(
        children: [
          // Зеленый фон с волной
          ClipPath(
            clipper: WaveClipper(),
            child: Container(
              color: const Color(0xFF90C29E), // Светло-зеленый
            ),
          ),

          // Основной контент
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Заголовок "home" и переключатели
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'home',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      _buildToggles(),
                    ],
                  ),
                ),

                // Лента
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggles() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _isForYouSelected = true),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            decoration: BoxDecoration(
              color:
                  _isForYouSelected ? const Color(0xFFF0F0E8) : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: const Text(
              'For you',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => setState(() => _isForYouSelected = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Text(
              'Following',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: _isForYouSelected ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_feedItems.isEmpty) {
      return const Center(child: Text('В ленте пока пусто.'));
    }

    // Лента в виде сетки
    return RefreshIndicator(
      onRefresh: _loadFeed,
      child: MasonryGridView.count(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        crossAxisCount: 2, // Две колонки
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: _feedItems.length,
        itemBuilder: (context, index) {
          final item = _feedItems[index];
          // Карточки разной высоты для "шахматного" эффекта
          final height = (index % 4 == 0 || index % 4 == 3) ? 220.0 : 180.0;
          return _FeedCard(item: item, height: height);
        },
      ),
    );
  }
}

// Универсальная карточка для ленты, как в макете
class _FeedCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final double height;

  const _FeedCard({required this.item, required this.height});

  @override
  Widget build(BuildContext context) {
    String title = 'Заголовок';
    String subtitle = 'Подзаголовок';
    VoidCallback onTap = () {};

    // Переменная для URL изображения
    String? imageUrl;

    // Логика для получения URL в зависимости от типа карточки
    switch (item['type']) {
      case 'profile':
        title = item['data']['full_name'] ?? 'Пользователь';
        subtitle = item['data']['interests'] ?? 'Нет интересов';
        imageUrl = item['data']['avatar_url']; // URL аватара пользователя
        onTap = () => ProfilePage.navigateTo(context, userId: item['data']['id']);
        break;
      case 'group':
        title = item['data']['name'] ?? 'Группа';
        subtitle = item['data']['description'] ?? 'Нет описания';
        imageUrl = item['data']['cover_url']; // URL обложки группы
        onTap = () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => GroupDetailsPage(groupId: item['data']['id']),
            ));
        break;
      case 'section':
        final sectionInfo = item['data']['sections'];
        title = sectionInfo?['name'] ?? 'Секция';
        subtitle = item['data']['location'] ?? 'Нет локации';
        // У секций может не быть изображения, поэтому imageUrl останется null
        onTap = () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => SectionDetailsPage(sectionEventId: item['data']['id']),
            ));
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Блок отображения изображения
          SizedBox(
            height: height,
            child: ClipRRect( // Используем ClipRRect для скругления углов у изображения
              borderRadius: BorderRadius.circular(16),
              child: (imageUrl != null && imageUrl.isNotEmpty)
                  // Если есть URL, показываем изображение из сети
                  ? Image.network(
                      imageUrl,
                      height: height,
                      width: double.infinity,
                      fit: BoxFit.cover, // Масштабируем, чтобы заполнить контейнер
                      // Пока изображение грузится, показываем индикатор
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      // Если произошла ошибка загрузки, показываем плейсхолдер
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Icon(Icons.broken_image, color: Colors.grey[600]),
                        );
                      },
                    )
                  // Если URL нет, показываем стандартный серый плейсхолдер
                  : Container(
                      color: Colors.grey[300],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Кастомный клиппер для создания волны
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width * 0.4, size.height);
    path.quadraticBezierTo(
        size.width * 0.6, size.height * 0.7, size.width * 0.75, size.height * 0.4);
    path.quadraticBezierTo(
        size.width * 0.85, size.height * 0.15, size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}