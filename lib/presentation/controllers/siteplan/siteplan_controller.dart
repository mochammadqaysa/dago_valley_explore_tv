import 'dart:io' as io;
import 'package:dago_valley_explore_tv/app/services/local_storage.dart';
import 'package:dago_valley_explore_tv/domain/entities/site_plan.dart';
import 'package:dago_valley_explore_tv/presentation/controllers/siteplan/detailsiteplan/detail_siteplan_binding.dart';
import 'package:dago_valley_explore_tv/presentation/pages/siteplan/detail_siteplan/detail_siteplan_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// ✅ Enum untuk tab types
enum SiteplanTabType {
  map,
  fasum,
  timelineProgress,
  siteplanStatus,
  kawasan360;

  String get label {
    switch (this) {
      case SiteplanTabType.map:
        return 'Map';
      case SiteplanTabType.fasum:
        return 'Fasum';
      case SiteplanTabType.timelineProgress:
        return 'Timeline Progress';
      case SiteplanTabType.siteplanStatus:
        return 'Siteplan Status';
      case SiteplanTabType.kawasan360:
        return 'Kawasan 360';
    }
  }

  IconData get icon {
    switch (this) {
      case SiteplanTabType.map:
        return Icons.map;
      case SiteplanTabType.fasum:
        return Icons.location_city;
      case SiteplanTabType.timelineProgress:
        return Icons.timeline;
      case SiteplanTabType.siteplanStatus:
        return Icons.assignment;
      case SiteplanTabType.kawasan360:
        return Icons.threesixty;
    }
  }
}

