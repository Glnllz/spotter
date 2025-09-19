import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SectionDetailsPage extends StatefulWidget {
  final String sectionEventId;
  
  const SectionDetailsPage({super.key, required this.sectionEventId});
  
  @override
  State<SectionDetailsPage> createState() => _SectionDetailsPageState();
}

class _SectionDetailsPageState extends State<SectionDetailsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  Map<String, dynamic>? _sectionEvent;
  Map<String, dynamic>? _section;
  int _registrationsCount = 0;
  int _maxParticipants = 0;
  bool _isRegistered = false;
  bool _isLoading = true;
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _loadSectionData();
  }

  Future<void> _loadSectionData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Загружаем данные о событии секции
      final sectionEventData = await _supabase
          .from('section_events')
          .select()
          .eq('id', widget.sectionEventId)
          .single();

      setState(() {
        _sectionEvent = sectionEventData;
        _maxParticipants = sectionEventData['max_participants'] ?? 0;
      });

      // Загружаем данные о секции
      final sectionId = sectionEventData['section_id'];
      final sectionData = await _supabase
          .from('sections')
          .select()
          .eq('id', sectionId)
          .single();

      setState(() {
        _section = sectionData;
      });

      // Загружаем количество записавшихся
      final registrationsData = await _supabase
          .from('event_registrations')
          .select('id')
          .eq('event_id', widget.sectionEventId);

      setState(() {
        _registrationsCount = registrationsData.length;
      });

      // Проверяем, записан ли текущий пользователь
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final userRegistration = await _supabase
            .from('event_registrations')
            .select('id')
            .eq('event_id', widget.sectionEventId)
            .eq('user_id', userId)
            .maybeSingle();

        setState(() {
          _isRegistered = userRegistration != null;
        });
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка при загрузке данных секции: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleRegistration() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      // Пользователь не авторизован
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Для записи необходимо авторизоваться')),
      );
      return;
    }

    setState(() {
      _isActionInProgress = true;
    });

    try {
      if (_isRegistered) {
        // Отменяем запись
        await _supabase
            .from('event_registrations')
            .delete()
            .eq('event_id', widget.sectionEventId)
            .eq('user_id', userId);

        setState(() {
          _isRegistered = false;
          _registrationsCount--;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Запись отменена')),
        );
      } else {
        // Проверяем, есть ли свободные места
        if (_maxParticipants > 0 && _registrationsCount >= _maxParticipants) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Нет свободных мест')),
          );
          return;
        }

        // Добавляем запись
        await _supabase
            .from('event_registrations')
            .insert({
              'event_id': widget.sectionEventId,
              'user_id': userId,
              'registered_at': DateTime.now().toIso8601String(),
            });

        setState(() {
          _isRegistered = true;
          _registrationsCount++;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вы успешно записаны')),
        );
      }
    } catch (e) {
      print('Ошибка при изменении записи: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Произошла ошибка: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isActionInProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_section?['name'] ?? 'Детали секции'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sectionEvent == null || _section == null
              ? const Center(child: Text('Данные не найдены'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_sectionEvent?['cover_url'] != null)
                        Image.network(
                          _sectionEvent!['cover_url'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      const SizedBox(height: 16),
                      Text(
                        _section!['name'],
                        //style: Theme.of(context).textTheme.headline4,
                      ),
                      const SizedBox(height: 8),
                      if (_section!['description'] != null)
                        Text(
                          _section!['description'],
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      const SizedBox(height: 16),
                      _buildInfoRow('Тренер', _section!['coach_name']),
                      _buildInfoRow('Место', _sectionEvent!['location']),
                      if (_sectionEvent!['event_date'] != null)
                        _buildInfoRow(
                          'Дата',
                          DateFormat('dd.MM.yyyy').format(
                            DateTime.parse(_sectionEvent!['event_date']),
                          ),
                        ),
                      if (_sectionEvent!['event_time'] != null)
                        _buildInfoRow('Время', _sectionEvent!['event_time']),
                      const SizedBox(height: 24),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                'Записано участников:',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$_registrationsCount/${_maxParticipants > 0 ? _maxParticipants : '∞'}',
                                //style: Theme.of(context).textTheme.headline4,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isActionInProgress
                                      ? null
                                      : _maxParticipants > 0 &&
                                              _registrationsCount >=
                                                  _maxParticipants &&
                                              !_isRegistered
                                          ? null
                                          : _toggleRegistration,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    backgroundColor: _isRegistered
                                        ? Colors.red
                                        : Theme.of(context).primaryColor,
                                  ),
                                  child: _isActionInProgress
                                      ? const CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        )
                                      : Text(
                                          _isRegistered
                                              ? 'Отменить запись'
                                              : 'Записаться',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}