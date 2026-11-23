import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:juamea/core/services/gemma_engine_manager.dart';
import 'package:path_provider/path_provider.dart';

/// Thrown when the optional local chat model (`SautiLM-Jua-Agri`) has not been downloaded yet.
class ModelNotInstalledException implements Exception {
  final String message;
  const ModelNotInstalledException([
    this.message =
        "Le modèle IA SautiLM-Jua-Agri n'est pas encore téléchargé sur cet appareil.",
  ]);

  @override
  String toString() => message;
}

enum JuameaModelUpdateStatus {
  upToDate,
  updateAvailable,
  notInstalled,
  offline,
  error,
}

class JuameaLocalModelStatus {
  final bool exists;
  final String? path;
  final int sizeBytes;
  final String? installedEtag;
  final String? installedCommit;

  const JuameaLocalModelStatus({
    required this.exists,
    this.path,
    this.sizeBytes = 0,
    this.installedEtag,
    this.installedCommit,
  });

  String get sizeFormatted {
    if (sizeBytes <= 0) return '0 Mo';
    final mb = sizeBytes / (1024 * 1024);
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(2)} Go';
    return '${mb.toStringAsFixed(0)} Mo';
  }

  String? get shortHash {
    if (installedEtag == null || installedEtag!.length < 8) return installedEtag;
    return installedEtag!.substring(0, 8);
  }
}

class JuameaUpdateCheckResult {
  final JuameaModelUpdateStatus status;
  final String? remoteEtag;
  final String? localEtag;
  final int remoteSizeBytes;
  final int localSizeBytes;
  final String? remoteCommit;
  final String? errorMessage;

  const JuameaUpdateCheckResult({
    required this.status,
    this.remoteEtag,
    this.localEtag,
    this.remoteSizeBytes = 0,
    this.localSizeBytes = 0,
    this.remoteCommit,
    this.errorMessage,
  });

  bool get hasUpdate => status == JuameaModelUpdateStatus.updateAvailable;

  String get remoteSizeFormatted {
    if (remoteSizeBytes <= 0) return '283 Mo';
    final mb = remoteSizeBytes / (1024 * 1024);
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(2)} Go';
    return '${mb.toStringAsFixed(0)} Mo';
  }

  String? get shortRemoteHash {
    if (remoteEtag == null || remoteEtag!.length < 8) return remoteEtag;
    return remoteEtag!.substring(0, 8);
  }
}

/// Play Store & App Store compliant storage & Hugging Face SHA-256 update manager
/// for Juamea's optional offline agronomy chat model (`SautiLM-Jua-Agri`, ~283 MB).
///
/// - Stored strictly inside app-private storage (`ApplicationSupport/sautilm_models/`).
/// - Requires ZERO Android external storage permissions (`MANAGE_EXTERNAL_STORAGE` removed).
/// - 100% automatically deleted by Android/iOS when the user uninstalls Juamea.
/// - Verifies updates cryptographically via `< 2 KB` non-redirected HTTP `HEAD`
///   against Hugging Face `X-Linked-ETag` (SHA-256) + `X-Linked-Size`.
class JuameaModelManager {
  static const String huggingFaceModelUrl =
      'https://huggingface.co/sautilm/SautiLM-Jua-Agri/resolve/main/sautilm-jua-agri.litertlm';
  static const String primaryFilename = 'sautilm-jua-agri.litertlm';
  static const String metadataFilename = 'sautilm-jua-agri.meta.json';
  static const int defaultMinValidBytes = 50 * 1024 * 1024;

  static const List<String> legacyPrivateFilenames = [
    'sautilm-jua-agri.litertlm',
    'sautilm-jua.litertlm',
    'gemma.litertlm',
  ];

