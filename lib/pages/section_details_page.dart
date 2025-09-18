import 'package:flutter/material.dart';

class SectionDetailsPage extends StatefulWidget {
  // final String sectionEventId;
  // const SectionDetailsPage({super.key, required this.sectionEventId});
  
  const SectionDetailsPage({super.key});

  @override
  State<SectionDetailsPage> createState() => _SectionDetailsPageState();
}

class _SectionDetailsPageState extends State<SectionDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // TODO: Название секции будет загружаться из базы данных
        title: const Text('Детали секции'),
      ),
      body: const Center(
        child: Text(
          'Здесь будет вся информация о конкретной секции и запись на нее',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
// ---
// ЗАДАЧИ ДЛЯ КОМАНДЫ:
// 1. Научить страницу принимать `sectionEventId` через аргументы навигации.
// 2. При загрузке страницы сделать запрос к Supabase, чтобы получить:
//    - Данные о секции из таблицы `section_events` по `sectionEventId`.
//    - Количество записавшихся из таблицы `event_registrations`.
// 3. Сверстать страницу:
//    - Название, описание, имя тренера (`coach_name`), место (`location`), дата и время.
//    - Красивый счетчик: "Записано X из Y человек".
// 4. Реализовать кнопку "Записаться" / "Отменить запись":
//    - Проверить, есть ли ID текущего котенка в `event_registrations` для этой секции.
//    - Если нет - показать кнопку "Записаться".
//    - Если есть - показать кнопку "Отменить запись".
//    - Кнопка "Записаться" должна быть неактивной, если X=Y (нет мест).
//    - При нажатии - добавлять/удалять запись в `event_registrations`.
// 5. **(Сложная задача):** Для предотвращения "гонки" за последнее место,
//    логику записи лучше вынести в Supabase Edge Function.
// ---