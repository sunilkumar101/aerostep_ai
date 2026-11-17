import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Brands the setup wizard knows how to guide.
enum OemBrand { samsung, xiaomi, realme, oppo, vivo, oneplus, pixel, other }

/// 1-Tap Android OEM battery protection: requests
/// `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` and opens the vendor's auto-start /
/// battery-manager page (native code in `MainActivity.kt`) so aggressive OEM
/// task killers leave the step service alone.
abstract final class OemBattery {
  static const _channel = MethodChannel('aerostep/battery');

  static Future<OemBrand> detect() async {
    if (!Platform.isAndroid) return OemBrand.other;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return fromManufacturer('${info.manufacturer} ${info.brand}');
    } catch (_) {
      return OemBrand.other;
    }
  }

  @visibleForTesting
  static OemBrand fromManufacturer(String raw) {
    final m = raw.toLowerCase();
    if (m.contains('samsung')) return OemBrand.samsung;
    if (m.contains('xiaomi') || m.contains('redmi') || m.contains('poco')) return OemBrand.xiaomi;
    if (m.contains('realme')) return OemBrand.realme;
    if (m.contains('oneplus')) return OemBrand.oneplus;
    if (m.contains('oppo')) return OemBrand.oppo;
    if (m.contains('vivo') || m.contains('iqoo')) return OemBrand.vivo;
    if (m.contains('google') || m.contains('pixel')) return OemBrand.pixel;
    return OemBrand.other;
  }

  static Future<bool> isProtected() async {
    if (!Platform.isAndroid) return true;
    try {
      return await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Runs the protection flow for [brand]. Returns true if the standard
  /// battery-optimisation exemption is granted afterwards.
  static Future<bool> protect(OemBrand brand) async {
    if (!Platform.isAndroid) return true;
    try {
      if (!await isProtected()) {
        await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
        // Let the user answer the system dialog before opening the next page.
        await _nextResume();
      }
      switch (brand) {
        case OemBrand.xiaomi:
        case OemBrand.oppo:
        case OemBrand.vivo:
        case OemBrand.realme:
        case OemBrand.oneplus:
          // These ROMs block background restarts unless AutoStart is on.
          await _channel.invokeMethod<bool>('openAutoStart');
        case OemBrand.samsung:
          // Battery > Background usage limits > Never sleeping apps.
          await _channel.invokeMethod<bool>('openOemBatteryManager');
        case OemBrand.pixel:
        case OemBrand.other:
          break;
      }
      return isProtected();
    } catch (e) {
      debugPrint('OemBattery.protect: $e');
      return false;
    }
  }

  /// Completes when the app returns to the foreground (or after a timeout).
  static Future<void> _nextResume() {
    final done = Completer<void>();
    late final AppLifecycleListener listener;
    var wentAway = false;
    listener = AppLifecycleListener(
      onStateChange: (s) {
        if (s != AppLifecycleState.resumed) wentAway = true;
        if (s == AppLifecycleState.resumed && wentAway && !done.isCompleted) done.complete();
      },
    );
    return done.future.timeout(const Duration(seconds: 90), onTimeout: () {}).whenComplete(listener.dispose);
  }
}
