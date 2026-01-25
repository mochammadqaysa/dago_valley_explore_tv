import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/gestures.dart';

import 'package:dago_valley_explore_tv/app/config/app_colors.dart';
import 'package:dago_valley_explore_tv/app/services/local_storage.dart';
import 'package:dago_valley_explore_tv/presentation/components/tinyplanet/tiny_planet.dart';
import 'package:dago_valley_explore_tv/presentation/controllers/siteplan/siteplan_controller.dart';
import 'package:dago_valley_explore_tv/presentation/controllers/theme/theme_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:panorama_viewer/panorama_viewer.dart';

class SiteplanPage extends StatefulWidget {
  const SiteplanPage({Key? key}) : super(key: key);

  @override
  State<SiteplanPage> createState() => _SiteplanPageState();
}

class _SiteplanPageState extends State<SiteplanPage>
    with TickerProviderStateMixin {
  // keep using controller via Get
  final SiteplanController controller = Get.find<SiteplanController>();

  // Tab controller for "Siteplan Status" pills (Tahap 1 / Tahap 2)
  late final TabController _statusTabController;
  // Tab controller for "Timeline Progress" pills (Tahap 1 / Tahap 2)
  late final TabController _timelineTabController;

  @override
  void initState() {
    super.initState();
    _statusTabController = TabController(length: 2, vsync: this);
    _timelineTabController = TabController(length: 2, vsync: this);

    // Optional: start on tahap 1 (index 0)
    _statusTabController.index = 0;
    _timelineTabController.index = 0;
  }

  @override
  void dispose() {
    _statusTabController.dispose();
    _timelineTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Segmented Button Tab Bar
            _buildSegmentedTabBar(context, themeController),

            // Tab Content
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

  // Build Segmented Button Tab Bar
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
                label: Text(tab.label),
                icon: Icon(tab.icon, size: 20),
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

  // Build Tab Content based on selected tab
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

  // Wrapper untuk InteractiveViewer dengan zoom controls
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
                heroTag: 'zoom_in_${imageUrl.hashCode}',
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
                heroTag: 'zoom_out_${imageUrl.hashCode}',
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
                heroTag: 'zoom_reset_${imageUrl.hashCode}',
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

  // Map Tab Content
  Widget _buildMapTab(BuildContext context, ThemeController themeController) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.895,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: themeController.isDarkMode ? Colors.black : Colors.white,
            child: Container(
              color: themeController.isDarkMode
                  ? Colors.grey[900]
                  : Colors.grey[200],
              child: _buildZoomableImage(
                imageUrl: controller.firstSiteplan?.mapUrl ?? '',
                fit: BoxFit.fitWidth,
                themeController: themeController,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Fasum Tab Content
  Widget _buildFasumTab(BuildContext context, ThemeController themeController) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.895,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: themeController.isDarkMode ? Colors.black : Colors.white,
            child: Container(
              color: themeController.isDarkMode
                  ? Colors.grey[900]
                  : Colors.grey[200],
              child: _buildZoomableImage(
                imageUrl: controller.firstSiteplan?.fasumUrl ?? '',
                fit: BoxFit.contain,
                themeController: themeController,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Timeline Progress Tab Content - with pills for Tahap 1 / Tahap 2
  Widget _buildTimelineProgressTab(
    BuildContext context,
    ThemeController themeController,
  ) {
    final isDark = themeController.isDarkMode;
    final tahap1Url = controller.firstSiteplan?.timelineProgressUrl;
    final tahap2Url = controller.firstSiteplan?.timelineProgressTahap2Url;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.895,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: isDark ? Colors.black : Colors.white,
            child: Column(
              children: [
                // Pills / TabBar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                  child: Container(
                    width: 260,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TabBar(
                      controller: _timelineTabController,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark
                          ? Colors.white70
                          : Colors.black54,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      tabs: [
                        Tab(text: 'Tahap 1'),
                        Tab(text: 'Tahap 2'),
                      ],
                    ),
                  ),
                ),

                // Content area
                Expanded(
                  child: TabBarView(
                    controller: _timelineTabController,
                    children: [
                      // Tahap 1 - existing image
                      Container(
                        color: isDark ? Colors.grey[900] : Colors.grey[200],
                        child: _buildZoomableImage(
                          imageUrl: tahap1Url ?? '',
                          fit: BoxFit.contain,
                          themeController: themeController,
                        ),
                      ),

                      // Tahap 2 - timelineProgressTahap2Url (fallback to placeholder if empty)
                      Container(
                        color: isDark ? Colors.grey[900] : Colors.grey[200],
                        child: (tahap2Url?.isNotEmpty ?? false)
                            ? _buildZoomableImage(
                                imageUrl: tahap2Url ?? '',
                                fit: BoxFit.contain,
                                themeController: themeController,
                              )
                            : Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Text(
                                    'No image available for Tahap 2',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Siteplan Status Tab Content - with pills for Tahap 1 / Tahap 2
  Widget _buildSiteplanStatusTab(
    BuildContext context,
    ThemeController themeController,
  ) {
    final isDark = themeController.isDarkMode;
    final tahap1Url = controller.firstSiteplan?.imageUrl;
    final tahap2Url = controller.firstSiteplan?.imageTahap2Url;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.895,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: isDark ? Colors.black : Colors.white,
            child: Column(
              children: [
                // Pills / TabBar like virtualtour_page.dart
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                  child: Container(
                    width: 260,
                    height: 34,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TabBar(
                      controller: _statusTabController,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark
                          ? Colors.white70
                          : Colors.black54,
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      tabs: [
                        Tab(text: 'Tahap 1'),
                        Tab(text: 'Tahap 2'),
                      ],
                    ),
                  ),
                ),

                // Content area
                Expanded(
                  child: TabBarView(
                    controller: _statusTabController,
                    children: [
                      // Tahap 1 - existing image
                      Container(
                        color: isDark ? Colors.grey[900] : Colors.grey[200],
                        child: _buildZoomableImage(
                          imageUrl: tahap1Url ?? '',
                          fit: BoxFit.contain,
                          themeController: themeController,
                        ),
                      ),

                      // Tahap 2 - imageTahap2Url (fallback to placeholder if empty)
                      Container(
                        color: isDark ? Colors.grey[900] : Colors.grey[200],
                        child: (tahap2Url?.isNotEmpty ?? false)
                            ? _buildZoomableImage(
                                imageUrl: tahap2Url ?? '',
                                fit: BoxFit.contain,
                                themeController: themeController,
                              )
                            : Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Text(
                                    'No image available for Tahap 2',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Kawasan 360 Tab Content
  Widget _buildKawasan360Tab(
    BuildContext context,
    ThemeController themeController,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height * 0.895,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            color: themeController.isDarkMode ? Colors.black : Colors.white,
            child: _buildPanoramaViewer(),
          ),
        ),
      ),
    );
  }

  // Coming Soon Widget (Reusable)
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
      final isExploration = controller.isExplorationMode.value;
      final isTransitioning = controller.isTransitioning.value;
      final rotation = controller.planetRotation.value;
      final currentPanoIndex =
          controller.panoId; // Ambil index aktif untuk highlight

      return AnimatedBuilder(
        animation: controller.animController,
        builder: (context, child) {
          // SCENARIO 1: Gunakan variabel lokal 'isExploration'
          if (isExploration) {
            return Stack(
              children: [
                // 1. Panorama Viewer Utama
                Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      // Scroll wheel: dy > 0 (scroll down) -> Zoom Out?
                      // dy < 0 (scroll up) -> Zoom In
                      final delta = event.scrollDelta.dy;
                      if (delta < 0) {
                        controller.handleZoom(0.1);
                      } else {
                        controller.handleZoom(-0.1);
                      }
                    }
                    if (event is PointerScaleEvent) {
                      // Trackpad pinch
                      if (event.scale > 1.0) {
                        controller.handleZoom(0.05); // Zoom In
                      } else if (event.scale < 1.0) {
                        controller.handleZoom(-0.05); // Zoom Out
                      }
                    }
                  },
                  child: PanoramaViewer(
                    latitude: controller.initialPanoLat,
                    longitude: controller.initialPanoLon,
                    zoom: controller.panoZoom.value,
                    interactive: true,
                    animSpeed: 0,
                    sensorControl: SensorControl.none,
                    child: controller.currentPanoAsset,
                    onViewChanged: controller.onViewChanged,
                    hotspots: controller.hotspots
                        .map(
                          (h) => Hotspot(
                            latitude: h.latitude,
                            longitude: h.longitude,
                            width: 90.0,
                            height: 90.0,
                            widget: GestureDetector(
                              onTap: () =>
                                  controller.onHotspotTap(h.targetIndex),
                              child: Column(
                                children: [
                                  Image.asset(
                                    'assets/vtourskin_hotspot0.png',
                                    width: 40,
                                    height: 40,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      h.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),

                // 2.A Zoom Controls (Tombol Zoom In/Out)
                Positioned(
                  bottom: 120, // Di atas panel bawah (jika ada) atau sesuaikan
                  right: 20,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'pano_zoom_in',
                        onPressed: controller.zoomIn,
                        backgroundColor: Colors.white.withOpacity(0.8),
                        child: const Icon(Icons.add, color: Colors.black),
                      ),
                      const SizedBox(height: 12),
                      FloatingActionButton.small(
                        heroTag: 'pano_zoom_out',
                        onPressed: controller.zoomOut,
                        backgroundColor: Colors.white.withOpacity(0.8),
                        child: const Icon(Icons.remove, color: Colors.black),
                      ),
                    ],
                  ),
                ),

                // 3. PANEL SAMPING (SIDEBAR) BARU
                Obx(
                  () => AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: controller.isSidebarVisible.value
                        ? 20
                        : -280, // Slide out
                    top: 100,
                    bottom: 100,
                    width: 260,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 16,
                      ), // ... existing decoration
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(
                          0.9,
                        ), // Sedikit transparan agar elegan
                        borderRadius: BorderRadius.circular(
                          24,
                        ), // Rounded sudut
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        // ... existing contents
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header kecil (Opsional)
                          Padding(
                            padding: const EdgeInsets.only(left: 8, bottom: 16),
                            child: Text(
                              "Locations",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),

                          // List Panorama
                          Expanded(
                            child: ListView.separated(
                              itemCount: controller.panoAssets.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final isSelected = currentPanoIndex == index;
                                // Ambil label dari controller, fallback jika index out of bound
                                final label =
                                    (index < controller.panoLabels.length)
                                    ? controller.panoLabels[index]
                                    : 'Location ${index + 1}';

                                return GestureDetector(
                                  onTap: () => controller.selectPanorama(index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withOpacity(
                                              0.2,
                                            ) // Highlight bg jika dipilih
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        // 1. THUMBNAIL BULAT
                                        Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.transparent,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              if (isSelected)
                                                BoxShadow(
                                                  color: Colors.black26,
                                                  blurRadius: 4,
                                                ),
                                            ],
                                          ),
                                          child: ClipOval(
                                            child: Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                controller
                                                    .panoAssets[index], // Gambar
                                                if (!isSelected) // Gelapkan yang tidak aktif
                                                  Container(
                                                    color: Colors.black
                                                        .withOpacity(0.3),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        const SizedBox(
                                          width: 12,
                                        ), // Jarak spasi
                                        // 2. CAPTION TEKS
                                        Expanded(
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.white70,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Sidebar Toggle Button
                Obx(
                  () => AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    // Visible: Sidebar ends at 20+260 = 280.
                    // Button width 40. Centered on edge = 280 - 20 = 260.
                    // Hidden: Sidebar at -280. Button should have margin. Let's use 20.
                    left: controller.isSidebarVisible.value ? 260 : 20,
                    top: 0,
                    bottom: 0,
                    width: 40,
                    child: Center(
                      child: GestureDetector(
                        onTap: controller.toggleSidebar,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            controller.isSidebarVisible.value
                                ? Icons.chevron_left
                                : Icons.chevron_right,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 4. White Fade Overlay (Scenario 1)
                Obx(
                  () => IgnorePointer(
                    child: Container(
                      color: Colors.white.withOpacity(
                        controller.whiteOpacity.value,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // SCENARIO 2: Masih Tiny Planet / Transisi (CODE LAMA TETAP SAMA)
          return Stack(
            // ... (Code scenario 2 tidak berubah) ...
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onScaleStart: controller.onTinyPlanetScaleStart,
                onScaleUpdate: controller.onTinyPlanetScaleUpdate,
                child: TinyPlanetWidget(
                  imageProvider: const AssetImage(
                    'assets/pano_flip.jpg',
                  ), // Pastikan ini sesuai
                  rotation: rotation,
                  scale: isTransitioning
                      ? controller.scaleAnimation.value
                      : controller.tinyPlanetScale.value,
                ),
              ),
              // LayoutBuilder untuk mendapatkan ukuran layar bagi projection
              LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: _buildTinyPlanetHotspots(
                      constraints.maxWidth,
                      constraints.maxHeight,
                      rotation,
                      isTransitioning
                          ? controller.scaleAnimation.value
                          : controller.tinyPlanetScale.value,
                    ),
                  );
                },
              ),

              // 3. White Fade Overlay
              Obx(
                () => IgnorePointer(
                  child: Container(
                    color: Colors.white.withOpacity(
                      controller.whiteOpacity.value,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
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

  List<Widget> _buildTinyPlanetHotspots(
    double width,
    double height,
    double rotation,
    double scale,
  ) {
    if (width <= 0 || height <= 0) return [];

    return controller.hotspots.map((h) {
      // Projection Math
      // 1. Convert Lat/Lon to Radians
      // Map Lat -90 (Center/SouthPole) to 0, +90 to PI?
      // Based on shader flip assumption:
      // Lat -90 -> Phi 0
      // Lat 90 -> Phi PI
      final phi = (h.latitude + 90) * (math.pi / 180.0);
      final theta = h.longitude * (math.pi / 180.0);

      // 2. Inverse Stereographic (Tiny Planet)
      // r = scale * tan(phi / 2)
      // Note: clip phi closely to PI to avoid infinity?
      // If phi is PI (Lat 90), tan(PI/2) is infinity.
      // But TinyPlanet usually sees -90 to approx 0 or so.
      final r = scale * math.tan(phi / 2.0);

      // 3. Angle on Screen
      // Shader: theta = angle + rotation => angle = theta - rotation
      final angle = theta - rotation;

      // 4. Polar to Cartesian (UV Space approx -1 to 1)
      // Note: Screen Y is usually down, but mathematical Y is up.
      // Shader: atan(uv.y, uv.x).
      // Flutter Coordinate: Top-Left is 0,0.
      // We'll calculate standard Cartesian first (Right X+, Up Y+)
      var u = r * math.cos(angle);
      var v = r * math.sin(angle);

      // 5. Aspect Ratio Correction (Reverse of Shader)
      if (width > height) {
        // Landscape: uv.x was multiplied by (w/h) in shader
        // So we divide by (w/h) to get back to "0..1" equivalent space?
        // Wait, 'u' calculated above corresponds to the *stretched* coordinate system?
        // No, 'r' and 'angle' are derived FROM the stretched coordinates.
        // So 'u' and 'v' ARE the stretched coordinates.
        // We need to un-stretch to get back to normalized square bounds relative to screen dimensions.
        u = u / (width / height);
      } else {
        // Portrait: uv.y was multiplied by (h/w)
        v = v / (height / width);
      }

      // 6. Map to Screen Coordinates
      // u, v are range approx -1..1 (if r=1).
      // Center is 0,0
      final cx = width / 2;
      final cy = height / 2;

      // Invert Y because screen Y is down
      // But atan(y,x) in shader standard math likely assumes Y up.
      // Or checking FlutterFragCoord...
      // Let's assume standard Y-up for calculation, then invert for screen.
      // Also need to check if 'r' exceeds visible bounds.
      // If r is huge, it's behind the camera or far out.

      final screenX = cx + (u * cx); // u * (width/2)
      final screenY =
          cy +
          (v *
              cy); // v * (height/2). Flip sign if needed. Assuming y+ is down in shader?
      // Shader: uv = st * 2.0 - 1.0. st 0..1 (Top-Left 0,0).
      // uv -1,-1 is Top-Left?
      // atan(-1, -1) -> -135 deg (South West).
      // If V is positive down, then atan(y,x) is correct?
      // Let's try direct mapping.

      // Bound check to avoid drawing off-screen or weird infinity
      if (r > 10.0) return const SizedBox.shrink(); // Too far

      return Positioned(
        left: screenX - 20, // Center the 40px icon
        top: screenY - 20,
        child: GestureDetector(
          onTap: () => controller.onHotspotTap(h.targetIndex),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/vtourskin_hotspot0.png',
                width: 40,
                height: 40,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  h.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

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
