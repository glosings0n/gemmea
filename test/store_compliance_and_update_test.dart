import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:juamea/core/services/juamea_model_manager.dart';

void main() {
  group('Juamea Store Compliance, Cryptographic HF Update & Private Vault Lifecycle', () {
    test('AndroidManifest.xml contains ZERO Play-Store-banned storage permissions', () {
      final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
      expect(manifest, isNot(contains('MANAGE_EXTERNAL_STORAGE')));
      expect(manifest, isNot(contains('READ_EXTERNAL_STORAGE')));
      expect(manifest, isNot(contains('WRITE_EXTERNAL_STORAGE')));
      expect(manifest, isNot(contains('requestLegacyExternalStorage')));
      expect(manifest, contains('android:allowBackup="false"'));
      expect(manifest, contains('android:screenOrientation="portrait"'));
      expect(manifest, contains('android.hardware.camera'));
      expect(manifest, contains('android:required="false"'));
    });

    test('Shorebird OTA release & patch configuration is present', () {
      final shorebirdYaml = File('shorebird.yaml').readAsStringSync();
      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(shorebirdYaml, contains('app_id:'));
      expect(pubspec, contains('shorebird_code_push:'));
      expect(pubspec, contains('- shorebird.yaml'));
    });

    test('iOS Info.plist declares export compliance, portrait lock and all required privacy descriptions', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(plist, contains('ITSAppUsesNonExemptEncryption'));
      expect(plist, contains('NSCameraUsageDescription'));
      expect(plist, contains('NSPhotoLibraryUsageDescription'));
      expect(plist, contains('NSMicrophoneUsageDescription'));
      expect(plist, contains('NSSpeechRecognitionUsageDescription'));
      expect(plist, isNot(contains('UIInterfaceOrientationLandscapeLeft')));
      expect(plist, isNot(contains('UIInterfaceOrientationLandscapeRight')));
    });

    test('checkForModelUpdate parses HF 302 X-Linked-ETag SHA-256 and detects same-size updates', () async {
      final tempVault = await Directory.systemTemp.createTemp('juamea_vault_test_');
      addTearDown(() async {
        if (await tempVault.exists()) {
          await tempVault.delete(recursive: true);
        }
      });

      const v1Hash = '1111111111111111111111111111111111111111111111111111111111111111';
      const v2Hash = '822c91d669b92e36080b0c66b2d985146974a930ce4fd1a2574715aa7c3fc42d';
      final payloadV1 = Uint8List.fromList(List<int>.filled(128, 3));
      final payloadV2 = Uint8List.fromList(List<int>.filled(128, 8));

      var activeRemoteHash = v1Hash;
      var activePayload = payloadV1;

      final mockClient = MockClient.streaming((request, _) async {
        if (request.method == 'HEAD') {
          expect(request.followRedirects, isFalse);
          return http.StreamedResponse(
            const Stream<List<int>>.empty(),
            302,
            headers: {
              'location': 'https://cdn.hf.co/sautilm-jua-agri.litertlm',
              'x-linked-etag': '"$activeRemoteHash"',
              'x-linked-size': '${activePayload.length}',
              'x-repo-commit': 'a8fcc7bcf388e8e3ec567fbb00581138829a2691',
            },
          );
        }
        if (request.url.host == 'huggingface.co') {
          return http.StreamedResponse(
            const Stream<List<int>>.empty(),
            302,
            headers: {
              'location': 'https://cdn.hf.co/sautilm-jua-agri.litertlm',
              'x-linked-etag': '"$activeRemoteHash"',
              'x-repo-commit': 'a8fcc7bcf388e8e3ec567fbb00581138829a2691',
            },
          );
        }
        return http.StreamedResponse(
          Stream<List<int>>.fromIterable([activePayload]),
          200,
          contentLength: activePayload.length,
        );
      });

      // 1. Before download -> notInstalled
      final beforeCheck = await JuameaModelManager.checkForModelUpdate(
        client: mockClient,
        vaultDirOverride: tempVault,
        minBytesOverride: 32,
      );
      expect(beforeCheck.status, JuameaModelUpdateStatus.notInstalled);

      // 2. First download saves binary + SHA-256 metadata
      await JuameaModelManager.downloadOrUpdateModel(
        onProgress: (_) {},
        client: mockClient,
        vaultDirOverride: tempVault,
        minBytesOverride: 32,
      );
      final upToDate = await JuameaModelManager.checkForModelUpdate(
        client: mockClient,
        vaultDirOverride: tempVault,
        minBytesOverride: 32,
      );
      expect(upToDate.status, JuameaModelUpdateStatus.upToDate);
      expect(upToDate.hasUpdate, isFalse);

      // 3. New Hugging Face checkpoint with IDENTICAL byte size (128 B) but new SHA-256 -> updateAvailable!
      activeRemoteHash = v2Hash;
      activePayload = payloadV2;
      final updateFound = await JuameaModelManager.checkForModelUpdate(
        client: mockClient,
        vaultDirOverride: tempVault,
        minBytesOverride: 32,
      );
      expect(updateFound.status, JuameaModelUpdateStatus.updateAvailable);
      expect(updateFound.hasUpdate, isTrue);

      // 4. force: true replaces binary & updates metadata -> upToDate again!
      final updatedFile = await JuameaModelManager.downloadOrUpdateModel(
        onProgress: (_) {},
        force: true,
        client: mockClient,
        vaultDirOverride: tempVault,
        minBytesOverride: 32,
      );
      expect((await updatedFile.readAsBytes()).first, equals(8));
      final afterUpdate = await JuameaModelManager.checkForModelUpdate(
        client: mockClient,
        vaultDirOverride: tempVault,
        minBytesOverride: 32,
      );
      expect(afterUpdate.status, JuameaModelUpdateStatus.upToDate);

      // 5. deleteLocalModel removes binary + meta.json cleanly
      final deleted = await JuameaModelManager.deleteLocalModel(vaultDirOverride: tempVault);
      expect(deleted, isTrue);
      final afterDelete = await JuameaModelManager.getLocalModelStatus(
        vaultDirOverride: tempVault,
        minBytesOverride: 32,
      );
      expect(afterDelete.exists, isFalse);
    });
  });
}
