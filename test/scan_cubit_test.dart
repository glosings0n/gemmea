import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart' show databaseFactory;
import 'package:sqflite/src/factory_impl.dart' show sqfliteDatabaseFactory;
import 'package:gemmea/data/datasources/gemma_local_source.dart';
import 'package:gemmea/presentation/bloc/scan_cubit.dart';

class MockGemmaLocalSource extends Mock implements GemmaLocalSource {}

class MockFile extends Mock implements File {}

class FakeFile extends Fake implements File {}

void main() {
  late MockGemmaLocalSource mockGemmaLocalSource;
  late MockFile mockFile;
  late ScanCubit scanCubit;

  setUpAll(() {
    registerFallbackValue(FakeFile());
    TestWidgetsFlutterBinding.ensureInitialized();
    databaseFactory = sqfliteDatabaseFactory;

    const MethodChannel channel = MethodChannel('com.tekartik.sqflite');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getDatabasesPath':
              return '/mock/path';
            case 'openDatabase':
              return 1; // Database ID
            case 'insert':
              return 1; // Row ID
            case 'query':
              return <Map<String, dynamic>>[];
            case 'execute':
              return null;
            case 'delete':
              return 0;
            case 'update':
              return 0;
            default:
              return null;
          }
        });
  });

  setUp(() {
    mockGemmaLocalSource = MockGemmaLocalSource();
    mockFile = MockFile();
    when(() => mockFile.path).thenReturn('/mock/temp/cassava.png');

    scanCubit = ScanCubit(mockGemmaLocalSource);
  });

  tearDown(() {
    scanCubit.close();
  });

  group('ScanCubit Tests', () {
    test('initial state is ScanInitial', () {
      expect(scanCubit.state, isA<ScanInitial>());
    });

    blocTest<ScanCubit, ScanState>(
      'analyzeCrop parses Cassava Mosaic Disease and emits ScanSuccess with DB insert',
      build: () {
        when(
          () => mockGemmaLocalSource.evaluateCropImage(any(), any()),
        ).thenAnswer(
          (_) async => "This is a Cassava leaf with Mosaic viral symptoms.",
        );
        return scanCubit;
      },
      act: (cubit) => cubit.analyzeCrop(mockFile),
      expect: () => [
        isA<ScanProcessing>(),
        isA<ScanSuccess>().having(
          (s) => s.diagnosis,
          'diagnosis',
          contains("This is a Cassava leaf with Mosaic viral symptoms."),
        ),
      ],
      verify: (_) {
        verify(
          () => mockGemmaLocalSource.evaluateCropImage(mockFile, any()),
        ).called(1);
      },
    );

    blocTest<ScanCubit, ScanState>(
      'analyzeCrop parses Maize Common Rust and emits ScanSuccess with DB insert',
      build: () {
        when(
          () => mockGemmaLocalSource.evaluateCropImage(any(), any()),
        ).thenAnswer(
          (_) async => "This maize leaf is covered in common rust spores.",
        );
        return scanCubit;
      },
      act: (cubit) => cubit.analyzeCrop(mockFile),
      expect: () => [
        isA<ScanProcessing>(),
        isA<ScanSuccess>().having(
          (s) => s.diagnosis,
          'diagnosis',
          contains("This maize leaf is covered in common rust spores."),
        ),
      ],
    );

    blocTest<ScanCubit, ScanState>(
      'analyzeCrop parses Healthy Leaf and emits ScanSuccess with DB insert',
      build: () {
        when(
          () => mockGemmaLocalSource.evaluateCropImage(any(), any()),
        ).thenAnswer((_) async => "The plant tissue is completely healthy.");
        return scanCubit;
      },
      act: (cubit) => cubit.analyzeCrop(mockFile),
      expect: () => [
        isA<ScanProcessing>(),
        isA<ScanSuccess>().having(
          (s) => s.diagnosis,
          'diagnosis',
          contains("The plant tissue is completely healthy."),
        ),
      ],
    );

    blocTest<ScanCubit, ScanState>(
      'analyzeCrop handles evaluation failures gracefully and emits ScanFailure',
      build: () {
        when(
          () => mockGemmaLocalSource.evaluateCropImage(any(), any()),
        ).thenThrow(Exception("LiteRT GPU initialization failure"));
        return scanCubit;
      },
      act: (cubit) => cubit.analyzeCrop(mockFile),
      expect: () => [
        isA<ScanProcessing>(),
        isA<ScanFailure>().having(
          (s) => s.error,
          'error text',
          contains("LiteRT GPU initialization failure"),
        ),
      ],
    );
  });
}
