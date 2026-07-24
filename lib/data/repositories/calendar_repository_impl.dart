import 'dart:developer' as dev;
import 'package:gemmea/data/datasources/sqlite_helper.dart';
import 'package:gemmea/domain/entities/calendar_event.dart';
import 'package:gemmea/domain/repositories/calendar_repository.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  final SQLiteHelper dbHelper = SQLiteHelper.instance;

  @override
  Future<List<CalendarEvent>> getCalendarEvents() async {
    try {
      dev.log("Fetching calendar events...", name: 'CALENDAR_REPO_IMPL');
      final list = await dbHelper.getCalendarEvents();
      return list.map((m) => CalendarEvent.fromMap(m)).toList();
    } catch (e, stack) {
      dev.log("Error getting calendar events", name: 'CALENDAR_REPO_IMPL', error: e, stackTrace: stack);
      return [];
    }
  }

  @override
  Future<void> addCalendarEvent(CalendarEvent event) async {
    try {
      dev.log("Adding calendar event: ${event.title}", name: 'CALENDAR_REPO_IMPL');
      await dbHelper.insertCalendarEvent(event.toMap());
    } catch (e, stack) {
      dev.log("Error adding calendar event", name: 'CALENDAR_REPO_IMPL', error: e, stackTrace: stack);
    }
  }

  @override
  Future<void> updateCalendarEvent(CalendarEvent event) async {
    try {
      if (event.id != null) {
        dev.log("Updating calendar event ID: ${event.id}", name: 'CALENDAR_REPO_IMPL');
        await dbHelper.updateCalendarEvent(event.id!, event.toMap());
      }
    } catch (e, stack) {
      dev.log("Error updating calendar event", name: 'CALENDAR_REPO_IMPL', error: e, stackTrace: stack);
    }
  }

  @override
  Future<void> updateRainStatus(String date, bool isRainy) async {
    try {
      dev.log("Updating rain status for date $date: $isRainy", name: 'CALENDAR_REPO_IMPL');
      await dbHelper.updateRainStatus(date, isRainy ? 1 : 0);
    } catch (e, stack) {
      dev.log("Error updating rain status", name: 'CALENDAR_REPO_IMPL', error: e, stackTrace: stack);
    }
  }
}
