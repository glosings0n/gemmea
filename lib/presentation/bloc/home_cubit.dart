import 'dart:developer' as dev;
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
      dev.log("Marking all diagnostics as read on dashboard...", name: 'HOME_CUBIT');
      await markDiagnosticsAsRead();
      await loadDashboard();
    } catch (e, stack) {
      dev.log("Error marking diagnostics read", name: 'HOME_CUBIT', error: e, stackTrace: stack);
    }
  }

  Future<void> loadDashboard() async {
    emit(HomeLoading());
    try {
      dev.log("Loading dashboard data...", name: 'HOME_CUBIT');
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
    } catch (e, stack) {
      dev.log("Error loading dashboard", name: 'HOME_CUBIT', error: e, stackTrace: stack);
      emit(HomeError(e.toString()));
    }
  }

  Future<void> scanCrop(List<int> imageBytes) async {
    try {
      dev.log("Running scanCrop from HomeCubit...", name: 'HOME_CUBIT');
      await runCropScan(imageBytes);
      await loadDashboard(); // Reload data with new diagnostic history
    } catch (e, stack) {
      dev.log("scanCrop error passed to UI layer", name: 'HOME_CUBIT', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> toggleRain(String date, bool isRainy) async {
    try {
      dev.log("Toggling rain for date $date: $isRainy", name: 'HOME_CUBIT');
      await updateRainStatus(date, isRainy);
      await loadDashboard(); // Reload data to show updated watering timetable
    } catch (e, stack) {
      dev.log("Error toggling rain", name: 'HOME_CUBIT', error: e, stackTrace: stack);
      emit(HomeError(e.toString()));
    }
  }

  Future<void> deleteDiagnostic(int id) async {
    try {
      dev.log("Deleting diagnostic ID: $id", name: 'HOME_CUBIT');
      await deleteDiagnosticUsecase(id);
      await loadDashboard(); // Reload data to show updated list
    } catch (e, stack) {
      dev.log("Error deleting diagnostic", name: 'HOME_CUBIT', error: e, stackTrace: stack);
      emit(HomeError(e.toString()));
    }
  }
}
