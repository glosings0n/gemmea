import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:juamea/data/datasources/gemma_local_source.dart';
import 'package:juamea/data/datasources/sqlite_helper.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const nuruChannel = MethodChannel('com.musantek.juamea/nuru_vision');

  testWidgets('Physical Android Pixel 7: Nuru-Agri TFLite INT8 + SQLite FTS5 RAG stress benchmark', (tester) async {
    // 1. Load real bundled crop photos from assets
    final samples = <Map<String, String>>[
      {'asset': 'assets/images/cassava_mosaic.png', 'expected': 'cassava_cmd'},
      {'asset': 'assets/images/maize_rust.png', 'expected': 'maize_rust'},
      {'asset': 'assets/images/healthy_leaf.png', 'expected': 'healthy_leaf'},
    ];

    final assetBytes = <String, Uint8List>{};
    for (final s in samples) {
      final bd = await rootBundle.load(s['asset']!);
      assetBytes[s['asset']!] = bd.buffer.asUint8List();
    }

    // Warm-up call (measures cold model load + first inference on real ARM64 TFLite)
    final coldSw = Stopwatch()..start();
    final coldProbs = await nuruChannel.invokeMethod<List<dynamic>>(
      'classifyCrop',
      {'imageBytes': assetBytes['assets/images/cassava_mosaic.png']!},
    );
    coldSw.stop();
    expect(coldProbs, isNotNull);
    expect(coldProbs!.length, equals(9));

    // 2. Sustained 150-iteration real TFLite INT8 hardware stress loop on Pixel 7
    final latenciesMs = <double>[];
    final firstPassPredictions = <String, Map<String, dynamic>>{};
    const totalIterations = 150;
    final loopSw = Stopwatch()..start();

    for (var i = 0; i < totalIterations; i++) {
      final sample = samples[i % samples.length];
      final bytes = assetBytes[sample['asset']!]!;
      final sw = Stopwatch()..start();
      final raw = await nuruChannel.invokeMethod<List<dynamic>>(
        'classifyCrop',
        {'imageBytes': bytes},
      );
      sw.stop();
      latenciesMs.add(sw.elapsedMicroseconds / 1000.0);

      if (i < samples.length) {
        final probs = raw!.map((e) => (e as num).toDouble()).toList();
        var bestIdx = 0;
        for (var j = 1; j < probs.length; j++) {
          if (probs[j] > probs[bestIdx]) bestIdx = j;
        }
        firstPassPredictions[sample['asset']!] = {
          'expected': sample['expected'],
          'predicted': NuruTfliteDecoder.labels[bestIdx],
          'confidence': double.parse(probs[bestIdx].toStringAsFixed(4)),
        };
      }
    }
    loopSw.stop();
    latenciesMs.sort();
    final avgMs = latenciesMs.reduce((a, b) => a + b) / latenciesMs.length;
    final p50Ms = latenciesMs[latenciesMs.length ~/ 2];
    final p95Ms = latenciesMs[(latenciesMs.length * 0.95).floor()];
    final maxMs = latenciesMs.last;

    // 3. Real Android sqflite FTS5 RAG benchmark across 6 EAC/DRC countries
    final ragQueries = <String>[
      'manioc mosaique CMD RDC INERA boutures',
      'mais chenille legionnaire FAW push pull desmodium',
      'bananier cercosporiose noire sigatoka Rwanda RAB',
      'haricot tache angulaire Burundi ISABU',
      'cassava brown streak CBSD Uganda Tanzania',
      'maize common rust Kenya KALRO',
    ];
    final ragLatenciesMs = <double>[];
    final ragHits = <String, int>{};
    for (final q in ragQueries) {
      final sw = Stopwatch()..start();
      final rows = await SQLiteHelper.instance.searchFAOKnowledge(q);
      sw.stop();
      ragLatenciesMs.add(sw.elapsedMicroseconds / 1000.0);
      ragHits[q] = rows.length;
      expect(rows, isNotEmpty, reason: 'SQLite FTS5 returned 0 rows for: $q');
    }

    // 4. Full End-to-End Production evaluateCropImage() on Pixel 7 (Pass-1 TFLite -> Ranked FTS4 -> Deterministic Card)
    final tmpImg = File('${Directory.systemTemp.path}/pixel7_cassava_live.png');
    await tmpImg.writeAsBytes(assetBytes['assets/images/cassava_mosaic.png']!, flush: true);
    final e2eSw = Stopwatch()..start();
    final prodSource = GemmaLocalSourceImpl();
    final report = await prodSource.evaluateCropImage(tmpImg, 'Diagnostic manioc complet');
    e2eSw.stop();
    if (await tmpImg.exists()) {
      await tmpImg.delete();
    }
    expect(report, contains('DIAGNOSTIC PRINCIPAL'));
    expect(report, contains('Manioc'));
    expect(report.length, greaterThan(150));

    final summary = {
      'platform': Platform.operatingSystem,
      'os_version': Platform.operatingSystemVersion,
      'process_current_rss_mb': double.parse((ProcessInfo.currentRss / (1024 * 1024)).toStringAsFixed(2)),
      'process_max_rss_mb': double.parse((ProcessInfo.maxRss / (1024 * 1024)).toStringAsFixed(2)),
      'nuru_cold_start_ms': coldSw.elapsedMilliseconds,
      'nuru_iterations': totalIterations,
      'nuru_total_wall_ms': loopSw.elapsedMilliseconds,
      'nuru_avg_ms': double.parse(avgMs.toStringAsFixed(2)),
      'nuru_p50_ms': double.parse(p50Ms.toStringAsFixed(2)),
      'nuru_p95_ms': double.parse(p95Ms.toStringAsFixed(2)),
      'nuru_max_ms': double.parse(maxMs.toStringAsFixed(2)),
      'first_pass_predictions': firstPassPredictions,
      'rag_avg_ms': double.parse(
        (ragLatenciesMs.reduce((a, b) => a + b) / ragLatenciesMs.length).toStringAsFixed(2),
      ),
      'rag_hits': ragHits,
      'e2e_pass1_pass2_ms': e2eSw.elapsedMilliseconds,
      'e2e_report_chars': report.length,
    };
    // Emit structured telemetry marker for ADB logcat / flutter test capture
    // ignore: avoid_print
    print('PIXEL7_JUAMEA_BENCH_JSON=${jsonEncode(summary)}');
  });
}
