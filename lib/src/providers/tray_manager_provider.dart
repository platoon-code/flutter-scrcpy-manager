import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/cmd_run.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../utils/constant_string.dart';
import 'theme_provider.dart';

final trayManagerProvider = AutoDisposeAsyncNotifierProvider<TrayManagerNotifier, void>(TrayManagerNotifier.new);

final isExitAppProvider = StateProvider<bool>((ref) => false);
final isAboutppProvider = StateProvider<bool>((ref) => false);
final isDarkThemeProvider = StateProvider<bool>((ref) => false);
final pageControllerProvider = Provider<PageController>((ref) => PageController(initialPage: 0));

class TrayManagerNotifier extends AutoDisposeAsyncNotifier<void> with TrayListener {
  @override
  Future<void> build() async => trayManager.addListener(this);

  Future<void> initialized() async {
    log('TrayManager initialized');
    await trayManager.setIcon(ConstantString.fIappIco);
    await trayManager.setToolTip(ConstantString.fApp);
    await trayManager.setContextMenu(_buildMenu());
    await windowManager.setPreventClose(true);
  }

  Menu _buildMenu() {
    return Menu(
      items: <MenuItem>[
        MenuItem(
          label: ConstantString.fOpenScrcpyManager,
          onClick: (menuItem) => onTapOpenScrcpy(),
        ),
        MenuItem(
          label: "Buka Console",
          onClick: (menuItem) => onTapOpenConsole(),
        ),
        MenuItem.separator(),
        MenuItem.submenu(
          label: ConstantString.fThemeMode,
          submenu: Menu(
            items: <MenuItem>[
              MenuItem(
                label: ConstantString.fDark,
                onClick: (menuItem) => _onTapDarkMode(),
              ),
              MenuItem(
                label: ConstantString.fLight,
                onClick: (menuItem) => _onTapLightMode(),
              ),
            ],
          ),
        ),
        MenuItem.separator(),
        MenuItem(
          label: ConstantString.fAbout,
          onClick: (menuItem) => _onTapAbout(),
        ),
        MenuItem(
          label: ConstantString.fExit,
          onClick: (menuItem) => onTapExit(),
        ),
      ],
    );
  }

  @override
  void onTrayIconMouseDown() async {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() async {
    trayManager.popUpContextMenu();
  }

  Future<void> _onTapLightMode() async {
    ref.read(themeProvider.notifier).isLight();
    await windowManager.restore();
  }

  Future<void> _onTapDarkMode() async {
    ref.read(themeProvider.notifier).isDark();
    await windowManager.restore();
  }

  Future<void> _onTapAbout() async {
    ref.read(isAboutppProvider.notifier).state = true;
    await windowManager.restore();
  }

  Future<void> onTapOpenScrcpy() async {
    ref.read(pageControllerProvider).animateToPage(
          0,
          duration: const Duration(milliseconds: 10),
          curve: Curves.linear,
        );
    await windowManager.restore();
  }

  Future<void> onTapOpenConsole() async {
    ref.read(pageControllerProvider).animateToPage(
          1,
          duration: const Duration(milliseconds: 10),
          curve: Curves.linear,
        );
    await windowManager.restore();
  }

  Future<void> onTapExit() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      ref.read(isExitAppProvider.notifier).state = true;
    }
    await windowManager.restore();
  }

  Future<void> onTapIconApp() async => trayManager.popUpContextMenu();

  Future<void> onExit() async {
    await windowManager.destroy();
  }

  Future<void> onExitAndDisconnect() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? scrcpyVersion = prefs.getString('version');
    final Directory appDocumentsDir = await getApplicationSupportDirectory();
    String adbPath = '${appDocumentsDir.path}/scrcpy-win64-$scrcpyVersion';
    ProcessCmd cmdDisconnect = ProcessCmd(workingDirectory: adbPath, 'adb', ['disconnect']);
    ProcessCmd cmdKillServer = ProcessCmd(workingDirectory: adbPath, 'adb', ['kill-server']);
    await runCmd(cmdDisconnect);
    await runCmd(cmdKillServer);
    await windowManager.destroy();
  }
}