class SiteplanController extends GetxController
    with GetTickerProviderStateMixin {
  SiteplanController();
  final LocalStorageService _storage = Get.find<LocalStorageService>();

  // ... (existing code)

  // ✅ Initial Pano Coordinates (Target)
  final double initialPanoLat = -25.584960968377505;
  final double initialPanoLon = -3.3566056649560116;

  // ✅ Fade Transition State
  late AnimationController fadeController;
  final RxDouble whiteOpacity = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    // Setup Animasi Transisi (Durasi 2 Detik)
    animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    // Setup Fade Controller (Fade In setelah pindah mode)
    // Value 1.0 = Transparent, 0.0 = White
    fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
      value: 1.0,
    );

    // Tween Scale: Tiny Planet (0.5) -> Zoomed In (4.0)
    scaleAnimation = Tween<double>(begin: 0.5, end: 4.0).animate(
      CurvedAnimation(parent: animController, curve: Curves.easeInOutExpo),
    );

    // Listener: Kalau animasi selesai, ganti widget ke PanoramaViewer asli
    animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // 1. Switch Mode (Behind White Screen)
        isExplorationMode.value = true;
        isTransitioning.value = false;

        // 2. Start Fade In (White -> Transparent)
        // Set controller to 0 (White) then animate to 1 (Transparent)
        fadeController.value = 0.0;
        fadeController.forward();
      }
    });

    // Listener untuk update UI saat animasi berjalan
    animController.addListener(() {
      if (isTransitioning.value) {
        // Update planetRotation value from animation
        // Logic Fade to White (Start at 20% progress)
        // Value 0.2 -> 1.0 maps to Opacity 0.0 -> 1.0
        if (animController.value > 0.2) {
          double normalized = (animController.value - 0.2) / 0.8;
          whiteOpacity.value = normalized.clamp(0.0, 1.0);
        } else {
          whiteOpacity.value = 0.0;
        }
      }
    });

    // Listener Fade Controller (White -> Transparent)
    fadeController.addListener(() {
      // Value 0.0 -> 1.0 maps to Opacity 1.0 -> 0.0
      whiteOpacity.value = 1.0 - fadeController.value;
    });

    _initializePanorama();
    loadSiteplans();
  }

  // ✅ Tab state
  final _selectedTab = Rx<SiteplanTabType>(SiteplanTabType.map);
  SiteplanTabType get selectedTab => _selectedTab.value;

  // Panorama state
  final _panoId = 0.obs;
  int get panoId => _panoId.value;

  final _lon = 0.0.obs;
  double get lon => _lon.value;

  final _lat = 0.0.obs;
  double get lat => _lat.value;

  final _tilt = 0.0.obs;
  double get tilt => _tilt.value;

  final _showDebugInfo = false.obs;
  bool get showDebugInfo => _showDebugInfo.value;

  // Sidebar Visibility
  final RxBool isSidebarVisible = true.obs;
  void toggleSidebar() => isSidebarVisible.toggle();

  final _currentIndex = 0.obs;
  int get currentIndex => _currentIndex.value;

  // Observable untuk list siteplan
  final _siteplans = RxList<SitePlan>([]);
  List<SitePlan> get siteplans => _siteplans;
  SitePlan? get firstSiteplan =>
      _siteplans.isNotEmpty ? _siteplans.first : null;

  // Panorama assets
  final panoAssets = <Image>[
    Image.asset('assets/pano.jpg', fit: BoxFit.cover),
    Image.asset('assets/pano_2.jpg', fit: BoxFit.cover),
    Image.asset('assets/pano_3.jpg', fit: BoxFit.cover),
  ];

  final List<String> panoLabels = ['All', 'Tropica', 'Foresta dan Harmoni'];

  // Get current panorama asset
  Image get currentPanoAsset => panoAssets[_panoId.value % panoAssets.length];

  // Check if running on desktop
  bool get isDesktop {
    return !kIsWeb &&
        (io.Platform.isWindows || io.Platform.isLinux || io.Platform.isMacOS);
  }

  // ✅ Hotspots Data
  final hotspots = <SiteplanHotspot>[
    SiteplanHotspot(
      name: 'Foresta dan Harmoni',
      latitude: -25.0, // Swapped
      longitude: -80.0,
      targetIndex: 2, // Index di panoAssets
    ),
    SiteplanHotspot(
      name: 'Tropica',
      latitude: -55.0, // Adjusted based on image
      longitude: 15.0, // Adjusted based on image
      targetIndex: 1, // Index di panoAssets
    ),
  ];

  // ✅ Zoom 360 Control
  final RxDouble panoZoom = 1.0.obs;

  // State Tiny Planet Zoom
  final RxDouble tinyPlanetScale = 0.5.obs;
  double _baseScale = 0.5;

  void onTinyPlanetScaleStart(ScaleStartDetails details) {
    _baseScale = tinyPlanetScale.value;
  }

  void onTinyPlanetScaleUpdate(ScaleUpdateDetails details) {
    if (isTransitioning.value || isExplorationMode.value) return;

    // Handle Rotation (One finger or Two fingers pan)
    // details.focalPointDelta.dx gives the movement
    if (details.pointerCount == 1 || details.scale == 1.0) {
      rotatePlanet(details.focalPointDelta.dx);
    }

    // Handle Scale (Pinch)
    if (details.pointerCount > 1) {
      double newScale = _baseScale * details.scale;
      // Limit scale
      if (newScale < 0.1) newScale = 0.1;
      if (newScale > 2.0) newScale = 2.0;

      tinyPlanetScale.value = newScale;

      if (kDebugMode) {
        print('TinyPlanet Scale: ${tinyPlanetScale.value}');
      }
    }
  }

  // Helper untuk update zoom dari scroll/pinch
  void handleZoom(double zoomDelta) {
    // zoomDelta > 0 means zoom in, < 0 means zoom out (sensitivitas diatur caller)
    double newZoom = panoZoom.value + zoomDelta;
    // Clamp
    if (newZoom < 0.5) newZoom = 0.5;
    if (newZoom > 3.0) newZoom = 3.0;
    panoZoom.value = newZoom;
  }

  void zoomIn() {
    handleZoom(0.2);
  }

  void zoomOut() {
    handleZoom(-0.2);
  }

  void onHotspotTap(int index) {
    if (index >= 0 && index < panoAssets.length) {
      selectPanorama(index);
      // Force switch to exploration mode if not already
      if (!isExplorationMode.value) {
        startTransition();
        // Short delay to allow transition to start before skipping to end?
        // Or just set state directly. Let's trigger normal transition.
      }
    }
  }

  void loadSiteplans() {
    final cachedSiteplans = _storage.siteplans;
    if (cachedSiteplans != null && cachedSiteplans.isNotEmpty) {
      print('✅ Using cached siteplan: ${cachedSiteplans.length} items');
      _siteplans.assignAll(cachedSiteplans);
    } else {
      print('⚠️ Using dummy siteplan');
      // _siteplans.assignAll(dummyPromos);
    }
  }

  SitePlan? get currentSiteplan {
    if (_siteplans.isEmpty) {
      return null;
    }
    // Ensure index is within bounds
    if (_currentIndex.value >= _siteplans.length) {
      return _siteplans.first;
    }
    return _siteplans[_currentIndex.value];
  }

  void selectPanorama(int index) async {
    if (index >= 0 && index < panoAssets.length) {
      // Jika mode eksplorasi, mainkan fade transition
      if (isExplorationMode.value) {
        // 1. Fade Out (Transparent -> White)
        await fadeController.reverse(from: 1.0); // 1.0 -> 0.0

        // 2. Change Image
        _panoId.value = index;

        // 3. Fade In (White -> Transparent)
        await fadeController.forward(from: 0.0); // 0.0 -> 1.0
      } else {
        // Jika masih Tiny Planet, langsung ganti (nanti animasi transisi yang handle fade)
        _panoId.value = index;
      }

      if (kDebugMode) {
        print('Selected panorama index: $index');
      }
    }
  }

  // Fungsi dipanggil saat tombol "Mulai" ditekan
  void startTransition() {
    isTransitioning.value = true;

    // Tween Scale: Dari scale saat ini ke 4.0
    scaleAnimation = Tween<double>(begin: tinyPlanetScale.value, end: 4.0)
        .animate(
          CurvedAnimation(parent: animController, curve: Curves.easeInOutExpo),
        );

    animController.forward(); // Jalankan animasi zoom in
  }

  void _initializePanorama() {
    if (kDebugMode) {
      print('Initializing Siteplan Panorama');
    }
  }

  // ✅ Change selected tab
  void setSelectedTab(SiteplanTabType tab) {
    _selectedTab.value = tab;
    if (kDebugMode) {
      print('Tab changed to: ${tab.label}');
    }

    // Auto-start transition if Kawasan 360 is selected
    if (tab == SiteplanTabType.kawasan360) {
      // Reset to Tiny Planet state first
      resetPlanet();

      // Start transition with slight delay to allow UI to rebuild
      Future.delayed(const Duration(milliseconds: 300), () {
        if (selectedTab == SiteplanTabType.kawasan360) {
          startTransition();
        }
      });
    }
  }

  // Update panorama view
  void onViewChanged(double longitude, double latitude, double tilt) {
    _lon.value = longitude;
    _lat.value = latitude;
    _tilt.value = tilt;
    if (kDebugMode) {
      print('Panorama View: lon=$longitude, lat=$latitude, tilt=$tilt');
    }
  }

  // Handle panorama tap
  void onPanoramaTap(double longitude, double latitude, double tilt) {
    if (kDebugMode) {
      print('onTap: $longitude, $latitude, $tilt');
    }
  }

  // Go to next panorama
  void goToNextPanorama() {
    _panoId.value = (_panoId.value + 1) % panoAssets.length;
    if (kDebugMode) {
      print('Switched to panorama: ${_panoId.value}');
    }
  }

  // Go to previous panorama
  void goToPreviousPanorama() {
    _panoId.value = (_panoId.value - 1 + panoAssets.length) % panoAssets.length;
    if (kDebugMode) {
      print('Switched to panorama: ${_panoId.value}');
    }
  }

  // Toggle debug info
  void toggleDebugInfo() {
    _showDebugInfo.value = !_showDebugInfo.value;
  }

  // Show notify snackbar
  void showNotifySnack() {
    Get.snackbar(
      'Terima Kasih',
      'Kami akan memberi tahu Anda saat fitur Siteplan tersedia.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  // Get brochure URL from storage
  String? getBrochureUrl() {
    try {
      final brochures = _storage.brochures;
      if (kDebugMode) {
        print('Fetched brochures from local storage: $brochures');
      }
      if (brochures != null && brochures.isNotEmpty) {
        final first = brochures.first;
        return first.imageUrl?.toString();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching brochures from local storage: $e');
      }
    }
    return null;
  }

  // Show siteplan modal
  void showSitePlanModal([String? url]) {
    if (url == null || url.isEmpty) {
      url = getBrochureUrl();
    }

    if (url == null || url.isEmpty) {
      Get.snackbar(
        'Site Plan',
        'Tidak ada URL brochure yang tersedia.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.black87,
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (kDebugMode) {
      print('Opening Siteplan detail modal with url: $url');
    }

    Get.to(
      () => const SiteplanDetailPage(),
      binding: DetailSiteplanBinding(),
      arguments: url,
      transition: Transition.fade,
      duration: const Duration(milliseconds: 400),
      opaque: false,
      fullscreenDialog: true,
    );
  }

  // Get sensor control based on platform
  dynamic get sensorControl {
    return isDesktop ? 'none' : 'orientation';
  }

  // State untuk kontrol kamera Panorama
  // Awalnya set ke Tiny Planet: Lihat bawah (-90) dan Zoom out (0.4)
  final RxDouble currentLat = (-90.0).obs;
  final RxDouble currentZoom =
      0.5.obs; // Sesuaikan angka ini (0.1 - 1.0) agar bulatnya pas
  final RxBool isTinyPlanetMode = true.obs;

  // ANIMATION CONTROLLER
  late AnimationController animController;
  late Animation<double> scaleAnimation;

  // State interaksi
  final RxDouble planetRotation = 0.0.obs;
  final RxBool isTransitioning = false.obs; // Sedang proses masuk?
  final RxBool isExplorationMode = false.obs; // Sudah mode 360 biasa?

  // Fungsi untuk memulai transisi dari Tiny Planet ke Normal View
  void startExploreMode() {
    isTinyPlanetMode.value = false;

    // Ubah ke pandangan normal
    currentLat.value = 0.0; // Lihat horizon
    currentZoom.value = 1.0; // Zoom normal

    update(); // Force update jika perlu
  }

  // Fungsi untuk kembali ke mode Tiny Planet (opsional)
  void resetToTinyPlanet() {
    isTinyPlanetMode.value = true;
    currentLat.value = -90.0;
    currentZoom.value = 0.5;
  }

  final RxDouble tinyPlanetRotation = 0.0.obs;

  // Method untuk update rotasi saat didrag
  void updateTinyPlanetRotation(double delta) {
    // Sensitivitas putaran
    // Semakin kecil angkanya, semakin pelan putarannya
    tinyPlanetRotation.value += delta * 0.005;
  }

  // Fungsi dipanggil saat user swipe jari di Tiny Planet
  void rotatePlanet(double delta) {
    if (!isTransitioning.value && !isExplorationMode.value) {
      planetRotation.value -= delta * 0.005; // Sesuaikan sensitivitas
      if (kDebugMode) {
        print('LOG_ROTATION: ${planetRotation.value}');
      }
    }
  }

  // Reset (untuk debugging)
  void resetPlanet() {
    isExplorationMode.value = false;
    isTransitioning.value = false;
    animController.reset();
  }

  @override
  void onClose() {
    animController.dispose();
    super.onClose();
  }
}

class SiteplanHotspot {
  final String name;
  final double latitude;
  final double longitude;
  final int targetIndex;

  SiteplanHotspot({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.targetIndex,
  });
}
