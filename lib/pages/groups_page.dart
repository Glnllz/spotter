import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({super.key});

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _getMyGroups() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('Пользователь не авторизован');
      return [];
    }

    try {
      print('Запрос моих групп для пользователя: $userId');
      
      // Получаем ID групп, в которых состоит пользователь
      final memberData = await _supabase
          .from('group_members')
          .select('group_id')
          .eq('user_id', userId);
      
      if (memberData.isEmpty) {
        print('Пользователь не состоит ни в одной группе');
        return [];
      }
      
      final groupIds = memberData.map((item) => item['group_id'] as String).toList();
      print('Найдены ID групп: $groupIds');
      
      // Получаем информацию о группах
      final groupsData = await _supabase
          .from('groups')
          .select()
          .inFilter('id', groupIds);
      
      print('Получены группы: ${groupsData.length}');
      return groupsData.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Ошибка при получении моих групп: $e');
      return [];
    }
  }
//GroupDetailsPage
  Future<List<Map<String, dynamic>>> _getAllGroups() async {
    try {
      print('Запрос всех групп');
      final data = await _supabase.from('groups').select();
      print('Получено всех групп: ${data.length}');
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Ошибка при получении всех групп: $e');
      return [];
    }
  }

  Future<int> _getMembersCount(String groupId) async {
    try {
      final data = await _supabase
          .from('group_members')
          .select('id')
          .eq('group_id', groupId);
      
      return data.length;
    } catch (e) {
      print('Ошибка при получении количества участников: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Группы по интересам'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Мои группы'),
            Tab(text: 'Все группы'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGroupsList(_getMyGroups, 'Мои группы'),
          _buildGroupsList(_getAllGroups, 'Все группы'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed('/create-group');
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGroupsList(
    Future<List<Map<String, dynamic>>> Function() fetchGroups,
    String listType,
  ) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchGroups(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Произошла ошибка'),
                Text('${snapshot.error}'),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Попробовать снова'),
                ),
              ],
            ),
          );
        }

        final groups = snapshot.data ?? [];

        if (groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$listType не найдены'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Обновить'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return _GroupCard(
                id: group['id'],
                name: group['name'],
                description: group['description'],
                coverUrl: group['cover_url'],
                onTap: () {
                  Navigator.of(context).pushNamed(
                    '/group-details',
                    arguments: {'groupId': group['id']}, // Передаем как Map с ключом 'groupId'
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String id;
  final String name;
  final String? description;
  final String? coverUrl;
  final VoidCallback onTap;

  const _GroupCard({
    required this.id,
    required this.name,
    this.description,
    this.coverUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (coverUrl != null && coverUrl!.isNotEmpty)
              Image.network(
                coverUrl!,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(Icons.group, size: 50),
                ),
              )
            else
              Container(
                height: 150,
                color: Colors.blue[100],
                child: const Icon(Icons.group, size: 50),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (description != null && description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(description!),
                    ),
                  FutureBuilder<int>(
                    future: _getMembersCount(id),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Участников: $count',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _getMembersCount(String groupId) async {
    try {
      final supabase = Supabase.instance.client;
      final data = await supabase
          .from('group_members')
          .select('id')
          .eq('group_id', groupId);
      
      return data.length;
    } catch (e) {
      print('Ошибка при получении количества участников: $e');
      return 0;
    }
  }
}