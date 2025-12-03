import 'package:dago_valley_explore_tv/app/translation/app_translations.dart';
import 'package:dago_valley_explore_tv/presentation/controllers/sidebar/sidebar_binding.dart';
import 'package:dago_valley_explore_tv/presentation/controllers/splash/splash_binding.dart';
import 'package:dago_valley_explore_tv/presentation/controllers/theme/theme_controller.dart';
import 'package:dago_valley_explore_tv/presentation/controllers/locale/locale_controller.dart';
import 'package:dago_valley_explore_tv/presentation/pages/splashscreen/splashscreen_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_onscreen_keyboard/flutter_onscreen_keyboard.dart';

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Initialize Controllers
    final themeController = Get.put(ThemeController(), permanent: true);
    final localeController = Get.put(LocaleController(), permanent: true);

    return Obx(
      () => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'app_name'.tr,

        // Theme configuration (use themeMode from controller)
        theme: themeController.lightTheme,
        darkTheme: themeController.darkTheme,
        themeMode: themeController.themeMode,

        // Locale configuration
        locale: localeController.currentLocale,
        translations: AppTranslations(),
        fallbackLocale: Locale('id', 'ID'),

        initialRoute: "/",
        initialBinding: SplashBinding(),
        home: SplashScreen(),

        // ✅ TAMBAHKAN BUILDER UNTUK ONSCREEN KEYBOARD
        builder: (context, child) {
          // Wrap with OnscreenKeyboard
          return OnscreenKeyboard(
            theme: _buildKeyboardTheme(themeController),
            child: child ?? const SizedBox(),
          );
        },
      ),
    );
  }

  // ✅ Dynamic keyboard theme based on app theme
  OnscreenKeyboardThemeData _buildKeyboardTheme(
    ThemeController themeController,
  ) {
    if (themeController.isDarkMode) {
      // Dark theme keyboard
      return OnscreenKeyboardThemeData(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
        textKeyThemeData: TextKeyThemeData(
          backgroundColor: Colors.grey[800],
          foregroundColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
          margin: const EdgeInsets.all(2),
          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        actionKeyThemeData: ActionKeyThemeData(
          backgroundColor: Colors.grey[700],
          foregroundColor: Colors.white70,
          pressedBackgroundColor: Colors.orange[700],
          pressedForegroundColor: Colors.white,
          borderRadius: BorderRadius.circular(8),
          margin: const EdgeInsets.all(2),
          iconSize: 20,
        ),
      );
    } else {
      // Light theme keyboard (Gboard style)
      return OnscreenKeyboardThemeData.gBoard();
    }
  }
}
