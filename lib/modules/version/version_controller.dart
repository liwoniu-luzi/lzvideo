import 'package:pure_live/common/index.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ReleaseAssetUrls {
  const ReleaseAssetUrls({required this.projectUrl, required this.version, required this.buildNumber});

  final String projectUrl;
  final String version;
  final int buildNumber;

  String get releaseBase => 'https://gh.lz1861.ccwu.cc/$projectUrl/releases/download/v$version-android';
  String get windowsReleaseBase => 'https://gh.lz1861.ccwu.cc/$projectUrl/releases/download/v$version-windows';
  String get androidArm64 => '$releaseBase/lzvideo-$version-$buildNumber-android-arm64-v8a-release.apk';
  String get androidArmeabiV7a => '';
  String get androidX8664 => '';
  String get windowsSetup => '';
  String get windowsMsix => '';
  String get windowsPortable => '$windowsReleaseBase/lzvideo-$version-$buildNumber-windows-x64-portable.zip';
  String get macosUniversal => '';
}

class VersionController extends GetxController {
  final hasNewVersion = false.obs;

  // =========================
  // Android
  // =========================

  final androidArmeabiV7aUrl = ''.obs;
  final androidArm64Url = ''.obs;
  final androidX8664Url = ''.obs;

  // =========================
  // Windows
  // =========================
  final windowsSetupUrl = ''.obs;
  final windowsMsixUrl = ''.obs;
  final windowsPortableUrl = ''.obs;

  // =========================
  // macOS
  // =========================
  final macosUrl = ''.obs;

  late PackageInfo packageInfo;

  final loading = true.obs;

  @override
  void onInit() {
    super.onInit();
    checkNewVersion();
  }

  Future<void> getPackageInfo() async {
    packageInfo = await PackageInfo.fromPlatform();
  }

  Future<void> checkNewVersion() async {
    await VersionUtil().checkUpdate();

    await getPackageInfo();

    hasNewVersion.value = VersionUtil.hasNewVersion();

    final latestVersion = VersionUtil.latestVersion;

    final localBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
    final int buildNumber;
    if (hasNewVersion.value) {
      buildNumber = VersionUtil.latestBuildNumber ?? (localBuild + 1);
    } else {
      buildNumber = VersionUtil.latestBuildNumber ?? localBuild;
    }
    final assets = ReleaseAssetUrls(
      projectUrl: VersionUtil.projectUrl,
      version: latestVersion,
      buildNumber: buildNumber,
    );

    // =====================================================
    // Android
    // =====================================================

    androidArmeabiV7aUrl.value = '';
    androidArm64Url.value = assets.androidArm64;
    androidX8664Url.value = '';

    // =====================================================
    // Windows
    // =====================================================

    windowsSetupUrl.value = '';
    windowsMsixUrl.value = '';
    windowsPortableUrl.value = assets.windowsPortable;

    // =====================================================
    // macOS
    // =====================================================

    macosUrl.value = '';

    loading.value = false;
  }
}
