import 'package:carousel_slider/carousel_controller.dart' as cs;
import 'package:dago_valley_explore_tv/data/models/house_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class DetailProductController extends GetxController {
  // Carousel controller
  final carouselController = cs.CarouselSliderController();

  // Observable untuk index aktif
  final currentIndex = 0.obs;

  // Observable untuk fullscreen mode
  final isFullscreen = false.obs;

  // TransformationController untuk zoom
  final transformationController = TransformationController();

  // House model yang akan ditampilkan
  final Rx<HouseModel?> houseModel = Rx<HouseModel?>(null);

  // List gambar dan video dari house model
  final RxList<String> images = <String>[].obs;
  final RxList<String> videos = <String>[].obs;

  // Total items (images + videos)
  int get totalItems => images.length + videos.length;

  // Video players
  final Map<int, VideoPlayerController?> videoControllers = {};
  final RxMap<int, bool> videoInitialized = <int, bool>{}.obs;
  final RxMap<int, bool> videoPlaying = <int, bool>{}.obs;
  final RxMap<int, String?> videoErrors = <int, String?>{}.obs;
  final RxMap<int, bool> videoMuted = <int, bool>{}.obs;

  // Video controls visibility
  final RxMap<int, bool> showControls = <int, bool>{}.obs;
  Timer? _hideControlsTimer;

  // Track copied video files
  final List<File> _tempVideoFiles = [];

  @override
  void onInit() {
    super.onInit();

    if (Get.arguments != null && Get.arguments is HouseModel) {
      houseModel.value = Get.arguments as HouseModel;
      images.value = houseModel.value?.gambar ?? [];
      videos.value = houseModel.value?.video ?? [];

      print('📊 Product Detail Loaded:');
      print('   Model: ${houseModel.value?.model}');
      print('   Type: ${houseModel.value?.type}');
      print('   Images: ${images.length}');
      print('   Videos: ${videos.length}');

      // Initialize videos if available
      if (videos.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!isClosed) {
            _initializeVideoPlayers();
          }
        });
      }
    }
  }

  void pauseVideo(int index) {
    final videoController = getVideoController(index);
    if (videoController != null && videoController.value.isPlaying) {
      videoController.pause();
      videoPlaying[index] = false;
    }
  }

  // Check if asset exists
  Future<bool> _checkAssetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Copy asset to temp directory
  Future<File?> _copyAssetToTemp(String assetPath) async {
    try {
      print('📦 Copying video asset: $assetPath');

      final exists = await _checkAssetExists(assetPath);
      if (!exists) {
        print('❌ Asset not found: $assetPath');
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = assetPath.split('/').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath =
          '${tempDir.path}${Platform.pathSeparator}video_$timestamp\_$fileName';

      print('   Loading asset bytes...');
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      print('   Writing ${bytes.length} bytes to temp file...');
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      if (!await file.exists() || await file.length() == 0) {
        print('❌ Failed to create temp file');
        return null;
      }

      print('✅ Video copied to: $filePath');
      print('   File size: ${await file.length()} bytes');

      _tempVideoFiles.add(file);
      return file;
    } catch (e, stackTrace) {
      print('❌ Error copying asset: $e');
      print('   Stack: $stackTrace');
      return null;
    }
  }

  // Initialize video players
  void _initializeVideoPlayers() async {
    print('\n🎬 Initializing ${videos.length} video(s)...');

    for (int i = 0; i < videos.length; i++) {
      final videoIndex = images.length + i;
      final videoPath = videos[i];

      try {
        videoInitialized[videoIndex] = false;
        videoPlaying[videoIndex] = false;
        videoErrors[videoIndex] = null;
        videoMuted[videoIndex] = false;
        showControls[videoIndex] = true;

        print('\n📹 Video $i: $videoPath');

        // Copy asset to temp file
        final tempFile = await _copyAssetToTemp(videoPath);
        if (tempFile == null) {
          throw Exception('Failed to copy video to temp directory');
        }

        // Create controller from file
        print('   Creating VideoPlayerController.. .');
        final controller = VideoPlayerController.file(tempFile);
        videoControllers[videoIndex] = controller;

        // Initialize with timeout
        print('   Initializing controller...');
        await controller
            .initialize()
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw Exception('Video initialization timeout');
              },
            )
            .then((_) {
              if (!isClosed && controller.value.isInitialized) {
                print('   Setting up video properties...');

                // Set looping
                controller.setLooping(true);
                controller.setVolume(1.0);

                videoInitialized[videoIndex] = true;

                // Add listener for playback state
                controller.addListener(() {
                  if (!isClosed && videoControllers[videoIndex] != null) {
                    final isPlaying = controller.value.isPlaying;
                    if (videoPlaying[videoIndex] != isPlaying) {
                      videoPlaying[videoIndex] = isPlaying;
                    }
                  }
                });

                print('✅ Video initialized successfully! ');
                print('   Duration: ${controller.value.duration}');
                print('   Size: ${controller.value.size}');
                print('   Aspect Ratio: ${controller.value.aspectRatio}');
              }
            })
            .catchError((error, stackTrace) {
              if (!isClosed) {
                final errorMsg = 'Init error: $error';
                videoErrors[videoIndex] = errorMsg;
                videoInitialized[videoIndex] = false;
                print('❌ $errorMsg');

                try {
                  controller.dispose();
                  videoControllers[videoIndex] = null;
                } catch (e) {
                  print('   Dispose error: $e');
                }
              }
            });

        await Future.delayed(const Duration(milliseconds: 300));
      } catch (e, stackTrace) {
        if (!isClosed) {
          final errorMsg = 'Exception: $e';
          videoErrors[videoIndex] = errorMsg;
          videoInitialized[videoIndex] = false;
          print('❌ $errorMsg');
          print('   Stack: $stackTrace');
        }
      }
    }

    print('\n✅ Video initialization complete\n');
  }

  // Show controls and start hide timer
  void showVideoControls(int index) {
    showControls[index] = true;
    _resetHideTimer(index);
  }

  // Hide controls
  void hideVideoControls(int index) {
    showControls[index] = false;
  }

  // Reset hide timer
  void _resetHideTimer(int index) {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (!isClosed) {
        hideVideoControls(index);
      }
    });
  }

  // Toggle video playback
  void toggleVideoPlayback(int index) {
    try {
      final controller = videoControllers[index];
      if (controller != null &&
          videoInitialized[index] == true &&
          controller.value.isInitialized) {
        if (controller.value.isPlaying) {
          controller.pause();
          print('⏸️ Video paused at index $index');
        } else {
          controller.play();
          print('▶️ Video playing at index $index');
        }
        showVideoControls(index);
      }
    } catch (e) {
      print('❌ Error toggling playback: $e');
    }
  }

  // Toggle mute
  void toggleMute(int index) {
    try {
      final controller = videoControllers[index];
      if (controller != null && controller.value.isInitialized) {
        final isMuted = videoMuted[index] ?? false;
        controller.setVolume(isMuted ? 1.0 : 0.0);
        videoMuted[index] = !isMuted;
        showVideoControls(index);
        print('🔊 Video ${isMuted ? "unmuted" : "muted"} at index $index');
      }
    } catch (e) {
      print('❌ Error toggling mute: $e');
    }
  }

  // Check if current item is video
  bool isVideo(int index) => index >= images.length;

  // Get video controller
  VideoPlayerController? getVideoController(int index) =>
      videoControllers[index];

  // Get video index
  int getVideoIndex(int carouselIndex) => carouselIndex - images.length;

  // Pause all videos
  void pauseAllVideos() {
    try {
      videoControllers.forEach((index, controller) {
        if (controller != null &&
            controller.value.isInitialized &&
            controller.value.isPlaying) {
          try {
            controller.pause();
          } catch (e) {
            print('Error pausing video $index: $e');
          }
        }
      });
    } catch (e) {
      print('❌ Error pausing videos: $e');
    }
  }

  // Seek video
  void seekVideo(int index, Duration position) {
    try {
      final controller = videoControllers[index];
      if (controller != null && controller.value.isInitialized) {
        controller.seekTo(position);
        showVideoControls(index);
      }
    } catch (e) {
      print('❌ Error seeking: $e');
    }
  }

  // Cleanup temp files
  Future<void> _cleanupTempFiles() async {
    if (_tempVideoFiles.isEmpty) return;

    try {
      print('🧹 Cleaning ${_tempVideoFiles.length} temp file(s)...');
      for (final file in _tempVideoFiles) {
        try {
          if (await file.exists()) {
            await file.delete();
            print('   Deleted: ${file.path}');
          }
        } catch (e) {
          print('   Delete failed: ${file.path}');
        }
      }
      _tempVideoFiles.clear();
      print('✅ Cleanup complete');
    } catch (e) {
      print('❌ Cleanup error: $e');
    }
  }

  @override
  void onClose() {
    try {
      print('\n🛑 Disposing controllers...');

      _hideControlsTimer?.cancel();

      final indices = videoControllers.keys.toList();
      for (final index in indices) {
        final controller = videoControllers[index];
        if (controller != null) {
          try {
            if (controller.value.isInitialized && controller.value.isPlaying) {
              controller.pause();
            }
            controller.dispose();
            print('   Disposed controller at index $index');
          } catch (e) {
            print('   Dispose error for index $index: $e');
          }
        }
      }
      videoControllers.clear();

      _cleanupTempFiles();

      print('✅ All controllers disposed\n');
    } catch (e) {
      print('❌ onClose error: $e');
    }

    try {
      transformationController.dispose();
    } catch (e) {
      // Ignore
    }

    super.onClose();
  }

  // Set current index
  void setCurrentIndex(int index) {
    pauseAllVideos();
    currentIndex.value = index;
  }

  // Go to page
  void goToPage(int index) {
    carouselController.animateToPage(index);
  }

  // Open fullscreen
  void openFullscreen() {
    isFullscreen.value = true;
  }

  // Close fullscreen
  void closeFullscreen() {
    isFullscreen.value = false;
    transformationController.value = Matrix4.identity();
  }

  // Handle booking
  void bookPromo() {
    if (houseModel.value != null) {
      Get.snackbar(
        'Booking',
        'Booking untuk ${houseModel.value!.model}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
  }

  // Close modal
  void closeModal() {
    Get.back();
  }
}
