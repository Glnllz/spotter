// lib/pages/profile_page.dart

// Юзинг директивы
import 'package:flutter/material.dart';
import '../main.dart';

class ProfilePage extends StatefulWidget {
  String initialUserId; 

  ProfilePage({
    super.key,
    required this.initialUserId,
  });

  // Статический метод для удобной навигации
  static void navigateTo(BuildContext context, {required String userId}) {
  Navigator.of(context).pushNamed(
    '/profile',
    arguments: userId,
  );
}

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  late String _userId; // Local state variable

  // Переменные окна
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isMyProfile = false;
  final _searchTextController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _showDropdown = false;

  // Заполнение профиля
  @override
  void initState() {
    super.initState();
    _userId = widget.initialUserId;
    _fetchUserProfile(_userId);
    _searchTextController.addListener(() {
      
      if (_searchTextController.text.isEmpty) {
        setState(() {
          _showDropdown = false;
        });
      }
    });
  }

  Future<void> _fetchUserProfile(String userGuid) async {
  try {
    final profile = await supabase
        .from('profiles')
        .select()
        .eq('id', userGuid)
        .maybeSingle();

    final myId = supabase.auth.currentUser?.id;

    setState(() {
      _userProfile = profile;
      _isMyProfile = myId != null && myId == userGuid;
      _isLoading = false;
    });
  } catch (error) {
    setState(() {
      _isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка загрузки профиля: $error')),
    );
  }
}

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showDropdown = false;
      });
      return;
    }
    final results = await supabase
        .from('profiles')
        .select('id, full_name')
        .ilike('full_name', '%$query%')
        .limit(5);
    setState(() {
      _searchResults = List<Map<String, dynamic>>.from(results);
      _showDropdown = _searchResults.isNotEmpty;
    });
  }

  // When you want to show another user's profile:
  void _showUserProfile(String userId) {
    setState(() {
      _userId = userId;
      _isLoading = true;
      _showDropdown = false;
      _searchTextController.clear();
    });
    _fetchUserProfile(userId);
  }

  void showMyProfile() {
  final myId = supabase.auth.currentUser?.id;
  if (myId != null) {
    _showUserProfile(myId);
  }
}

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(child: Text('Профиль не найден'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Center(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.5,
                                height: 36,
                                child: TextField(
                                  controller: _searchTextController,
                                  decoration: InputDecoration(
                                    hintText: 'Search',
                                    prefixIcon: Icon(Icons.search, size: 20),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                  onSubmitted: _searchUsers,
                                ),
                              ),
                            ),
                            if (_showDropdown)
                              Container(
                                width: MediaQuery.of(context).size.width * 0.5,
                                constraints: const BoxConstraints(maxHeight: 180),
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final user = _searchResults[index];
                                    return ListTile(
                                      dense: true,
                                      title: Text(user['full_name'] ?? ''),
                                      subtitle: Text('@${user['full_name']}'),
                                      onTap: () {
                                        setState(() {
                                          _showDropdown = false;
                                          _searchTextController.clear();
                                          _isLoading = true;
                                          _userId = user['id'];
                                        });
                                        _fetchUserProfile(_userId);
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Отдельно выводим аватар
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[300],
                                border: Border.all(color: Colors.grey, width: 1),
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              ),
                            ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Информация о пользователе
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _userProfile!['full_name'] ?? 'Без имени',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '@${_userProfile!['username'] ?? 'user'}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      '·',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_userProfile!['following_count'] ?? 0} Following',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                  child: Text(
                                    '${_userProfile!['about'] ?? 'Нет информации'}',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Кнопка редактирования или сообщения
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.6,
                            height: 40,
                            child: ElevatedButton(
                              onPressed: _isMyProfile
                                  ? () {
                                      // TODO: Переход на страницу редактирования профиля
                                    }
                                  : () {
                                      // TODO: Реализовать функцию "Написать сообщение"
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightGreen[300],
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                _isMyProfile ? 'Редактировать профиль' : 'Написать сообщение',
                                style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Раздел "Favorites & New Group"
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            double cardSize = 140;
                            double totalWidth = cardSize * 2 + 24;
                            bool isWide = constraints.maxWidth > totalWidth;

                            return Row(
                              mainAxisAlignment: isWide ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: cardSize,
                                  child: Column(
                                    children: [
                                      AspectRatio(
                                        aspectRatio: 1,
                                        child: Card(
                                          elevation: 2,
                                          color: Colors.lightGreen[200],
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(18),
                                          ),
                                          child: Center(
                                            child: Icon(Icons.favorite, color: Colors.white, size: cardSize * 0.5),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Favorites',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (_isMyProfile)
                                  SizedBox(width: 24), 
                                if (_isMyProfile)
                                  SizedBox(
                                    width: cardSize,
                                    child: Column(
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 1,
                                          child: Card(
                                            elevation: 2,
                                            color: Colors.lightGreen[200],
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(18),
                                            ),
                                            child: Center(
                                              child: Icon(Icons.group_add, color: Colors.white, size: cardSize * 0.5),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        const Text(
                                          'New Group',
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}