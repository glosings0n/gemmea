import 'dart:developer' as dev;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:juamea/core/localization/localization.dart';
import 'package:juamea/data/datasources/sqlite_helper.dart';
import 'package:juamea/domain/entities/calendar_event.dart';
import 'package:juamea/domain/entities/diagnostic_result.dart';
import 'package:juamea/domain/usecases/calendar_usecases.dart';
import 'package:juamea/domain/usecases/diagnostic_usecases.dart';

abstract class HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final DiagnosticResult? lastDiagnostic;
  final List<DiagnosticResult> diagnosticsHistory;
  final List<CalendarEvent> calendarEvents;
  final String waterScheduleStatus;
  final List<String> soilReminders;
  final String selectedCountryCode;

  HomeLoaded({
    this.lastDiagnostic,
    required this.diagnosticsHistory,
    required this.calendarEvents,
    required this.waterScheduleStatus,
    required this.soilReminders,
    this.selectedCountryCode = 'CD',
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
      await loadDashboard(isSilent: true);
    } catch (e, stack) {
      dev.log("Error marking diagnostics read", name: 'HOME_CUBIT', error: e, stackTrace: stack);
    }
  }

  Future<void> loadDashboard({bool isSilent = false}) async {
    if (!isSilent || state is! HomeLoaded) {
      emit(HomeLoading());
    }
    try {
      dev.log("Loading dashboard data (isSilent: $isSilent)...", name: 'HOME_CUBIT');
      final diagnostics = await getDiagnostics();
      final calendar = await getCalendarEvents();
      
      final strings = JuameaStrings.of(
        JuameaLanguageX.fromCode(SQLiteHelper.currentLanguageCode),
      );
      final lastDiagnostic = diagnostics.isNotEmpty ? diagnostics.first : null;
      
      // Calculate water schedule status based on calendar events
      String waterStatus = strings.waterAllIrrigated;
      final upcomingWatering = calendar.where((e) => !e.isRainy).toList();
      if (upcomingWatering.isNotEmpty) {
        waterStatus =
            "${strings.waterNextPrefix} : ${upcomingWatering.first.title} ${strings.waterOnDateWord} ${upcomingWatering.first.eventDate}";
      } else {
        waterStatus = strings.waterRainPausedStatus;
      }

      // Generate dynamic soil reminders
      final List<String> reminders = [];
      if (diagnostics.isNotEmpty && lastDiagnostic != null) {
        if (lastDiagnostic.disease.contains("Mosaïque") || lastDiagnostic.disease.contains("Mosaic")) {
          reminders.add(strings.reminderCassavaMosaic);
        } else if (lastDiagnostic.disease.contains("Rouille") || lastDiagnostic.disease.contains("Rust")) {
          reminders.add(strings.reminderMaizeRust);
        }
      }
      if (calendar.any((e) => e.isRainy)) {
        reminders.add(strings.reminderRainTomorrow);
      } else {
        reminders.add(strings.reminderDrySoil);
      }

      final countryCode = await SQLiteHelper.instance.getSelectedCountryCode();

      emit(HomeLoaded(
        lastDiagnostic: lastDiagnostic,
        diagnosticsHistory: diagnostics,
        calendarEvents: calendar,
        waterScheduleStatus: waterStatus,
        soilReminders: reminders,
        selectedCountryCode: countryCode,
      ));
    } catch (e, stack) {
      dev.log("Error loading dashboard", name: 'HOME_CUBIT', error: e, stackTrace: stack);
      if (state is! HomeLoaded) {
        emit(HomeError(e.toString()));
      }
    }
  }

  Future<void> scanCrop(List<int> imageBytes) async {
    try {
      dev.log("Running scanCrop from HomeCubit...", name: 'HOME_CUBIT');
      await runCropScan(imageBytes);
      await loadDashboard(isSilent: true); // Reload data silently
    } catch (e, stack) {
      dev.log("scanCrop error passed to UI layer", name: 'HOME_CUBIT', error: e, stackTrace: stack);
      rethrow;
    }
  }

  Future<void> setEacCountry(String countryCode) async {
    final normalized = countryCode.trim().toUpperCase();
    if (normalized.isEmpty) return;
    await SQLiteHelper.instance.setSelectedCountryCode(normalized);
    if (state is HomeLoaded) {
      final current = state as HomeLoaded;
      emit(HomeLoaded(
        lastDiagnostic: current.lastDiagnostic,
        diagnosticsHistory: current.diagnosticsHistory,
        calendarEvents: current.calendarEvents,
        waterScheduleStatus: current.waterScheduleStatus,
        soilReminders: current.soilReminders,
        selectedCountryCode: normalized,
      ));
    }
  }

  Future<void> toggleRain(String date, bool isRainy) async {
    try {
      dev.log("Toggling rain for date $date: $isRainy", name: 'HOME_CUBIT');
      
      // 1. Optimistic state update if currently in HomeLoaded
      if (state is HomeLoaded) {
        final currentState = state as HomeLoaded;
        final updatedCalendar = currentState.calendarEvents.map((e) {
          if (e.eventDate == date) {
            return e.copyWith(isRainy: isRainy);
          }
          return e;
        }).toList();

        final strings = JuameaStrings.of(
          JuameaLanguageX.fromCode(SQLiteHelper.currentLanguageCode),
        );
        String waterStatus = strings.waterAllIrrigated;
        final upcomingWatering = updatedCalendar.where((e) => !e.isRainy).toList();
        if (upcomingWatering.isNotEmpty) {
          waterStatus =
              "${strings.waterNextPrefix} : ${upcomingWatering.first.title} ${strings.waterOnDateWord} ${upcomingWatering.first.eventDate}";
        } else {
          waterStatus = strings.waterRainPausedStatus;
        }

        final List<String> reminders = List.from(currentState.soilReminders);
        if (updatedCalendar.any((e) => e.isRainy)) {
          if (!reminders.contains(strings.reminderRainTomorrow)) {
            reminders.add(strings.reminderRainTomorrow);
          }
          reminders.remove(strings.reminderDrySoil);
        } else {
          if (!reminders.contains(strings.reminderDrySoil)) {
            reminders.add(strings.reminderDrySoil);
          }
          reminders.remove(strings.reminderRainTomorrow);
        }

        emit(HomeLoaded(
          lastDiagnostic: currentState.lastDiagnostic,
          diagnosticsHistory: currentState.diagnosticsHistory,
          calendarEvents: updatedCalendar,
          waterScheduleStatus: waterStatus,
          soilReminders: reminders,
          selectedCountryCode: currentState.selectedCountryCode,
        ));
      }

      // 2. Persist in DB
      await updateRainStatus(date, isRainy);

      // 3. Silent refresh in background to ensure database consistency
      await loadDashboard(isSilent: true);
    } catch (e, stack) {
      dev.log("Error toggling rain", name: 'HOME_CUBIT', error: e, stackTrace: stack);
      await loadDashboard(isSilent: true);
    }
  }

  Future<void> deleteDiagnostic(int id) async {
    try {
      dev.log("Deleting diagnostic ID: $id", name: 'HOME_CUBIT');
      
      // Optimistic remove if in HomeLoaded
      if (state is HomeLoaded) {
        final currentState = state as HomeLoaded;
        final updatedHistory = currentState.diagnosticsHistory.where((d) => d.id != id).toList();
        final lastDiagnostic = updatedHistory.isNotEmpty ? updatedHistory.first : null;

        emit(HomeLoaded(
          lastDiagnostic: lastDiagnostic,
          diagnosticsHistory: updatedHistory,
          calendarEvents: currentState.calendarEvents,
          waterScheduleStatus: currentState.waterScheduleStatus,
          soilReminders: currentState.soilReminders,
          selectedCountryCode: currentState.selectedCountryCode,
        ));
      }

      await deleteDiagnosticUsecase(id);
      await loadDashboard(isSilent: true);
    } catch (e, stack) {
      dev.log("Error deleting diagnostic", name: 'HOME_CUBIT', error: e, stackTrace: stack);
      await loadDashboard(isSilent: true);
    }
  }
}
