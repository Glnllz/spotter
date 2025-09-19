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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ошибка')),
        body: const Center(child: Text('Группа не найдена')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_group!['name'] ?? 'Детали группы'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Обложка группы
            if (_group!['cover_url'] != null)
              Image.network(
                _group!['cover_url'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            
            // Информация о группе
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _group!['name'] ?? '',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _group!['description'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  // Счетчик участников
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16),
                      const SizedBox(width: 4),
                      Text('${_members.length} участников'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Кнопка вступления/выхода
                  if (_currentUserId != null)
                    ElevatedButton(
                      onPressed: _isMember ? _leaveGroup : _joinGroup,
                      child: Text(_isMember ? 'Выйти из группы' : 'Вступить в группу'),
                    ),
                ],
              ),
            ),
            
            // Список участников
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Участники:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _members.length,
                itemBuilder: (context, index) {
                  final member = _members[index]['profiles'] ?? {};
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: member['avatar_url'] != null
                              ? NetworkImage(member['avatar_url'])
                              : null,
                          child: member['avatar_url'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member['full_name'] ?? 'Без имени',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
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