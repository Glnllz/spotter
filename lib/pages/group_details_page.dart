import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupDetailsPage extends StatefulWidget {
  final String groupId;
  const GroupDetailsPage({super.key, required this.groupId});

  @override
  State<GroupDetailsPage> createState() => _GroupDetailsPageState();
}

class _GroupDetailsPageState extends State<GroupDetailsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? _group;
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  bool _isMember = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadGroupData();
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.id;
      });
    }
  }

  Future<void> _loadGroupData() async {
    try {
      // Загружаем данные группы
      final groupResponse = await supabase
          .from('groups')
          .select()
          .eq('id', widget.groupId)
          .single();
      
      // Загружаем участников группы
      final membersResponse = await supabase
          .from('group_members')
          .select('''
            user_id,
            profiles:user_id (id, full_name, avatar_url)
          ''')
          .eq('group_id', widget.groupId);
      
      // Проверяем, является ли текущий пользователь участником
      final currentUser = supabase.auth.currentUser;
      bool isMember = false;
      if (currentUser != null) {
        for (var member in membersResponse) {
          if (member['user_id'] == currentUser.id) {
            isMember = true;
            break;
          }
        }
      }

      setState(() {
        _group = groupResponse;
        _members = List<Map<String, dynamic>>.from(membersResponse);
        _isMember = isMember;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки данных группы: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinGroup() async {
    if (_currentUserId == null) return;
    
    try {
      await supabase
          .from('group_members')
          .insert({
            'user_id': _currentUserId,
            'group_id': widget.groupId,
          });
      
      // Обновляем данные
      await _loadGroupData();
    } catch (e) {
      print('Ошибка вступления в группу: $e');
    }
  }

  Future<void> _leaveGroup() async {
    if (_currentUserId == null) return;
    
    try {
      await supabase
          .from('group_members')
          .delete()
          .eq('user_id', _currentUserId!)
          .eq('group_id', widget.groupId);
      
      // Обновляем данные
      await _loadGroupData();
    } catch (e) {
      print('Ошибка выхода из группы: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[700]!),
          ),
        ),
      );
    }

    if (_group == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.green[700]),
          title: Text(
            'Ошибка',
            style: TextStyle(color: Colors.black),
          ),
        ),
        body: Center(child: Text('Группа не найдена')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.green[700]),
        title: Text(
          _group!['name'] ?? 'Детали группы',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Обложка группы с декоративными элементами
            Stack(
              children: [
                if (_group!['cover_url'] != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    child: ClipRRect(
                      child: Image.network(
                        _group!['cover_url'],
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.green[100],
                    child: Icon(
                      Icons.group,
                      size: 60,
                      color: Colors.green[700],
                    ),
                  ),
                
                // Декоративные зеленые элементы
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            
            // Основная информация о группе
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _group!['name'] ?? '',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    _group!['description'] ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Счетчик участников
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.people, size: 20, color: Colors.green[700]),
                        SizedBox(width: 8),
                        Text(
                          '${_members.length} участников',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Кнопка вступления/выхода
                  if (_currentUserId != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isMember ? _leaveGroup : _joinGroup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isMember ? Colors.white : Colors.green[700],
                          foregroundColor: _isMember ? Colors.green[700] : Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: _isMember 
                                ? BorderSide(color: Colors.green[700]!, width: 1.5)
                                : BorderSide.none,
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _isMember ? 'Покинуть группу' : 'Присоединиться',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Разделитель
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 0),
            ),
            
            // Список участников
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'Участники',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            // Горизонтальный список участников
            Container(
              height: 100,
              margin: EdgeInsets.only(bottom: 20),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index]['profiles'] ?? {};
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.green[100]!,
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: member['avatar_url'] != null
                                ? Image.network(
                                    member['avatar_url'],
                                    fit: BoxFit.cover,
                                  )
                                : Icon(
                                    Icons.person,
                                    color: Colors.green[700],
                                    size: 30,
                                  ),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          member['full_name'] ?? 'Без имени',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Декоративный зеленый элемент внизу
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}