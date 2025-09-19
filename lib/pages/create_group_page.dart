import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  
  File? _coverImage;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024, // Оптимизация - уменьшаем размер
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _coverImage = File(pickedFile.path);
          _errorMessage = null; // Сбрасываем ошибку при успешном выборе
        });
      }
    } catch (e) {
      print('Ошибка выбора изображения: $e');
      setState(() {
        _errorMessage = 'Не удалось выбрать изображение';
      });
    }
  }

  Future<String?> _uploadCoverImage() async {
    if (_coverImage == null) return null;
    
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_nameController.text}';
      final fileExtension = _coverImage!.path.split('.').last;
      final fullFileName = '$fileName.$fileExtension';
      
      // Загружаем файл
      await supabase.storage
          .from('group_covers')
          .upload(fullFileName, _coverImage!);

      // Получаем публичный URL
      return supabase.storage
          .from('group_covers')
          .getPublicUrl(fullFileName);
    } catch (e) {
      print('Ошибка загрузки изображения: $e');
      setState(() {
        _errorMessage = 'Ошибка загрузки изображения';
      });
      return null;
    }
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Загружаем обложку, если выбрана
      final String? coverUrl = await _uploadCoverImage();
      
      // Получаем ID текущего пользователя
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorMessage = 'Пользователь не авторизован';
          _isLoading = false;
        });
        return;
      }
      
      // Создаем группу
      final response = await supabase
          .from('groups')
          .insert({
            'name': _nameController.text,
            'description': _descriptionController.text,
            'cover_url': coverUrl,
            'creator_id': currentUser.id,
          })
          .select()
          .single();
      
      final newGroupId = response['id'];
      
      // Добавляем создателя в участники группы
      await supabase
          .from('group_members')
          .insert({
            'user_id': currentUser.id,
            'group_id': newGroupId,
          });
      
      // Возвращаемся на предыдущую страницу
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Ошибка создания группы: $e');
      setState(() {
        _errorMessage = 'Ошибка создания группы';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Создание новой группы'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Поле для названия группы
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название группы',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите название группы';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Поле для описания
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание группы',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Пожалуйста, введите описание группы';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Кнопка загрузки обложки
              OutlinedButton(
                onPressed: _pickImage,
                child: const Text('Загрузить обложку'),
              ),
              const SizedBox(height: 8),
              
              // Превью выбранного изображения
              if (_coverImage != null)
                Container(
                  height: 200,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(_coverImage!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              
              // Сообщение об ошибке
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              
              // Кнопка создания группы
              ElevatedButton(
                onPressed: _isLoading ? null : _createGroup,
                child: const Text('Создать группу'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}