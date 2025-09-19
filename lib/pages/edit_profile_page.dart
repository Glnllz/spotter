import 'package:flutter/material.dart';
import 'package:spotter/main.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  // ignore: unused_field
  Map<String, dynamic>? _profile;

  final _nameController = TextEditingController();
  final _avatarController = TextEditingController();
  final _aboutController = TextEditingController();
  final _interestsController = TextEditingController();
  final _skillLevelController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: пользователь не найден')),
        );
        Navigator.of(context).pop();
      }
      return;
    }
    final profile = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (profile != null) {
      _nameController.text = profile['full_name'] ?? '';
      _avatarController.text = profile['avatar_url'] ?? '';
      _aboutController.text = profile['about'] ?? '';
      _interestsController.text = profile['interests'] ?? '';
      _skillLevelController.text = profile['skill_level'] ?? '';
    }
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final userId = supabase.auth.currentUser?.id;
    await supabase.from('profiles').update({
      'full_name': _nameController.text,
      'avatar_url': _avatarController.text,
      'about': _aboutController.text,
      'interests': _interestsController.text,
      'skill_level': _skillLevelController.text,
    }).eq('id', userId.toString());
    setState(() => _isLoading = false);
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Профиль обновлён!')),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    _aboutController.dispose();
    _interestsController.dispose();
    _skillLevelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать профиль')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Имя'),
                      validator: (v) => v == null || v.isEmpty ? 'Введите имя' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _avatarController,
                      decoration: const InputDecoration(labelText: 'URL аватара'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _aboutController,
                      decoration: const InputDecoration(labelText: 'О себе'),
                      minLines: 1,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _interestsController,
                      decoration: const InputDecoration(labelText: 'Интересы'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _skillLevelController,
                      decoration: const InputDecoration(labelText: 'Уровень навыка'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Сохранить'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
