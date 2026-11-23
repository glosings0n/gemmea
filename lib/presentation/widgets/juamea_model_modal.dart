import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_edge_ai/flutter_edge_ai.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:juamea/core/core.dart';
import 'package:juamea/presentation/bloc/bloc.dart';

/// Store-compliant modal sheet letting Juamea users inspect, check Hugging Face SHA-256 updates,
/// download/update, or delete the optional ~283 MB `SautiLM-Jua-Agri` offline chat model
/// while highlighting that `SautiLM-Nuru-Agri` (1.07 MB) + FAO/NARS SQLite (2,369 records)
/// remain bundled and always available offline across East Africa.
class JuameaModelModal extends StatefulWidget {
  const JuameaModelModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardCleanWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const JuameaModelModal(),
    );
  }

  @override
  State<JuameaModelModal> createState() => _JuameaModelModalState();
}

class _JuameaModelModalState extends State<JuameaModelModal> {
  JuameaLocalModelStatus _localStatus = const JuameaLocalModelStatus(exists: false);
  JuameaUpdateCheckResult? _updateResult;
  bool _isLoading = true;
  bool _isChecking = false;
  bool _isDownloading = false;
  bool _isDeleting = false;
  double _progress = 0.0;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _refreshLocalStatus();
  }

  Future<void> _refreshLocalStatus() async {
    final status = await JuameaModelManager.getLocalModelStatus();
    if (!mounted) return;
    setState(() {
      _localStatus = status;
      _isLoading = false;
    });
  }

  Future<void> _checkUpdate(JuameaStringsData strings) async {
    if (_isChecking || _isDownloading) return;
    setState(() {
      _isChecking = true;
      _statusMessage = strings.modelCheckShaNotice;
    });
    final res = await JuameaModelManager.checkForModelUpdate();
    if (!mounted) return;
    String msg;
    switch (res.status) {
      case JuameaModelUpdateStatus.upToDate:
        final hash = res.shortRemoteHash != null ? ' (${res.shortRemoteHash})' : '';
        msg = '${strings.modelUpToDateMsg}$hash.';
        break;
      case JuameaModelUpdateStatus.updateAvailable:
        final hash = res.shortRemoteHash != null ? ' [${res.shortRemoteHash}]' : '';
        msg = '${strings.modelUpdateAvailableMsg} (${res.remoteSizeFormatted})$hash.';
        break;
      case JuameaModelUpdateStatus.notInstalled:
        msg = '${strings.modelNotInstalledMsg} (${res.remoteSizeFormatted}).';
        break;
      case JuameaModelUpdateStatus.offline:
        msg = strings.modelOfflineCheckMsg;
        break;
      case JuameaModelUpdateStatus.error:
        msg = '${strings.modelCheckErrorPrefix} (${res.errorMessage ?? '?'}).';
        break;
    }
    setState(() {
      _isChecking = false;
      _updateResult = res;
      _statusMessage = msg;
    });
  }

  Future<void> _downloadOrUpdate({
    required bool force,
    required JuameaStringsData strings,
  }) async {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _statusMessage =
          force ? strings.modelUpdatingStatus : strings.modelDownloadingStatus;
    });
    try {
      final file = await JuameaModelManager.downloadOrUpdateModel(
        force: force,
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
      );
      await GemmaEngineManager.ensureInitialized();
      try {
        await FlutterEdgeAi.installModel(
          modelType: ModelType.gemmaIt,
          fileType: ModelFileType.litertlm,
        ).fromFile(file.path).install();
      } catch (_) {}
      await _refreshLocalStatus();
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _updateResult = null;
        _statusMessage = strings.modelInstalledMsg;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDownloading = false;
        _statusMessage = strings.modelInterruptedMsg;
      });
    }
  }

  Future<void> _confirmDelete(JuameaStringsData strings) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          strings.modelDeleteConfirmTitle,
          style: const TextStyle(
            fontFamily: 'Figtree',
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          '${strings.modelDeleteConfirmBodyPrefix} ${_localStatus.sizeFormatted} ${strings.modelDeleteConfirmBodySuffix}',
          style: const TextStyle(fontFamily: 'Figtree', fontSize: 13.5, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              strings.cancelBtn,
              style: const TextStyle(fontFamily: 'Figtree', color: AppColors.textGrey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(
              strings.deleteBtn,
              style: const TextStyle(fontFamily: 'Figtree', fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isDeleting = true;
      _statusMessage = strings.modelFreeingSpaceMsg;
    });
    await JuameaModelManager.deleteLocalModel();
    await _refreshLocalStatus();
    if (!mounted) return;
    setState(() {
      _isDeleting = false;
      _updateResult = null;
      _statusMessage = strings.modelDeletedMsg;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleCubit>().state.strings;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      strings.modelModalTitle,
                      style: const TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textCharcoal,
                      ),
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const HugeIcon(icon: AppIcons.close, color: AppColors.textGrey, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                strings.modelModalStoreNote,
                style: const TextStyle(
                  fontFamily: 'Figtree',
                  fontSize: 12.5,
                  color: AppColors.textGrey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              // Bundled Core Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryForestGreen.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryForestGreen.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.modelNuruTitle,
                      style: const TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryForestGreen,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      strings.modelNuruDesc,
                      style: const TextStyle(
                        fontFamily: 'Figtree',
                        fontSize: 12,
                        color: AppColors.textCharcoal,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Optional Chat LLM Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  strings.modelJuaTitle,
                                  style: const TextStyle(
                                    fontFamily: 'Figtree',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textCharcoal,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _localStatus.exists
                                      ? AppColors.primaryForestGreen.withValues(alpha: 0.12)
                                      : Colors.orange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  _localStatus.exists
                                      ? _localStatus.sizeFormatted
                                      : strings.modelNotInstalledBadge,
                                  style: TextStyle(
                                    fontFamily: 'JetBrainsMono',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _localStatus.exists
                                        ? AppColors.primaryForestGreen
                                        : Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _localStatus.exists
                                ? '${strings.modelVaultPrefix}${_localStatus.shortHash != null ? ' · SHA-256 ${_localStatus.shortHash}' : ''}'
                                : strings.modelOptionalDesc,
                            style: const TextStyle(
                              fontFamily: 'Figtree',
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                          if (_statusMessage != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _statusMessage!,
                              style: const TextStyle(
                                fontFamily: 'Figtree',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textCharcoal,
                              ),
                            ),
                          ],
                          if (_isDownloading) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: _progress > 0 ? _progress : null,
                                minHeight: 8,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryForestGreen,
                                ),
                                backgroundColor:
                                    AppColors.primaryForestGreen.withValues(alpha: 0.14),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${(_progress * 100).toStringAsFixed(0)} %',
                              style: const TextStyle(
                                fontFamily: 'JetBrainsMono',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryForestGreen,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 14),
                            if (!_localStatus.exists)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _downloadOrUpdate(
                                    force: false,
                                    strings: strings,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryForestGreen,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    strings.chatDownloadBtnFull,
                                    style: const TextStyle(
                                      fontFamily: 'Figtree',
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              )
                            else ...[
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _isChecking || _isDeleting
                                      ? null
                                      : () {
                                          if (_updateResult?.hasUpdate == true) {
                                            _downloadOrUpdate(
                                              force: true,
                                              strings: strings,
                                            );
                                          } else {
                                            _checkUpdate(strings);
                                          }
                                        },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryForestGreen,
                                    side: const BorderSide(color: AppColors.primaryForestGreen),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isChecking
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : Text(
                                          _updateResult?.hasUpdate == true
                                              ? strings.modelUpdateBtn
                                              : (_updateResult?.status ==
                                                      JuameaModelUpdateStatus.upToDate
                                                  ? strings.modelUpToDateBtn
                                                  : strings.modelCheckUpdateBtn),
                                          style: const TextStyle(
                                            fontFamily: 'Figtree',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isDeleting
                                      ? null
                                      : () => _confirmDelete(strings),
                                  child: Text(
                                    strings.modelDeleteBtn,
                                    style: const TextStyle(
                                      fontFamily: 'Figtree',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
