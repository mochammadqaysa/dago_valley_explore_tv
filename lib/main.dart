import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:window_manager/window_manager.dart';
import 'app/services/local_storage.dart';
import 'app/util/dependency.dart';
import 'presentation/app.dart';

void main() async {
  DependencyCreator.init();
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationSupportDirectory();
  final logFile = File('${dir.path}/startup_error.log');

  runZonedGuarded(
    () async {
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        await windowManager.ensureInitialized();

        WindowOptions windowOptions = WindowOptions(
          size: Size(3840, 2160),
          center: true,
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.hidden,
        );
        windowManager.waitUntilReadyToShow(windowOptions, () async {
          await windowManager.show();
          await windowManager.focus();
          await windowManager.setFullScreen(true);
        });
      }
      await initServices();
      runApp(App());
    },
    (error, stack) async {
      final msg = 'Uncaught error: $error\n$stack\n';
      await logFile.writeAsString(msg, mode: FileMode.append);
    },
  );
}

initServices() async {
  print('starting services ...');
  await Get.putAsync(() => LocalStorageService().init());
  print('All services started...');
}
