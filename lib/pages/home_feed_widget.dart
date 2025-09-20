// lib/pages/home_feed_widget.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:spotter/main.dart';
import 'package:spotter/pages/group_details_page.dart';
import 'package:spotter/pages/login_page.dart';
import 'package:spotter/pages/profile_page.dart';
import 'package:spotter/pages/section_details_page.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomeFeedWidget extends StatefulWidget {
  const HomeFeedWidget({super.key});

  @override
  State<HomeFeedWidget> createState() => _HomeFeedWidgetState();
}

class _HomeFeedWidgetState extends State<HomeFeedWidget> {
  bool _isLoading = true;
  String? _errorMessage;
  
  // --- ИЗМЕНЕНО: Раздельные списки для каждой вкладки ---
  List<Map<String, dynamic>> _forYouItems = [];
  List<Map<String, dynamic>> _followingItems = [];

  bool _isForYouSelected = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  // --- ИЗМЕНЕНО: Функция загружает данные для обеих вкладок ---
  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) throw 'Пользователь не авторизован';

      // --- 1. Загрузка данных для вкладки "Following" ---
      // Сначала получаем ID тех, на кого мы подписаны
      final subscribedToIdsResponse = await supabase
          .from('subscribes')
          .select('user_id')
          .eq('subscribed_user', currentUserId);

      final subscribedToIds = subscribedToIdsResponse
          .map((subscription) => subscription['user_id'] as String)
          .toList();

      List<Map<String, dynamic>> followingProfiles = [];
      if (subscribedToIds.isNotEmpty) {
        // Теперь загружаем профили по этим ID
        followingProfiles = await supabase
            .from('profiles')
            .select()
            .inFilter('id', subscribedToIds);
      }
      
      // --- 2. Загрузка данных для вкладки "For you" ---
      final groups = await supabase
          .from('groups')
          .select()
          .order('created_at', ascending: false)
          .limit(10);
      
      final sections = await supabase
          .from('section_events')
          .select('*, sections:section_id(*)')
          .gte('created_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: true)
          .limit(10);

      // --- 3. Формируем и сохраняем списки ---
      final forYouCombined = [
        ...groups.map((g) => {'type': 'group', 'data': g}),
        ...sections.map((s) => {'type': 'section', 'data': s}),
      ];
      forYouCombined.shuffle(Random());
      
      setState(() {
        _followingItems = followingProfiles
            .map((p) => {'type': 'profile', 'data': p})
            .toList();
        _forYouItems = forYouCombined;
      });

    } catch (e) {
      setState(() => _errorMessage = 'Ошибка загрузки ленты: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Выйти')),
        ],
      ),
    );

    if (shouldSignOut == null || !shouldSignOut) return;

    try {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка выхода: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0E8),
      appBar: AppBar(
        title: const Text('Spotter', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Выйти из аккаунта',
          )
        ],
      ),
      body: Stack(
        children: [
          ClipPath(
            clipper: WaveClipper(),
            child: Container(color: const Color(0xFF90C29E)),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildToggles(),
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggles() {
    return Row(children: [
      GestureDetector(
        onTap: () => setState(() => _isForYouSelected = true),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: _isForYouSelected ? const Color(0xFFF0F0E8) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: const Text('For you', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
      const SizedBox(width: 16),
      GestureDetector(
        onTap: () => setState(() => _isForYouSelected = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
    ]);
  }

  // --- ИЗМЕНЕНО: Этот виджет теперь использует разные списки в зависимости от вкладки ---
  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) return Center(child: Text(_errorMessage!));

    final activeList = _isForYouSelected ? _forYouItems : _followingItems;
    
    if (activeList.isEmpty) {
      return Center(
        child: Text(
          _isForYouSelected
              ? 'Здесь будут рекомендованные группы и секции.'
              : 'Подпишитесь на пользователей,\nчтобы видеть их здесь.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFeed,
      child: MasonryGridView.count(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: activeList.length,
        itemBuilder: (context, index) {
          final item = activeList[index];
          // Карточки разной высоты для "шахматного" эффекта
          final height = (index % 4 == 0 || index % 4 == 3) ? 220.0 : 180.0;
          return _FeedCard(item: item, height: height);
        },
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final double height;
  const _FeedCard({required this.item, required this.height});

  @override
  Widget build(BuildContext context) {
    String title = 'Заголовок'; String subtitle = 'Подзаголовок'; VoidCallback onTap = () {}; String? imageUrl;
    switch (item['type']) {
      case 'profile':
        title = item['data']['full_name'] ?? 'Пользователь'; subtitle = item['data']['interests'] ?? 'Нет интересов'; imageUrl = item['data']['avatar_url']; onTap = () => ProfilePage.navigateTo(context, userId: item['data']['id']); break;
      case 'group':
        title = item['data']['name'] ?? 'Группа'; subtitle = item['data']['description'] ?? 'Нет описания'; imageUrl = item['data']['cover_url']; onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => GroupDetailsPage(groupId: item['data']['id']))); break;
      case 'section':
        final sectionInfo = item['data']['sections']; title = sectionInfo?['name'] ?? 'Секция'; subtitle = item['data']['location'] ?? 'Нет локации'; onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => SectionDetailsPage(sectionEventId: item['data']['id']))); break;
    }
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: height, child: ClipRRect(borderRadius: BorderRadius.circular(16), child: (imageUrl != null && imageUrl.isNotEmpty) ? Image.network(imageUrl, height: height, width: double.infinity, fit: BoxFit.cover, loadingBuilder: (context, child, p) => p == null ? child : const Center(child: CircularProgressIndicator()), errorBuilder: (context, error, stack) => Container(color: Colors.grey[300], child: Icon(Icons.broken_image, color: Colors.grey[600]))) : Container(color: Colors.grey[300]))),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[700]), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);
    path.lineTo(size.width * 0.4, size.height);
    path.quadraticBezierTo(size.width * 0.6, size.height * 0.7, size.width * 0.75, size.height * 0.4);
    path.quadraticBezierTo(size.width * 0.85, size.height * 0.15, size.width, 0);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}