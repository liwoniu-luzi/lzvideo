import 'dart:io';
import 'dart:developer' as developer;
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:pure_live/common/index.dart';

class WindowsSelfUpdater {
  /// 执行 Windows 便携版原地无缝更新与自动重启
  static Future<bool> applyUpdateAndRestart(File zipFile) async {
    if (!Platform.isWindows) return false;

    try {
      final currentExePath = Platform.resolvedExecutable;
      final targetAppDir = File(currentExePath).parent.path;
      final targetExeName = p.basename(currentExePath);

      final tempDir = Directory(p.join(Directory.systemTemp.path, 'lzvideo_update'));
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
      tempDir.createSync(recursive: true);

      final extractDir = Directory(p.join(tempDir.path, 'extracted'));
      extractDir.createSync(recursive: true);

      // 解压 ZIP 文件
      developer.log('Extracting update zip to ${extractDir.path}...', name: 'WindowsSelfUpdater');
      final bytes = zipFile.readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      extractArchiveToDisk(archive, extractDir.path);

      // 寻找包含 exe 的实际根目录
      String sourceDir = extractDir.path;
      final subDirs = extractDir.listSync().whereType<Directory>().toList();
      for (final d in subDirs) {
        final exes = d.listSync().whereType<File>().where((f) => f.path.toLowerCase().endsWith('.exe'));
        if (exes.isNotEmpty) {
          sourceDir = d.path;
          break;
        }
      }

      // 生成原地覆盖更新与自动重启脚本
      final batFile = File(p.join(tempDir.path, 'apply_update.bat'));
      final batContent = '''@echo off
setlocal
echo Updating lzvideo...
timeout /t 2 /nobreak >nul
robocopy "%~1" "%~2" /E /IS /IT /XD "AppData" "IPTV_CACHE" /R:5 /W:1 >nul
if errorlevel 8 (
    xcopy /s /e /y /q "%~1\\*" "%~2" >nul
)
if exist "%~2\\lzvideo.exe" (
    start "" "%~2\\lzvideo.exe"
) else if exist "%~2\\pure_live.exe" (
    start "" "%~2\\pure_live.exe"
) else (
    start "" "%~2\\%~3"
)
exit
''';

      batFile.writeAsStringSync(batContent);

      developer.log('Launching updater batch script...', name: 'WindowsSelfUpdater');
      await Process.start(
        'cmd.exe',
        ['/c', batFile.path, sourceDir, targetAppDir, targetExeName],
        mode: ProcessStartMode.detached,
      );

      // 退出当前主程序，释放文件锁
      await Future.delayed(const Duration(milliseconds: 200));
      exit(0);
    } catch (e, stack) {
      developer.log('Windows self-update failed: $e', name: 'WindowsSelfUpdater', stackTrace: stack);
      return false;
    }
  }
}