  static String? normalizeEtag(String? raw) {
    if (raw == null) return null;
    var cleaned = raw.trim();
    if (cleaned.startsWith('W/') || cleaned.startsWith('w/')) {
      cleaned = cleaned.substring(2).trim();
    }
    cleaned = cleaned.replaceAll('"', '').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  static Future<Directory> resolvePrivateVaultDir({Directory? vaultDirOverride}) async {
    if (vaultDirOverride != null) {
      if (!await vaultDirOverride.exists()) {
        await vaultDirOverride.create(recursive: true);
      }
      return vaultDirOverride;
    }

    Directory base;
    try {
      base = await getApplicationSupportDirectory();
    } catch (_) {
      base = await getApplicationDocumentsDirectory();
    }
    final vault = Directory('${base.path}/sautilm_models');
    if (!await vault.exists()) {
      await vault.create(recursive: true);
    }
    try {
      final nomedia = File('${vault.path}/.nomedia');
      if (!await nomedia.exists()) {
        await nomedia.create();
      }
    } catch (_) {}
    return vault;
  }

  static Future<bool> _isValidFile(File file, {int? minBytesOverride}) async {
    try {
      if (!await file.exists()) return false;
      final len = await file.length();
      return len > (minBytesOverride ?? defaultMinValidBytes);
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> _readMetadata(Directory vaultDir) async {
    try {
      final metaFile = File('${vaultDir.path}/$metadataFilename');
      if (!await metaFile.exists()) return null;
      final decoded = jsonDecode(await metaFile.readAsString());
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
    return null;
  }

  static Future<void> _writeMetadata({
    required Directory vaultDir,
    required int sizeBytes,
    String? etag,
    String? commit,
  }) async {
    try {
      final metaFile = File('${vaultDir.path}/$metadataFilename');
      final payload = <String, dynamic>{
        'filename': primaryFilename,
        'sizeBytes': sizeBytes,
        'etag': normalizeEtag(etag),
        'commit': commit?.trim(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      await metaFile.writeAsString(jsonEncode(payload));
    } catch (_) {}
  }

  /// Resolves the installed private model file (never scanning public external storage).
  static Future<File?> resolveInstalledModelFile({
    Directory? vaultDirOverride,
    int? minBytesOverride,
  }) async {
    final vault = await resolvePrivateVaultDir(vaultDirOverride: vaultDirOverride);
    for (final name in legacyPrivateFilenames) {
      final candidate = File('${vault.path}/$name');
      if (await _isValidFile(candidate, minBytesOverride: minBytesOverride)) {
        return candidate;
      }
    }

    if (vaultDirOverride == null) {
      try {
        final docs = await getApplicationDocumentsDirectory();
        for (final name in legacyPrivateFilenames) {
          final candidate = File('${docs.path}/$name');
          if (await _isValidFile(candidate, minBytesOverride: minBytesOverride)) {
            return candidate;
          }
        }
      } catch (_) {}
    }

    return null;
  }

  static Future<JuameaLocalModelStatus> getLocalModelStatus({
    Directory? vaultDirOverride,
    int? minBytesOverride,
  }) async {
    final vault = await resolvePrivateVaultDir(vaultDirOverride: vaultDirOverride);
    final file = await resolveInstalledModelFile(
      vaultDirOverride: vaultDirOverride,
      minBytesOverride: minBytesOverride,
    );
    if (file == null) {
      return const JuameaLocalModelStatus(exists: false);
    }
    final size = await file.length();
    final meta = await _readMetadata(vault);
    return JuameaLocalModelStatus(
      exists: true,
      path: file.path,
      sizeBytes: size,
      installedEtag: normalizeEtag(meta?['etag'] as String?),
      installedCommit: meta?['commit'] as String?,
    );
  }

  /// Sends a `< 2 KB` non-redirected HTTP `HEAD` check to Hugging Face and verifies
  /// the cryptographic LFS SHA-256 (`X-Linked-ETag`) + byte size against the local vault.
  static Future<JuameaUpdateCheckResult> checkForModelUpdate({
    http.Client? client,
    String modelUrl = huggingFaceModelUrl,
    Directory? vaultDirOverride,
    int? minBytesOverride,
  }) async {
    final local = await getLocalModelStatus(
      vaultDirOverride: vaultDirOverride,
      minBytesOverride: minBytesOverride,
    );

    final effectiveClient = client ?? http.Client();
    final ownsClient = client == null;

    try {
      final request = http.Request('HEAD', Uri.parse(modelUrl))
        ..followRedirects = false
        ..headers['User-Agent'] = 'Juamea-Mobile/1.0';

      final streamed = await effectiveClient
          .send(request)
          .timeout(const Duration(seconds: 12));
      await streamed.stream.drain<void>();

      final code = streamed.statusCode;
      if (code != 200 && code != 301 && code != 302 && code != 307 && code != 308) {
        return JuameaUpdateCheckResult(
          status: JuameaModelUpdateStatus.error,
          localEtag: local.installedEtag,
          localSizeBytes: local.sizeBytes,
          errorMessage: 'HTTP $code',
        );
      }

      final headers = streamed.headers;
      final remoteEtag = normalizeEtag(headers['x-linked-etag'] ?? headers['etag']);
      final remoteSizeBytes = int.tryParse(
            headers['x-linked-size'] ?? headers['content-length'] ?? '',
          ) ??
          0;
      final remoteCommit = headers['x-repo-commit']?.trim();

      if (!local.exists) {
        return JuameaUpdateCheckResult(
          status: JuameaModelUpdateStatus.notInstalled,
          remoteEtag: remoteEtag,
          remoteSizeBytes: remoteSizeBytes,
          remoteCommit: remoteCommit,
        );
      }

      if (local.installedEtag != null &&
          local.installedEtag!.isNotEmpty &&
          remoteEtag != null &&
          remoteEtag.isNotEmpty) {
        final sizeMatches = remoteSizeBytes <= 0 || local.sizeBytes == remoteSizeBytes;
        if (local.installedEtag == remoteEtag && sizeMatches) {
          return JuameaUpdateCheckResult(
            status: JuameaModelUpdateStatus.upToDate,
            remoteEtag: remoteEtag,
            localEtag: local.installedEtag,
            remoteSizeBytes: remoteSizeBytes,
            localSizeBytes: local.sizeBytes,
            remoteCommit: remoteCommit,
          );
        }
        return JuameaUpdateCheckResult(
          status: JuameaModelUpdateStatus.updateAvailable,
          remoteEtag: remoteEtag,
          localEtag: local.installedEtag,
          remoteSizeBytes: remoteSizeBytes,
          localSizeBytes: local.sizeBytes,
          remoteCommit: remoteCommit,
        );
      }

      if (remoteSizeBytes > 0 && local.sizeBytes != remoteSizeBytes) {
        return JuameaUpdateCheckResult(
          status: JuameaModelUpdateStatus.updateAvailable,
          remoteEtag: remoteEtag,
          localEtag: local.installedEtag,
          remoteSizeBytes: remoteSizeBytes,
          localSizeBytes: local.sizeBytes,
          remoteCommit: remoteCommit,
        );
      }

      return JuameaUpdateCheckResult(
        status: remoteEtag != null
            ? JuameaModelUpdateStatus.updateAvailable
            : JuameaModelUpdateStatus.upToDate,
        remoteEtag: remoteEtag,
        localEtag: local.installedEtag,
        remoteSizeBytes: remoteSizeBytes,
        localSizeBytes: local.sizeBytes,
        remoteCommit: remoteCommit,
      );
    } on SocketException catch (e) {
      return JuameaUpdateCheckResult(
        status: JuameaModelUpdateStatus.offline,
        localEtag: local.installedEtag,
        localSizeBytes: local.sizeBytes,
        errorMessage: e.message,
      );
    } on TimeoutException catch (e) {
      return JuameaUpdateCheckResult(
        status: JuameaModelUpdateStatus.offline,
        localEtag: local.installedEtag,
        localSizeBytes: local.sizeBytes,
        errorMessage: e.message,
      );
    } on http.ClientException catch (e) {
      return JuameaUpdateCheckResult(
        status: JuameaModelUpdateStatus.offline,
        localEtag: local.installedEtag,
        localSizeBytes: local.sizeBytes,
        errorMessage: e.message,
      );
    } catch (e) {
      return JuameaUpdateCheckResult(
        status: JuameaModelUpdateStatus.error,
        localEtag: local.installedEtag,
        localSizeBytes: local.sizeBytes,
        errorMessage: e.toString(),
      );
    } finally {
      if (ownsClient) {
        effectiveClient.close();
      }
    }
  }

  /// Downloads or atomically replaces `sautilm-jua-agri.litertlm` inside Juamea's
  /// Store-compliant private vault, recording its Hugging Face SHA-256 ETag.
  static Future<File> downloadOrUpdateModel({
    required void Function(double progress) onProgress,
    bool force = false,
    String modelUrl = huggingFaceModelUrl,
    http.Client? client,
    Directory? vaultDirOverride,
    int? minBytesOverride,
  }) async {
    final vault = await resolvePrivateVaultDir(vaultDirOverride: vaultDirOverride);
    final destinationFile = File('${vault.path}/$primaryFilename');
    final tempModelFile = File('${vault.path}/$primaryFilename.part');

    if (!force) {
      final existing = await resolveInstalledModelFile(
        vaultDirOverride: vaultDirOverride,
        minBytesOverride: minBytesOverride,
      );
      if (existing != null) {
        onProgress(1.0);
        return existing;
      }
    } else {
      GemmaEngineManager.resetChatSession();
    }

    if (await tempModelFile.exists()) {
      try {
        await tempModelFile.delete();
      } catch (_) {}
    }

    final effectiveClient = client ?? http.Client();
    final ownsClient = client == null;

    try {
      dev.log(
        'Downloading SautiLM-Jua-Agri to private vault ${destinationFile.path} (force=$force)...',
        name: 'JUAMEA_MODEL_MANAGER',
      );

      final initialReq = http.Request('GET', Uri.parse(modelUrl))
        ..followRedirects = false
        ..headers['User-Agent'] = 'Juamea-Mobile/1.0';

      http.StreamedResponse response = await effectiveClient
          .send(initialReq)
          .timeout(const Duration(seconds: 30));

      String? capturedEtag = normalizeEtag(
        response.headers['x-linked-etag'] ?? response.headers['etag'],
      );
      String? capturedCommit = response.headers['x-repo-commit']?.trim();

      int redirectCount = 0;
      Uri currentUri = Uri.parse(modelUrl);
      while ((response.isRedirect ||
              response.statusCode == 301 ||
              response.statusCode == 302 ||
              response.statusCode == 307 ||
              response.statusCode == 308) &&
          redirectCount < 10) {
        final loc = response.headers['location'];
        await response.stream.drain<void>();
        if (loc == null || loc.isEmpty) break;
        currentUri = currentUri.resolve(loc);
        final nextReq = http.Request('GET', currentUri)
          ..followRedirects = false
          ..headers['User-Agent'] = 'Juamea-Mobile/1.0';
        response = await effectiveClient
            .send(nextReq)
            .timeout(const Duration(seconds: 30));
        capturedEtag ??= normalizeEtag(
          response.headers['x-linked-etag'] ?? response.headers['etag'],
        );
        capturedCommit ??= response.headers['x-repo-commit']?.trim();
        redirectCount++;
      }

      if (response.statusCode != 200) {
        throw HttpException('Échec du téléchargement du modèle (HTTP ${response.statusCode})');
      }

      final contentLength = response.contentLength ?? 0;
      int downloadedBytes = 0;
      final IOSink sink = tempModelFile.openWrite();

      await response.stream.forEach((chunk) {
        downloadedBytes += chunk.length;
        sink.add(chunk);
        if (contentLength > 0) {
          onProgress((downloadedBytes / contentLength).clamp(0.0, 1.0));
        }
      });

      await sink.close();

      if (await destinationFile.exists()) {
        await destinationFile.delete();
      }
      await tempModelFile.rename(destinationFile.path);
      final finalSize = await destinationFile.length();
      await _writeMetadata(
        vaultDir: vault,
        sizeBytes: finalSize,
        etag: capturedEtag,
        commit: capturedCommit,
      );
      onProgress(1.0);
      return destinationFile;
    } catch (_) {
      if (await tempModelFile.exists()) {
        try {
          await tempModelFile.delete();
        } catch (_) {}
      }
      rethrow;
    } finally {
      if (ownsClient) {
        effectiveClient.close();
      }
    }
  }

  /// Deletes the optional ~283 MB offline chat weights from Juamea's private vault
  /// without touching `SautiLM-Nuru-Agri` (1.07 MB) or FAO/NARS SQLite diagnostics.
  static Future<bool> deleteLocalModel({Directory? vaultDirOverride}) async {
    GemmaEngineManager.resetChatSession();
    var deletedAny = false;

    final dirs = <Directory>[
      await resolvePrivateVaultDir(vaultDirOverride: vaultDirOverride),
    ];
    if (vaultDirOverride == null) {
      try {
        dirs.add(await getApplicationDocumentsDirectory());
      } catch (_) {}
    }

    for (final dir in dirs) {
      try {
        if (!await dir.exists()) continue;
        await for (final entity in dir.list()) {
          if (entity is File) {
            final lower = entity.path.toLowerCase();
            if (lower.endsWith('.litertlm') ||
                lower.endsWith('.part') ||
                lower.endsWith('.tmp') ||
                lower.endsWith(metadataFilename)) {
              await entity.delete();
              deletedAny = true;
            }
          }
        }
      } catch (_) {}
    }
    return deletedAny;
  }
}
