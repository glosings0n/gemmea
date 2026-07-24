import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gemmea/domain/entities/diagnostic_result.dart';
import 'package:gemmea/domain/entities/calendar_event.dart';
import 'package:gemmea/domain/usecases/diagnostic_usecases.dart';
import 'package:gemmea/domain/usecases/calendar_usecases.dart';
import 'package:gemmea/presentation/bloc/home_cubit.dart';

class MockGetDiagnostics extends Mock implements GetDiagnostics {}
class MockGetCalendarEvents extends Mock implements GetCalendarEvents {}
class MockRunCropScan extends Mock implements RunCropScan {}
class MockUpdateRainStatus extends Mock implements UpdateRainStatus {}
class MockMarkDiagnosticsAsRead extends Mock implements MarkDiagnosticsAsRead {}
class MockDeleteDiagnostic extends Mock implements DeleteDiagnostic {}

void main() {
  late MockGetDiagnostics mockGetDiagnostics;
  late MockGetCalendarEvents mockGetCalendarEvents;
  late MockRunCropScan mockRunCropScan;
  late MockUpdateRainStatus mockUpdateRainStatus;
  late MockMarkDiagnosticsAsRead mockMarkDiagnosticsAsRead;
  late MockDeleteDiagnostic mockDeleteDiagnostic;
  late HomeCubit homeCubit;

  setUp(() {
    mockGetDiagnostics = MockGetDiagnostics();
    mockGetCalendarEvents = MockGetCalendarEvents();
    mockRunCropScan = MockRunCropScan();
    mockUpdateRainStatus = MockUpdateRainStatus();
    mockMarkDiagnosticsAsRead = MockMarkDiagnosticsAsRead();
    mockDeleteDiagnostic = MockDeleteDiagnostic();

    homeCubit = HomeCubit(
      getDiagnostics: mockGetDiagnostics,
      getCalendarEvents: mockGetCalendarEvents,
      runCropScan: mockRunCropScan,
      updateRainStatus: mockUpdateRainStatus,
      markDiagnosticsAsRead: mockMarkDiagnosticsAsRead,
      deleteDiagnosticUsecase: mockDeleteDiagnostic,
    );
  });

  tearDown(() {
    homeCubit.close();
  });

  group('HomeCubit Tests', () {
    test('initial state is HomeLoading', () {
      expect(homeCubit.state, isA<HomeLoading>());
    });

    blocTest<HomeCubit, HomeState>(
      'loadDashboard emits HomeLoading then HomeLoaded with empty values and default water schedule',
      build: () {
        when(() => mockGetDiagnostics.call()).thenAnswer((_) async => []);
        when(() => mockGetCalendarEvents.call()).thenAnswer((_) async => []);
        return homeCubit;
      },
      act: (cubit) => cubit.loadDashboard(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>().having(
          (s) => s.waterScheduleStatus,
          'waterStatus',
          contains("Pluie prévue - Irrigation en pause"),
        ).having(
          (s) => s.soilReminders.first,
          'soilReminders',
          contains("Alerte sol sec. Surveillez le niveau d'humidité du maïs."),
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'loadDashboard with Cassava Mosaic diagnostic emits HomeLoaded with custom crop reminders',
      build: () {
        final mockDiagnostics = [
          DiagnosticResult(
            id: 1,
            cropName: "Cassava",
            disease: "Cassava Mosaic Disease",
            confidence: 0.88,
            remedy: "Uproot infected stems.",
            timestamp: DateTime.now(),
            status: 'new',
          )
        ];
        final mockCalendar = [
          CalendarEvent(
            id: 1,
            title: "Cassava Watering",
            eventDate: "2026-07-10",
            description: "Water roots.",
            isRainy: false,
          )
        ];
        when(() => mockGetDiagnostics.call()).thenAnswer((_) async => mockDiagnostics);
        when(() => mockGetCalendarEvents.call()).thenAnswer((_) async => mockCalendar);
        return homeCubit;
      },
      act: (cubit) => cubit.loadDashboard(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>().having(
          (s) => s.waterScheduleStatus,
          'waterStatus',
          contains("Prochain : Cassava Watering le 2026-07-10"),
        ).having(
          (s) => s.soilReminders.first,
          'reminder alert',
          contains("Vérifiez les herbes sauvages et mouches blanches dans vos champs de manioc."),
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'loadDashboard with Maize Rust diagnostic emits HomeLoaded with maize-specific reminders',
      build: () {
        final mockDiagnostics = [
          DiagnosticResult(
            id: 2,
            cropName: "Maize",
            disease: "Maize Common Rust",
            confidence: 0.90,
            remedy: "Apply neem oil.",
            timestamp: DateTime.now(),
            status: 'read',
          )
        ];
        when(() => mockGetDiagnostics.call()).thenAnswer((_) async => mockDiagnostics);
        when(() => mockGetCalendarEvents.call()).thenAnswer((_) async => []);
        return homeCubit;
      },
      act: (cubit) => cubit.loadDashboard(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>().having(
          (s) => s.soilReminders.first,
          'reminder alert',
          contains("Vaporisez une solution de neem sur les cultures de maïs."),
        ),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'markAllAsRead calls markDiagnosticsAsRead and reloads dashboard',
      build: () {
        when(() => mockMarkDiagnosticsAsRead.call()).thenAnswer((_) async {});
        when(() => mockGetDiagnostics.call()).thenAnswer((_) async => []);
        when(() => mockGetCalendarEvents.call()).thenAnswer((_) async => []);
        return homeCubit;
      },
      act: (cubit) => cubit.markAllAsRead(),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>(),
      ],
      verify: (_) {
        verify(() => mockMarkDiagnosticsAsRead.call()).called(1);
        verify(() => mockGetDiagnostics.call()).called(1);
      },
    );

    blocTest<HomeCubit, HomeState>(
      'deleteDiagnostic calls deleteDiagnosticUsecase and reloads dashboard',
      build: () {
        when(() => mockDeleteDiagnostic.call(any())).thenAnswer((_) async {});
        when(() => mockGetDiagnostics.call()).thenAnswer((_) async => []);
        when(() => mockGetCalendarEvents.call()).thenAnswer((_) async => []);
        return homeCubit;
      },
      act: (cubit) => cubit.deleteDiagnostic(15),
      expect: () => [
        isA<HomeLoading>(),
        isA<HomeLoaded>(),
      ],
      verify: (_) {
        verify(() => mockDeleteDiagnostic.call(15)).called(1);
        verify(() => mockGetDiagnostics.call()).called(1);
      },
    );
  });
}
