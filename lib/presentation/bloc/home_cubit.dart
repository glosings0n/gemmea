import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gemmea/domain/entities/calendar_event.dart';
import 'package:gemmea/domain/entities/diagnostic_result.dart';
import 'package:gemmea/domain/usecases/calendar_usecases.dart';
import 'package:gemmea/domain/usecases/diagnostic_usecases.dart';

abstract class HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final DiagnosticResult? lastDiagnostic;
  final List<DiagnosticResult> diagnosticsHistory;
  final List<CalendarEvent> calendarEvents;
  final String waterScheduleStatus;
  final List<String> soilReminders;

  HomeLoaded({
    this.lastDiagnostic,
    required this.diagnosticsHistory,
    required this.calendarEvents,
    required this.waterScheduleStatus,
    required this.soilReminders,
  });
}

class HomeError extends HomeState {
  final String error;
  HomeError(this.error);
}

class HomeCubit extends Cubit<HomeState> {
  final GetDiagnostics getDiagnostics;
  final GetCalendarEvents getCalendarEvents;
  final RunCropScan runCropScan;
  final UpdateRainStatus updateRainStatus;
  final MarkDiagnosticsAsRead markDiagnosticsAsRead;
  final DeleteDiagnostic deleteDiagnosticUsecase;

  HomeCubit({
    required this.getDiagnostics,
    required this.getCalendarEvents,
    required this.runCropScan,
    required this.updateRainStatus,
    required this.markDiagnosticsAsRead,
    required this.deleteDiagnosticUsecase,
  }) : super(HomeLoading());

  Future<void> markAllAsRead() async {
    try {
      await markDiagnosticsAsRead();
      await loadDashboard();
    } catch (_) {}
  }

  Future<void> loadDashboard() async {
    emit(HomeLoading());
    try {
      final diagnostics = await getDiagnostics();
      final calendar = await getCalendarEvents();
      
      final lastDiagnostic = diagnostics.isNotEmpty ? diagnostics.first : null;
      
      // Calculate water schedule status based on calendar events
      String waterStatus = "Toutes les cultures sont irriguées";
      final upcomingWatering = calendar.where((e) => !e.isRainy).toList();
      if (upcomingWatering.isNotEmpty) {
        waterStatus = "Prochain : ${upcomingWatering.first.title} le ${upcomingWatering.first.eventDate}";
      } else {
        waterStatus = "Pluie prévue - Irrigation en pause";
      }

      // Generate dynamic soil reminders
      final List<String> reminders = [];
      if (diagnostics.isNotEmpty && lastDiagnostic != null) {
        if (lastDiagnostic.disease.contains("Mosaïque") || lastDiagnostic.disease.contains("Mosaic")) {
          reminders.add("Vérifiez les herbes sauvages et mouches blanches dans vos champs de manioc.");
        } else if (lastDiagnostic.disease.contains("Rouille") || lastDiagnostic.disease.contains("Rust")) {
          reminders.add("Vaporisez une solution de neem sur les cultures de maïs.");
        }
      }
      if (calendar.any((e) => e.isRainy)) {
        reminders.add("Pluie demain ! Gardez les seaux d'engrais à l'abri.");
      } else {
        reminders.add("Alerte sol sec. Surveillez le niveau d'humidité du maïs.");
      }

      emit(HomeLoaded(
        lastDiagnostic: lastDiagnostic,
        diagnosticsHistory: diagnostics,
        calendarEvents: calendar,
        waterScheduleStatus: waterStatus,
        soilReminders: reminders,
      ));
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> scanCrop(List<int> imageBytes) async {
    // Keep current loaded state on the dashboard intact and rethrow the exception
    // so that the UI layer can display a beautiful, descriptive instructions modal.
    try {
      await runCropScan(imageBytes);
      await loadDashboard(); // Reload data with new diagnostic history
    } catch (e) {
      rethrow;
    }
  }

  Future<void> toggleRain(String date, bool isRainy) async {
    try {
      await updateRainStatus(date, isRainy);
      await loadDashboard(); // Reload data to show updated watering timetable
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }

  Future<void> deleteDiagnostic(int id) async {
    try {
      await deleteDiagnosticUsecase(id);
      await loadDashboard(); // Reload data to show updated list
    } catch (e) {
      emit(HomeError(e.toString()));
    }
  }
}
