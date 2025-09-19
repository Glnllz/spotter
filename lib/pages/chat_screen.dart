// lib/pages/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:spotter/pages/profile_page.dart';
import '../main.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  // Статический метод для удобной навигации
  static void navigateTo(BuildContext context, {required String chatId}) {
    Navigator.of(context).pushNamed(
      '/chat',
      arguments: chatId,
    );
  }

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  Map<String, dynamic>? _otherUser;
  bool _isLoading = true;
  final _scrollController = ScrollController();
  Stream<List<Map<String, dynamic>>>? _messagesStream;

  @override
  void initState() {
    super.initState();
    _loadChatData();
    _setupMessagesStream();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatData() async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      // Загружаем сообщения с информацией о пользователях
      final messages = await supabase
          .from('chat_messages')
          .select('''
            *,
            profiles!user_id(id, full_name, avatar_url, about, interests, skill_level)
          ''')
          .eq('chat_id', widget.chatId)
          .order('created_at', ascending: true);

      // Определяем другого пользователя в чате
      final chatMembers = await supabase
          .from('chat_members')
          .select('''
            user_id,
            profiles!user_id(*)
          ''')
          .eq('chat_id', widget.chatId);

      Map<String, dynamic>? otherUser;
      for (final member in chatMembers) {
        if (member['user_id'] != currentUserId && member['profiles'] != null) {
          otherUser = member['profiles'] as Map<String, dynamic>;
          break;
        }
      }

      setState(() {
        _messages = List<Map<String, dynamic>>.from(messages);
        _otherUser = otherUser;
        _isLoading = false;
      });

      // Прокручиваем к последнему сообщению после загрузки
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && _messages.isNotEmpty) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки чата: $e')),
      );
    }
  }

  void _setupMessagesStream() {
    // Создаем stream для отслеживания новых сообщений
    _messagesStream = supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', widget.chatId)
        .order('created_at');

    // Слушаем изменения
    _messagesStream?.listen((List<Map<String, dynamic>> newMessages) {
      // Обновляем список сообщений
      setState(() {
        _messages = newMessages;
      });

      // Прокручиваем к новому сообщению
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && _messages.isNotEmpty) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return;

    try {
      await supabase.from('chat_messages').insert({
        'message': messageText,
        'user_id': currentUserId,
        'chat_id': widget.chatId,
      });

      _messageController.clear();
      await _loadChatData();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка отправки сообщения: $e')),
      );
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final currentUserId = supabase.auth.currentUser?.id;
    final isMyMessage = message['user_id'] == currentUserId;
    final userProfile = message['profiles'] as Map<String, dynamic>?;
    final userName = userProfile?['full_name'] ?? 'Неизвестный';
    final userAvatar = userProfile?['avatar_url'];
    final userSkill = userProfile?['skill_level'] ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMyMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMyMessage)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: userAvatar != null && userAvatar.isNotEmpty
                        ? NetworkImage(userAvatar)
                        : null,
                    child: userAvatar == null || userAvatar.isEmpty
                        ? const Icon(Icons.person, size: 18, color: Colors.white)
                        : null,
                  ),
                  if (userSkill.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.lightGreen[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        userSkill,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMyMessage)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                  decoration: BoxDecoration(
                    color: isMyMessage ? Colors.lightGreen[300] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message['message'] ?? '',
                        style: TextStyle(
                          fontSize: 16,
                          color: isMyMessage ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message['created_at']),
                        style: TextStyle(
                          fontSize: 10,
                          color: isMyMessage ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  void _showUserProfile() {
    if (_otherUser != null) {
      ProfilePage.navigateTo(
        context,
        userId: _otherUser!['id'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightGreen[300],
        foregroundColor: Colors.white,
        title: _isLoading
            ? const Text('Загрузка...')
            : InkWell(
                onTap: _showUserProfile,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: _otherUser?['avatar_url'] != null &&
                              _otherUser!['avatar_url'].isNotEmpty
                          ? NetworkImage(_otherUser!['avatar_url'])
                          : null,
                      child: _otherUser?['avatar_url'] == null ||
                              _otherUser!['avatar_url'].isEmpty
                          ? const Icon(Icons.person, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _otherUser?['full_name'] ?? 'Неизвестный',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        if (_otherUser?['skill_level'] != null &&
                            _otherUser!['skill_level'].isNotEmpty)
                          Text(
                            _otherUser!['skill_level'],
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
        actions: [
          if (_otherUser != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: _showUserProfile,
              tooltip: 'Информация о пользователе',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(
                          child: Text(
                            'Начните общение!',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8.0),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageBubble(_messages[index]);
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Введите сообщение...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            suffixIcon: _messageController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.send, color: Colors.lightGreen),
                                    onPressed: _sendMessage,
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            setState(() {}); // Для обновления иконки отправки
                          },
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_messageController.text.isEmpty)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: null,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}