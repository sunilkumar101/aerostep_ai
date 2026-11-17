import '../../core/pedometer/oem_battery.dart';

/// OEM battery-protection hook for the Smart Setup screen. Requests the
/// standard `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` exemption and opens the
/// vendor's AutoStart / battery-manager page so the step service survives.
///
/// [oem] is one of [kOemSamsung], [kOemXiaomi], [kOemRealmePixel]. For the
/// combined Realme/Pixel card the device's real manufacturer decides.
Future<void> requestOemBatteryProtection(String oem) async {
  final brand = switch (oem) {
    kOemSamsung => OemBrand.samsung,
    kOemXiaomi => OemBrand.xiaomi,
    _ => await OemBattery.detect(),
  };
  await OemBattery.protect(brand);
}

const kOemSamsung = 'samsung';
const kOemXiaomi = 'xiaomi';
const kOemRealmePixel = 'realme_pixel';
