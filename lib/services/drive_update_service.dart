import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update_me/in_app_update_me.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Version info model for Google Drive
class VersionInfo {
  final String version;
  final String apkUrl;
  final String? releaseNotes;
  final bool forceUpdate;

  VersionInfo({
    required this.version,
    required this.apkUrl,
    this.releaseNotes,
    this.forceUpdate = false,
  });

  factory VersionInfo.fromJson(Map<String, dynamic> json) {
    return VersionInfo(
      version: json['version'] ?? '',
      apkUrl: json['apk_url'] ?? '',
      releaseNotes: json['release_notes'],
      forceUpdate: json['force_update'] ?? false,
    );
  }
}

/// Service to check and perform updates from Google Drive
class DriveUpdateService {
  // Drive folder: https://drive.google.com/drive/folders/1zx1CRD8yqi6lzD46ZzcIYuelTqpJ2aWB
  // We need the raw download link for the version.json inside this folder.
  // Make sure version.json is shared as "Anyone with the link can view".
  // Note: For Google Drive, you usually need a direct download link.
  // Format for direct link: https://drive.google.com/uc?export=download&id=FILE_ID
  static const String versionJsonUrl = 'https://drive.google.com/uc?export=download&id=1zx1CRD8yqi6lzD46ZzcIYuelTqpJ2aWB_version_json_file_id'; // TODO: Replace with actual file ID of version.json

  static final DriveUpdateService _instance = DriveUpdateService._internal();
  factory DriveUpdateService() => _instance;
  DriveUpdateService._internal();

  /// Check for update and prompt user
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      logDebug('🔍 Checking for updates from Google Drive...');
      
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      logDebug('📱 Current version: $currentVersion');
      
      final versionInfo = await _fetchVersionInfo();
      if (versionInfo == null) {
        logDebug('❌ Could not fetch version info from Drive');
        return;
      }
      
      logDebug('🌐 Latest version: ${versionInfo.version}');
      logDebug('📦 APK URL: ${versionInfo.apkUrl}');
      
      if (_isUpdateAvailable(currentVersion, versionInfo.version)) {
        logDebug('✅ Update available!');
        
        if (context.mounted) {
          await _showUpdateDialog(context, versionInfo, currentVersion);
        }
      } else {
        logDebug('👍 App is up to date');
      }
    } catch (e, stackTrace) {
      logDebug('❌ Error checking for updates: $e');
      logDebug(stackTrace.toString());
    }
  }

  /// Fetch version info from Google Drive
  static Future<VersionInfo?> _fetchVersionInfo() async {
    try {
      final response = await http.get(
        Uri.parse(versionJsonUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return VersionInfo.fromJson(json);
      } else {
        logDebug('⚠️ HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      logDebug('❌ Error fetching version.json: $e');
      return null;
    }
  }

  /// Compare versions (simple string comparison)
  static bool _isUpdateAvailable(String current, String latest) {
    try {
      // Remove 'v' prefix if present
      final currentClean = current.replaceAll('v', '');
      final latestClean = latest.replaceAll('v', '');

      final currentParts = currentClean.split('.').map(int.parse).toList();
      final latestParts = latestClean.split('.').map(int.parse).toList();
      
      for (int i = 0; i < latestParts.length; i++) {
        final currentPart = i < currentParts.length ? currentParts[i] : 0;
        final latestPart = latestParts[i];
        
        if (latestPart > currentPart) return true;
        if (latestPart < currentPart) return false;
      }
      return false;
    } catch (e) {
      logDebug('❌ Error comparing versions: $e');
      return false;
    }
  }

  /// Show update dialog
  static Future<void> _showUpdateDialog(
    BuildContext context,
    VersionInfo versionInfo,
    String currentVersion,
  ) async {
    final bool isForced = versionInfo.forceUpdate;
    
    await showDialog(
      context: context,
      barrierDismissible: !isForced,
      builder: (context) => WillPopScope(
        onWillPop: () async => !isForced,
        child: AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.system_update, color: Colors.blue),
              SizedBox(width: 8),
              Text('Cập nhật mới'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Phiên bản hiện tại: $currentVersion'),
              Text('Phiên bản mới: ${versionInfo.version}'),
              if (versionInfo.releaseNotes != null && versionInfo.releaseNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Ghi chú:'),
                Text(versionInfo.releaseNotes!, style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
          actions: [
            if (!isForced)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Để sau'),
              ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _performUpdate(context, versionInfo.apkUrl);
              },
              child: const Text('Cập nhật ngay'),
            ),
          ],
        ),
      ),
    );
  }

  /// Perform the actual update using direct Drive URL
  static Future<void> _performUpdate(BuildContext context, String apkUrl) async {
    try {
      logDebug('🚀 Starting download from Google Drive...');
      
      if (Platform.isAndroid) {
        // Show loading or toast here if needed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đang tải bản cập nhật...')),
        );

        final result = await InAppUpdateMe.downloadAndInstallUpdate(apkUrl);
        
        if (result) {
            logDebug('✅ Install prompt triggered');
        } else {
            logDebug('❌ Failed to trigger install');
        }
      }
    } catch (e) {
      logDebug('❌ Update error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
      }
    }
  }

  /// Debug logging
  static void logDebug(String message) {
    debugPrint('[DriveUpdateService] $message');
  }
}
