import 'package:gemmea/domain/entities/calendar_event.dart';
import 'package:gemmea/domain/repositories/calendar_repository.dart';

class GetCalendarEvents {
  final CalendarRepository repository;
  GetCalendarEvents(this.repository);

  Future<List<CalendarEvent>> call() async {
    return await repository.getCalendarEvents();
  }
}

class AddCalendarEvent {
  final CalendarRepository repository;
  AddCalendarEvent(this.repository);

  Future<void> call(CalendarEvent event) async {
    await repository.addCalendarEvent(event);
  }
}

class UpdateCalendarEvent {
  final CalendarRepository repository;
  UpdateCalendarEvent(this.repository);

  Future<void> call(CalendarEvent event) async {
    await repository.updateCalendarEvent(event);
  }
}

class UpdateRainStatus {
  final CalendarRepository repository;
  UpdateRainStatus(this.repository);

  Future<void> call(String date, bool isRainy) async {
    await repository.updateRainStatus(date, isRainy);
  }
}
