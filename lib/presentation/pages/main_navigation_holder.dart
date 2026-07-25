import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gemmea/core/core.dart';
import 'package:gemmea/data/data.dart';
import 'package:gemmea/presentation/presentation.dart';

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

  Future<File> _copyAssetToFile(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final directory = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return file;
  }

  void _executeCropScan(File imageFile) {
    final screenHeight = MediaQuery.of(context).size.height;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
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
          child: BlocProvider(
            create: (_) => ScanCubit(GemmaLocalSourceImpl())..analyzeCrop(imageFile),
            child: ScanResultModal(capturedImage: imageFile),
          ),
        ),
      ),
    ).then((_) {
      if (mounted) {
        context.read<HomeCubit>().loadDashboard();
      }
    });
  }

  Future<void> _triggerRealCameraScan() async {
    final picker = ImagePicker();
    XFile? image;
    try {
      image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erreur appareil photo : $e"),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (image == null) return; // User cancelled

    _executeCropScan(File(image.path));
  }

  void _showScanSourceSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                const Text(
                  "Sélectionner la source du scan",
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryForestGreen,
                  ),
                ),
                const SizedBox(height: AppSize.p8),
                const Text(
                  "Effectuez un vrai scan hors ligne avec votre appareil photo ou sélectionnez l'un de nos fichiers de simulation intégrés pour un test immédiat.",
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: 13,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: AppSize.p20),
                _buildSourceTile(
                  icon: AppIcons.scan,
                  title: "Scan de culture par caméra saine",
                  subtitle: "Prenez une photo de feuille en temps réel avec votre appareil photo",
                  onTap: () {
                    Navigator.pop(context);
                    _triggerRealCameraScan();
                  },
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                _buildSourceTile(
                  icon: AppIcons.alert,
                  title: "Scan de Mosaïque du Manioc",
                  subtitle: "Simuler une feuille de manioc affectée par la mosaïque",
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await _copyAssetToFile("assets/images/cassava_mosaic.png");
                    _executeCropScan(file);
                  },
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                _buildSourceTile(
                  icon: AppIcons.calendar,
                  title: "Scan de Rouille du Maïs",
                  subtitle: "Simuler une feuille de maïs affectée par la rouille commune",
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await _copyAssetToFile("assets/images/maize_rust.png");
                    _executeCropScan(file);
                  },
                ),
                const Divider(height: 1, color: Color(0xFFEEEEEE)),
                _buildSourceTile(
                  icon: AppIcons.scan,
                  title: "Scan de feuille saine",
                  subtitle: "Simuler une feuille de culture saine et verte",
                  onTap: () async {
                    Navigator.pop(context);
                    final file = await _copyAssetToFile("assets/images/healthy_leaf.png");
                    _executeCropScan(file);
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
          fontFamily: 'Fredoka',
          fontWeight: FontWeight.bold,
          color: AppColors.primaryForestGreen,
          fontSize: 14,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontFamily: 'Fredoka',
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
    return Scaffold(
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
                      HugeIcon(
                        icon: AppIcons.home,
                        color: _currentIndex == 0 ? AppColors.primaryForestGreen : AppColors.textGrey,
                        size: 26.0,
                      ),
                      if (_currentIndex == 0) ...[
                        const SizedBox(height: 2),
                        const Text(
                          "Accueil",
                          style: TextStyle(
                            fontFamily: 'Fredoka',
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
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _triggerCropScan,
                child: Container(
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
                          "Gemmea",
                          style: TextStyle(
                            fontFamily: 'Fredoka',
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
            ],
          ),
        ),
      ),
    );
  }
}
