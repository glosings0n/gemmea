import 'package:gemmea/domain/entities/calendar_event.dart';

abstract class CalendarRepository {
  Future<List<CalendarEvent>> getCalendarEvents();
  Future<void> addCalendarEvent(CalendarEvent event);
  Future<void> updateCalendarEvent(CalendarEvent event);
  Future<void> updateRainStatus(String date, bool isRainy);
}
