import 'package:gemmea/data/datasources/sqlite_helper.dart';
import 'package:gemmea/domain/entities/calendar_event.dart';
import 'package:gemmea/domain/repositories/calendar_repository.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final SQLiteHelper dbHelper = SQLiteHelper.instance;

  @override
  Future<List<CalendarEvent>> getCalendarEvents() async {
    final list = await dbHelper.getCalendarEvents();
    return list.map((m) => CalendarEvent.fromMap(m)).toList();
  }

  @override
  Future<void> addCalendarEvent(CalendarEvent event) async {
    await dbHelper.insertCalendarEvent(event.toMap());
  }

  @override
  Future<void> updateCalendarEvent(CalendarEvent event) async {
    if (event.id != null) {
      await dbHelper.updateCalendarEvent(event.id!, event.toMap());
    }
  }

  @override
  Future<void> updateRainStatus(String date, bool isRainy) async {
    await dbHelper.updateRainStatus(date, isRainy ? 1 : 0);
  }
}
