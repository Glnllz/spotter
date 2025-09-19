import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SectionsPage extends StatefulWidget {
  const SectionsPage({super.key});

  @override
  State<SectionsPage> createState() => _SectionsPageState();
}

class _SectionsPageState extends State<SectionsPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _sections = [];
  List<Map<String, dynamic>> _filteredSections = [];
  bool _isLoading = true;
  
  // Контроллеры для полей ввода дат
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  
  // Форматтер для дат
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _loadSections();
    
    // Устанавливаем начальные даты (сегодня и через 5 дней)
    final now = DateTime.now();
    _startDateController.text = _dateFormat.format(now);
    _endDateController.text = _dateFormat.format(now.add(const Duration(days: 5)));
  }

  Future<void> _loadSections() async {
    try {
      // Загружаем секции
      final sectionsData = await _supabase
          .from('sections')
          .select('*')
          .order('created_at', ascending: false);

      // Для каждой секции загружаем события и регистрации
      List<Map<String, dynamic>> sectionsWithRegistrations = [];
      
      for (var section in sectionsData) {
        // Загружаем события для этой секции
        final eventsData = await _supabase
            .from('section_events')
            .select('*')
            .eq('section_id', section['id']);
        
        // Для каждого события загружаем регистрации
        List<Map<String, dynamic>> eventsWithRegistrations = [];
        
        for (var event in eventsData) {
          final registrationsData = await _supabase
              .from('event_registrations')
              .select('*')
              .eq('event_id', event['id']);
          
          eventsWithRegistrations.add({
            ...event,
            'registrations': registrationsData,
          });
        }
        
        sectionsWithRegistrations.add({
          ...section,
          'events': eventsWithRegistrations,
        });
      }

      setState(() {
        _sections = sectionsWithRegistrations;
        _applyDateFilter();
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка при загрузке секций: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyDateFilter() {
    if (_startDateController.text.isEmpty || _endDateController.text.isEmpty) {
      setState(() {
        _filteredSections = _sections;
      });
      return;
    }

    try {
      final startDate = _dateFormat.parse(_startDateController.text);
      final endDate = _dateFormat.parse(_endDateController.text);

      setState(() {
        _filteredSections = _sections.where((section) {
          final events = section['events'] as List? ?? [];
          
          // Проверяем, есть ли регистрации в выбранном диапазоне дат
          return events.any((event) {
            final registrations = event['registrations'] as List? ?? [];
            
            return registrations.any((registration) {
              final registeredAtStr = registration['registered_at'] as String?;
              if (registeredAtStr == null) return false;
              
              try {
                // Парсим дату регистрации
                final registeredAt = DateTime.parse(registeredAtStr);
                final registeredDate = DateTime(registeredAt.year, registeredAt.month, registeredAt.day);
                
                return registeredDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                       registeredDate.isBefore(endDate.add(const Duration(days: 1)));
              } catch (e) {
                print('Ошибка парсинга даты регистрации: $registeredAtStr');
                return false;
              }
            });
          });
        }).toList();
      });
    } catch (e) {
      print('Ошибка при фильтрации по датам: $e');
      setState(() {
        _filteredSections = _sections;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    
    if (picked != null) {
      controller.text = _dateFormat.format(picked);
      _applyDateFilter();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Спортивные секции'),
      ),
      body: Column(
        children: [
          // Фильтр по датам
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Фильтр по дате регистрации:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _startDateController,
                        decoration: const InputDecoration(
                          labelText: 'Начальная дата',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context, _startDateController),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _endDateController,
                        decoration: const InputDecoration(
                          labelText: 'Конечная дата',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        readOnly: true,
                        onTap: () => _selectDate(context, _endDateController),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _applyDateFilter,
                  child: const Text('Применить фильтр'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredSections.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Секции не найдены'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadSections,
                              child: const Text('Обновить'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredSections.length,
                        itemBuilder: (context, index) {
                          final section = _filteredSections[index];
                          final events = section['events'] as List? ?? [];
                          
                          return _SectionCard(
                            id: section['id'],
                            name: section['name'],
                            description: section['description'],
                            coachName: section['coach_name'],
                            events: events,
                            dateFilter: {
                              'start': _startDateController.text,
                              'end': _endDateController.text,
                            },
                            onTap: () {
                              if (events.isNotEmpty) {
                                Navigator.of(context).pushNamed(
                                  '/section-details',
                                  arguments: events.first['id'], // передаем ID первого события
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Нет событий для этой секции')),
                                );
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String id;
  final String name;
  final String? description;
  final String? coachName;
  final List<dynamic> events;
  final Map<String, String> dateFilter;
  final VoidCallback onTap;

  const _SectionCard({
    required this.id,
    required this.name,
    this.description,
    this.coachName,
    required this.events,
    required this.dateFilter,
    required this.onTap,
  });

  // Метод для получения регистраций в выбранном диапазоне дат
  List<dynamic> _getRegistrationsInDateRange() {
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd');
    final startDate = dateFormat.parse(dateFilter['start']!);
    final endDate = dateFormat.parse(dateFilter['end']!);
    
    List<dynamic> allRegistrations = [];
    
    for (var event in events) {
      final registrations = event['registrations'] as List? ?? [];
      
      for (var registration in registrations) {
        final registeredAtStr = registration['registered_at'] as String?;
        if (registeredAtStr == null) continue;
        
        try {
          final registeredAt = DateTime.parse(registeredAtStr);
          final registeredDate = DateTime(registeredAt.year, registeredAt.month, registeredAt.day);
          
          if (registeredDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
              registeredDate.isBefore(endDate.add(const Duration(days: 1)))) {
            allRegistrations.add({
              'event': event,
              'registration': registration,
            });
          }
        } catch (e) {
          continue;
        }
      }
    }
    
    return allRegistrations;
  }

  @override
  Widget build(BuildContext context) {
    final registrations = _getRegistrationsInDateRange();
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        child: Padding(
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
              if (coachName != null && coachName!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Тренер: $coachName',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              if (registrations.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Регистраций в выбранном диапазоне: ${registrations.length}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      ...registrations.take(3).map((item) {
                        final event = item['event'];
                        final registration = item['registration'];
                        final registeredAt = DateTime.parse(registration['registered_at'] as String);
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '• ${event['location']} - ${DateFormat('yyyy-MM-dd').format(registeredAt)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}