import 'dart:developer' as dev;
import 'package:shorebird_code_push/shorebird_code_push.dart';

/// Shorebird Code Push service for instant Over-The-Air (OTA) Dart patches in Juamea.
class ShorebirdService {
  static final ShorebirdService _instance = ShorebirdService._internal();
  factory ShorebirdService() => _instance;
  ShorebirdService._internal();

  final ShorebirdUpdater _updater = ShorebirdUpdater();

  bool get isAvailable => _updater.isAvailable;

  Future<int?> getCurrentPatchNumber() async {
    if (!isAvailable) return null;
    try {
      final patch = await _updater.readCurrentPatch();
      return patch?.number;
    } catch (e) {
      dev.log('Shorebird: error reading current patch: $e', name: 'ShorebirdService');
      return null;
    }
  }

  /// Checks for available Shorebird OTA patches and downloads them in the background.
  Future<bool> checkForUpdatesAndDownload() async {
    if (!isAvailable) return false;
    try {
      final status = await _updater.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        dev.log('Shorebird: patch found, downloading in background...', name: 'ShorebirdService');
        await _updater.update();
        dev.log('Shorebird: patch ready for next restart.', name: 'ShorebirdService');
        return true;
      }
      return false;
    } catch (e) {
      dev.log('Shorebird: update check skipped ($e)', name: 'ShorebirdService');
      return false;
    }
  }
}
