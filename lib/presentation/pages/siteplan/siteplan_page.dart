import 'dart:io';

import 'package:dago_valley_explore_tv/app/config/app_colors.dart';
import 'package:dago_valley_explore_tv/app/services/local_storage.dart';
import 'package:dago_valley_explore_tv/presentation/controllers/siteplan/siteplan_controller.dart';
import 'package:dago_valley_explore_tv/presentation/controllers/theme/theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

class SiteplanPage extends GetView<SiteplanController> {
  const SiteplanPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Segmented Button Tab Bar
            _buildSegmentedTabBar(context, themeController),

            // ✅ Tab Content - UBAH DARI Expanded JADI FLEXIBLE ATAU ALIGN
            Expanded(
              child: Obx(
                () => Align(
                  alignment: Alignment.topCenter,
                  child: _buildTabContent(context, themeController),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Build Segmented Button Tab Bar
  Widget _buildSegmentedTabBar(
    BuildContext context,
    ThemeController themeController,
  ) {
    return Container(
      padding: const EdgeInsets.only(top: 60),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Obx(() {
          return SegmentedButton<SiteplanTabType>(
            segments: SiteplanTabType.values.map((tab) {
              return ButtonSegment<SiteplanTabType>(
                value: tab,
                label: Text(tab.label, style: TextStyle(fontSize: 11)),
                icon: Icon(tab.icon, size: 12),
              );
            }).toList(),
            selected: {controller.selectedTab},
            onSelectionChanged: (Set<SiteplanTabType> newSelection) {
              controller.setSelectedTab(newSelection.first);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.primary;
                }
                return themeController.isDarkMode
                    ? Colors.grey[800]
                    : Colors.grey[200];
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return themeController.isDarkMode ? Colors.white : Colors.black;
              }),
              side: WidgetStateProperty.all(
                BorderSide(
                  color: themeController.isDarkMode
                      ? Colors.grey[700]!
                      : Colors.grey[300]!,
                ),
              ),
            ),
            showSelectedIcon: false,
          );
        }),
      ),
    );
  }

  // ✅ Build Tab Content based on selected tab
  Widget _buildTabContent(
    BuildContext context,
    ThemeController themeController,
  ) {
    switch (controller.selectedTab) {
      case SiteplanTabType.map:
        return _buildMapTab(context, themeController);
      case SiteplanTabType.fasum:
        return _buildFasumTab(context, themeController);
      case SiteplanTabType.timelineProgress:
        return _buildTimelineProgressTab(context, themeController);
      case SiteplanTabType.siteplanStatus:
        return _buildSiteplanStatusTab(context, themeController);
      case SiteplanTabType.kawasan360:
        return _buildKawasan360Tab(context, themeController);
    }
  }

  Future<File?> _localFile(String imageUrl) {
    final storage = Get.find<LocalStorageService>();
    return storage.getLocalImage(imageUrl);
  }

  Widget _buildSiteplanImage(
    String imageUrl, {
    BoxFit fit = BoxFit.cover,
    double? height,
    double? width,
  }) {
    // gunakan FutureBuilder untuk mengecek apakah file tersedia di lokal
    return FutureBuilder<File?>(
      future: _localFile(imageUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        final file = snapshot.data;
        if (file != null && file.existsSync()) {
          return Image.file(file, fit: fit, width: width, height: height);
        }

        // terakhir, anggap sebagai asset path
        if (imageUrl.isNotEmpty) {
          return Image.asset(
            imageUrl,
            fit: fit,
            width: width,
            height: height,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.broken_image)),
              );
            },
          );
        }

        // jika tidak ada imageUrl
        return Container(
          width: width,
          height: height,
          color: Colors.grey[200],
          child: const Center(child: Icon(Icons.image_not_supported)),
        );
      },
    );
  }

  // ✅ Wrapper untuk InteractiveViewer dengan zoom controls
  Widget _buildZoomableImage({
    required String imageUrl,
    required BoxFit fit,
    required ThemeController themeController,
  }) {
    final TransformationController transformationController =
        TransformationController();

    return Stack(
      children: [
        InteractiveViewer(
          transformationController: transformationController,
          minScale: 1.0,
          maxScale: 5.0,
          boundaryMargin: const EdgeInsets.all(20),
          panEnabled: true,
          scaleEnabled: true,
          child: Center(child: _buildSiteplanImage(imageUrl, fit: fit)),
        ),
        // Zoom controls
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Zoom In Button
              FloatingActionButton.small(
                heroTag: 'zoom_in',
                onPressed: () {
                  final currentScale = transformationController.value
                      .getMaxScaleOnAxis();
                  final newScale = (currentScale * 1.2).clamp(1.0, 5.0);
                  transformationController.value = Matrix4.identity()
                    ..scale(newScale);
                },
                backgroundColor: themeController.isDarkMode
                    ? Colors.grey[800]
                    : Colors.white,
                child: Icon(
                  Icons.zoom_in,
                  color: themeController.isDarkMode
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              // Zoom Out Button
              FloatingActionButton.small(
                heroTag: 'zoom_out',
                onPressed: () {
                  final currentScale = transformationController.value
                      .getMaxScaleOnAxis();
                  final newScale = (currentScale / 1.2).clamp(1.0, 5.0);
                  transformationController.value = Matrix4.identity()
                    ..scale(newScale);
                },
                backgroundColor: themeController.isDarkMode
                    ? Colors.grey[800]
                    : Colors.white,
                child: Icon(
                  Icons.zoom_out,
                  color: themeController.isDarkMode
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              // Reset Zoom Button
              FloatingActionButton.small(
                heroTag: 'zoom_reset',
                onPressed: () {
                  transformationController.value = Matrix4.identity();
                },
                backgroundColor: themeController.isDarkMode
                    ? Colors.grey[800]
                    : Colors.white,
                child: Icon(
                  Icons.refresh,
                  color: themeController.isDarkMode
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ✅ Map Tab Content - HEIGHT SEKARANG AKAN BEKERJA
  Widget _buildMapTab(BuildContext context, ThemeController themeController) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height:
            MediaQuery.of(context).size.height *
            0.759, // ← SEKARANG AKAN BEKERJA
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: themeController.isDarkMode ? Colors.black : Colors.white,
            child: Container(
              color: themeController.isDarkMode
                  ? Colors.grey[900]
                  : Colors.grey[200],
              child: _buildZoomableImage(
                imageUrl: controller.firstSiteplan.mapUrl,
                fit: BoxFit.fitWidth,
                themeController: themeController,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Fasum Tab Content - DENGAN SIZED BOX
  Widget _buildFasumTab(BuildContext context, ThemeController themeController) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.759,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: themeController.isDarkMode ? Colors.black : Colors.white,
            child: Container(
              color: themeController.isDarkMode
                  ? Colors.grey[900]
                  : Colors.grey[200],
              child: _buildZoomableImage(
                imageUrl: controller.firstSiteplan.fasumUrl,
                fit: BoxFit.contain,
                themeController: themeController,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Timeline Progress Tab Content - DENGAN SIZED BOX
  Widget _buildTimelineProgressTab(
    BuildContext context,
    ThemeController themeController,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.759,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: themeController.isDarkMode ? Colors.black : Colors.white,
            child: Container(
              color: themeController.isDarkMode
                  ? Colors.grey[900]
                  : Colors.grey[200],
              child: _buildZoomableImage(
                imageUrl: controller.firstSiteplan.timelineProgressUrl,
                fit: BoxFit.contain,
                themeController: themeController,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Siteplan Status Tab Content - DENGAN SIZED BOX
  Widget _buildSiteplanStatusTab(
    BuildContext context,
    ThemeController themeController,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.759,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: themeController.isDarkMode ? Colors.black : Colors.white,
            child: Container(
              color: themeController.isDarkMode
                  ? Colors.grey[900]
                  : Colors.grey[200],
              child: _buildZoomableImage(
                imageUrl: controller.firstSiteplan.imageUrl,
                fit: BoxFit.contain,
                themeController: themeController,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Kawasan 360 Tab Content - DENGAN SIZED BOX
  Widget _buildKawasan360Tab(
    BuildContext context,
    ThemeController themeController,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.759,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: themeController.isDarkMode ? Colors.black : Colors.white,
            child: _buildComingSoonWidget(
              context,
              themeController,
              icon: Icons.construction,
              title: 'Kawasan 360° Coming Soon',
              description:
                  'Explore the 360-degree view of the kawasan soon.  Stay tuned for updates!',
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Coming Soon Widget (Reusable)
  Widget _buildComingSoonWidget(
    BuildContext context,
    ThemeController themeController, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWide ? 900 : 600),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 120,
                color: themeController.isDarkMode
                    ? Colors.white24
                    : Colors.black26,
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: TextStyle(
                  fontSize: isWide ? 28 : 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: isWide ? 16 : 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build panorama viewer
  Widget _buildPanoramaViewer() {
    return Obx(() {
      try {
        return PanoramaViewer(
          animSpeed: 0.1,
          sensorControl: controller.isDesktop
              ? SensorControl.none
              : SensorControl.orientation,
          onViewChanged: controller.onViewChanged,
          onTap: controller.onPanoramaTap,
          hotspots: [
            Hotspot(
              latitude: 0.0,
              longitude: 0.0,
              width: 90,
              height: 80,
              widget: _buildHotspotButton(
                text: "Next",
                icon: Icons.open_in_new,
                onPressed: controller.goToNextPanorama,
              ),
            ),
          ],
          child: controller.currentPanoAsset,
        );
      } catch (e, st) {
        debugPrint('PanoramaViewer failed: $e\n$st');
        return _buildPanoramaFallback();
      }
    });
  }

  // Build panorama fallback
  Widget _buildPanoramaFallback() {
    return Obx(
      () => Stack(
        fit: StackFit.expand,
        children: [
          controller.currentPanoAsset,
          const Center(
            child: Text(
              'Panorama unavailable',
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  // Build hotspot button
  Widget _buildHotspotButton({
    String? text,
    IconData? icon,
    VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          style: ButtonStyle(
            shape: WidgetStateProperty.all(const CircleBorder()),
            backgroundColor: WidgetStateProperty.all(Colors.black38),
            foregroundColor: WidgetStateProperty.all(Colors.white),
          ),
          onPressed: onPressed,
          child: Icon(icon),
        ),
        if (text != null)
          Container(
            padding: const EdgeInsets.all(4.0),
            decoration: const BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            child: Center(child: Text(text)),
          ),
      ],
    );
  }
}
