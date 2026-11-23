import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:juamea/core/core.dart';
import 'package:juamea/presentation/presentation.dart';

class MainNavigationHolder extends StatefulWidget {
  const MainNavigationHolder({super.key});

  @override
  State<MainNavigationHolder> createState() => _MainNavigationHolderState();
}

class _MainNavigationHolderState extends State<MainNavigationHolder> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const ChatPage(),
  ];

  void _executeCropScan(File imageFile) {
    context.read<ScanCubit>().analyzeCrop(imageFile);

    final screenHeight = MediaQuery.of(context).size.height;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.r24)),
      ),
      builder: (modalContext) => MediaQuery.removeViewInsets(
        context: modalContext,
        removeBottom: true,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.85,
          ),
          decoration: const BoxDecoration(
            color: AppColors.cardCleanWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.r24)),
          ),
          child: ScanResultModal(capturedImage: imageFile),
        ),
      ),
    );
  }

  Future<void> _pickAndScanImage(ImageSource source) async {
    final strings = context.read<LocaleCubit>().state.strings;
    final picker = ImagePicker();
    XFile? image;
    try {
      image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${strings.imageOpenErrorPrefix} : $e"),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (image == null) return; // User cancelled

    _executeCropScan(File(image.path));
  }

  void _showScanSourceSelector() {
    final strings = context.read<LocaleCubit>().state.strings;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Material(
          color: AppColors.cardCleanWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSize.r24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(AppSize.p24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.scanSheetTitle,
                  style: const TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryForestGreen,
                  ),
                ),
                const SizedBox(height: AppSize.p8),
                Text(
                  strings.scanSheetSubtitle,
                  style: const TextStyle(
                    fontFamily: 'Figtree',
                    fontSize: 13,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: AppSize.p20),
                _buildSourceTile(
                  icon: AppIcons.scan,
                  title: strings.takePhotoTitle,
                  subtitle: strings.takePhotoSubtitle,
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _pickAndScanImage(ImageSource.camera);
                  },
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                _buildSourceTile(
                  icon: AppIcons.gallery,
                  title: strings.choosePhotoTitle,
                  subtitle: strings.choosePhotoSubtitle,
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    _pickAndScanImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceTile({
    required dynamic icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSize.p8, horizontal: AppSize.p4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.primaryForestGreen.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: HugeIcon(icon: icon, color: AppColors.primaryForestGreen, size: AppSize.iconMd),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Figtree',
          fontWeight: FontWeight.bold,
          color: AppColors.primaryForestGreen,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'Figtree',
          fontSize: 12,
          color: AppColors.textGrey,
        ),
      ),
      trailing: const HugeIcon(icon: AppIcons.arrowRight, color: AppColors.textGrey, size: 20.0),
      onTap: onTap,
    );
  }

  Future<void> _triggerCropScan() async {
    _showScanSourceSelector();
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.watch<LocaleCubit>().state.strings;
    return BlocListener<ScanCubit, ScanState>(
      listener: (context, state) {
        final s = context.read<LocaleCubit>().state.strings;
        if (state is ScanSuccess) {
          context.read<HomeCubit>().loadDashboard();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const HugeIcon(
                    icon: AppIcons.check,
                    color: Colors.white,
                    size: 20.0,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.scanDoneSnack,
                      style: const TextStyle(
                        fontFamily: 'Figtree',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: AppColors.primaryForestGreen,
              duration: const Duration(seconds: 4),
            ),
          );
        } else if (state is ScanFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${s.scanInterruptedPrefix} : ${state.title}"),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      },
      child: Scaffold(
        body: _pages[_currentIndex],
        bottomNavigationBar: BottomAppBar(
          color: AppColors.cardCleanWhite,
          surfaceTintColor: Colors.transparent,
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: 0.15),
          padding: EdgeInsets.zero,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                // Tab 1: Home Dashboard Button
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _currentIndex = 0;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        BlocBuilder<HomeCubit, HomeState>(
                          builder: (context, homeState) {
                            final hasNewAlerts = homeState is HomeLoaded &&
                                homeState.diagnosticsHistory.any((d) => d.status == 'new');
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                HugeIcon(
                                  icon: AppIcons.home,
                                  color: _currentIndex == 0 ? AppColors.primaryForestGreen : AppColors.textGrey,
                                  size: 26.0,
                                ),
                                if (hasNewAlerts)
                                  Positioned(
                                    right: -3,
                                    top: -3,
                                    child: Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: AppColors.errorRed,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        if (_currentIndex == 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            strings.navHome,
                            style: const TextStyle(
                              fontFamily: 'Figtree',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryForestGreen,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Tab 2: Scan Leaf Action
                BlocBuilder<ScanCubit, ScanState>(
                  builder: (context, scanState) {
                    final isProcessing = scanState is ScanProcessing;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (isProcessing) {
                          final screenHeight = MediaQuery.of(context).size.height;
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            useSafeArea: true,
                            isDismissible: true,
                            enableDrag: true,
                            backgroundColor: Colors.transparent,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.r24)),
                            ),
                            builder: (modalContext) => MediaQuery.removeViewInsets(
                              context: modalContext,
                              removeBottom: true,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxHeight: screenHeight * 0.85,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.cardCleanWhite,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(AppSize.r24)),
                                ),
                                child: ScanResultModal(capturedImage: scanState.image),
                              ),
                            ),
                          );
                        } else {
                          _triggerCropScan();
                        }
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSize.p12),
                            decoration: BoxDecoration(
                              color: AppColors.primaryForestGreen.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const HugeIcon(
                              icon: AppIcons.scan,
                              color: AppColors.primaryForestGreen,
                              size: 26.0,
                            ),
                          ),
                          if (isProcessing)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF9800),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                // Tab 3: Chat Assistant Button
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        _currentIndex = 1;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HugeIcon(
                          icon: AppIcons.chat,
                          color: _currentIndex == 1 ? AppColors.primaryForestGreen : AppColors.textGrey,
                          size: 26.0,
                        ),
                        if (_currentIndex == 1) ...[
                          const SizedBox(height: 2),
                          const Text(
                            "Juamea",
                            style: TextStyle(
                              fontFamily: 'Urbanist',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: AppColors.primaryForestGreen,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
