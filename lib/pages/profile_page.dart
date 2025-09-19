// lib/pages/profile_page.dart

// Юзинг директивы
import 'package:flutter/material.dart';
import 'package:spotter/pages/chat_screen.dart';
import '../main.dart';

// ignore: must_be_immutable
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
  late String _userId;

  // Переменные окна
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isMyProfile = false;
  final _searchTextController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _showDropdown = false;
  int _followers = 0;

  // Добавьте переменную для статуса подписки
  bool _isSubscribed = false;

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

    // Получаем количество подписчиков
    final followers = await _followersCount(userGuid);

    setState(() {
      _userProfile = profile;
      _isMyProfile = myId != null && myId == userGuid;
      _isLoading = false;
      _followers = followers;
    });

    if (!_isMyProfile) {
      dynamic myId = supabase.auth.currentUser?.id;
      myId ??= "";
      final subscribeResponse = await supabase
          .from('subscribes')
          .select('id')
          .eq('user_id', _userId)
          .eq('subscribed_user', myId!);
      setState(() {
        _isSubscribed = subscribeResponse.isNotEmpty;
      });
    }
  } catch (error) {
    setState(() {
      _isLoading = false;
    });
    // ignore: use_build_context_synchronously
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

Future<int> _followersCount(String userId) async {
try {
  final response = await supabase
      .from('subscribes')
      .select('id')
      .eq('user_id', userId);

  // ignore: dead_code, unnecessary_null_comparison
  if (response == null) return 0;
  // ignore: unnecessary_type_check
  if (response is List) return response.length;
  } catch (e) {
    return 0;
  }
}

Future<void> _openIndividualChat(BuildContext context) async {
  final currentUserId = supabase.auth.currentUser?.id;
  final targetUserId = _userId;

  if (currentUserId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Непредвиденная ошибка. Невозможно открыть чат. Попробуйте позже...')),
    );
    return;
  }

  try {
    // 1. Ищем существующий чат через вложенный запрос
    final existingChats = await supabase
        .from('chats')
        .select('''
          id,
          chat_members!inner(user_id)
        ''')
        .eq('individual', true)
        .eq('chat_members.user_id', currentUserId);

    // 2. Проверяем каждый найденный чат на наличие целевого пользователя
    for (final chat in existingChats) {
      final chatId = chat['id'] as String;
      
      final targetMember = await supabase
          .from('chat_members')
          .select()
          .eq('chat_id', chatId)
          .eq('user_id', targetUserId)
          .maybeSingle();

      if (targetMember != null) {
        // Чат найден - открываем его
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatId: chatId),
          ),
        );
        return;
      }
    }

    // 3. Если чат не найден - создаем новый
    final newChat = await supabase
        .from('chats')
        .insert({'individual': true})
        .select()
        .single();

    // 4. Добавляем обоих участников
    await supabase
        .from('chat_members')
        .insert([
          {'chat_id': newChat['id'], 'user_id': currentUserId},
          {'chat_id': newChat['id'], 'user_id': targetUserId}
        ]);

    // 5. Открываем новый чат
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatId: newChat['id']),
      ),
    );

  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ошибка при создании/поиске чата: $e')),
    );
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
                          child: (_userProfile?['avatar_url'] != null && _userProfile!['avatar_url'].toString().isNotEmpty)
                              ? CircleAvatar(
                                  radius: 48,
                                  backgroundImage: NetworkImage(_userProfile!['avatar_url']),
                                  backgroundColor: Colors.grey[200],
                                )
                              : CircleAvatar(
                                  radius: 48,
                                  backgroundColor: Colors.grey[200],
                                  child: Icon(Icons.person, size: 48),
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
                                      'Followers: $_followers',
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
                            child: Row(
                              children: [
                                // Левая кнопка (основная)
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _isMyProfile
                                        ? () {
                                            Navigator.of(context).pushNamed('/edit-profile');
                                          }
                                        : () {
                                            _openIndividualChat(context);
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.lightGreen[300],
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(double.infinity, 60),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                    ),
                                    child: Text(
                                      _isMyProfile ? 'Редактировать профиль' : 'Написать сообщение',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                if (!_isMyProfile)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12.0),
                                    child: SizedBox(
                                      width: 40, // Фиксированная ширина для круглой кнопки
                                      height: 40, // Такая же высота как у левой кнопки
                                      child: ElevatedButton(
                                        onPressed: _isSubscribed
                                            ? () async {
                                                await supabase
                                                        .from('subscribes')
                                                        .delete()
                                                        .eq('user_id', _userId).eq('subscribed_user', widget.initialUserId);
                                                _fetchUserProfile(_userId);
                                              }
                                            : () async {
                                                await supabase
                                                  .from('subscribes')
                                                  .insert({'user_id': _userId, 'subscribed_user': widget.initialUserId});
                                                _fetchUserProfile(_userId);
                                              },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.lightGreen[300],
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(40, 40), // Квадратная кнопка
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(30),
                                          ),
                                        ),
                                        child: Icon(
                                          _isSubscribed ? Icons.check : Icons.flash_on,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
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