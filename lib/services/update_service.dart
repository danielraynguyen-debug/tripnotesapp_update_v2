import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update_me/in_app_update_me.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// GitHub Release Asset model
class GithubReleaseAsset {
  final String name;
  final String downloadUrl;
  final int size;

  GithubReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });

  factory GithubReleaseAsset.fromJson(Map<String, dynamic> json) {
    return GithubReleaseAsset(
      name: json['name'] ?? '',
      downloadUrl: json['browser_download_url'] ?? '',
      size: json['size'] ?? 0,
    );
  }
}

/// GitHub Release model
class GithubRelease {
  final String tagName;
  final String name;
  final String body;
  final bool prerelease;
  final bool draft;
  final DateTime publishedAt;
  final List<GithubReleaseAsset> assets;

  GithubRelease({
    required this.tagName,
    required this.name,
    required this.body,
    required this.prerelease,
    required this.draft,
    required this.publishedAt,
    required this.assets,
  });

  factory GithubRelease.fromJson(Map<String, dynamic> json) {
    final assetsList = (json['assets'] as List<dynamic>?)
            ?.map((asset) => GithubReleaseAsset.fromJson(asset))
            .toList() ??
        [];

    return GithubRelease(
      tagName: json['tag_name'] ?? '',
      name: json['name'] ?? '',
      body: json['body'] ?? '',
      prerelease: json['prerelease'] ?? false,
      draft: json['draft'] ?? false,
      publishedAt: DateTime.tryParse(json['published_at'] ?? '') ?? DateTime.now(),
      assets: assetsList,
    );
  }

  /// Get APK asset from release
  GithubReleaseAsset? get apkAsset {
    return assets.firstWhere(
      (asset) => asset.name.toLowerCase().endsWith('.apk'),
      orElse: () => null as GithubReleaseAsset,
    );
  }

  /// Check if this is a valid release (not draft, not prerelease)
  bool get isValidRelease => !draft && !prerelease;
}

/// Version comparison result
enum VersionComparison { newer, same, older }

/// Service for checking and handling GitHub updates
class GithubUpdateService {
  static const String _owner = 'YOUR_GITHUB_USERNAME'; // TODO: Replace with your GitHub username
  static const String _repo = 'tripnotesapp'; // TODO: Replace with your repo name

  /// Check for updates and install if available
  static Future<void> checkAndDoUpdate({
    bool allowPrerelease = false,
    bool allowDraft = false,
    void Function(String message)? onLog,
    void Function(String error)? onError,
  }) async {
    try {
      _log('Starting update check...', onLog);

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      _log('Current app version: $currentVersion', onLog);

      // Fetch latest release from GitHub
      final release = await _fetchLatestRelease(
        allowPrerelease: allowPrerelease,
        allowDraft: allowDraft,
      );

      if (release == null) {
        _log('No valid release found', onLog);
        return;
      }

      _log('Latest GitHub release: ${release.tagName}', onLog);

      // Compare versions
      final comparison = _compareVersions(release.tagName, currentVersion);

      switch (comparison) {
        case VersionComparison.newer:
          _log('New version available: ${release.tagName}', onLog);

          // Find APK asset
          final apkAsset = release.apkAsset;
          if (apkAsset == null) {
            _error('No APK asset found in release', onError);
            return;
          }

          _log('Found APK: ${apkAsset.name} (${_formatBytes(apkAsset.size)})', onLog);
          _log('Download URL: ${apkAsset.downloadUrl}', onLog);

          // Perform update
          await _performUpdate(apkAsset.downloadUrl, onLog: onLog, onError: onError);
          break;

        case VersionComparison.same:
          _log('App is up to date (version $currentVersion)', onLog);
          break;

        case VersionComparison.older:
          _log('Local version is newer than GitHub release', onLog);
          break;
      }
    } on SocketException catch (e) {
      _error('Network error: ${e.message}', onError);
    } on FormatException catch (e) {
      _error('Invalid data format: ${e.message}', onError);
    } catch (e, stackTrace) {
      _error('Unexpected error: $e\n$stackTrace', onError);
    }
  }

  /// Fetch latest release from GitHub API
  static Future<GithubRelease?> _fetchLatestRelease({
    bool allowPrerelease = false,
    bool allowDraft = false,
  }) async {
    final url = Uri.parse(
      'https://api.github.com/repos/$_owner/$_repo/releases/latest',
    );

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'TripNotes-App-Updater',
      },
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 404) {
      throw Exception('Repository or release not found. Check owner/repo settings.');
    }

    if (response.statusCode == 403) {
      throw Exception('API rate limit exceeded. Try again later.');
    }

    if (response.statusCode != 200) {
      throw Exception('GitHub API error: ${response.statusCode} - ${response.body}');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    final release = GithubRelease.fromJson(data);

    // Validate release
    if (!allowDraft && release.draft) {
      return null;
    }
    if (!allowPrerelease && release.prerelease) {
      return null;
    }

    return release;
  }

  /// Compare two version strings
  /// Returns: newer if remote > local, same if equal, older if remote < local
  static VersionComparison _compareVersions(String remoteVersion, String localVersion) {
    // Remove 'v' prefix if present
    final remote = remoteVersion.toLowerCase().replaceFirst('v', '');
    final local = localVersion.toLowerCase().replaceFirst('v', '');

    // Parse version numbers
    final remoteParts = remote.split('.').map(int.tryParse).where((v) => v != null).cast<int>().toList();
    final localParts = local.split('.').map(int.tryParse).where((v) => v != null).cast<int>().toList();

    // Compare each part
    final maxLength = remoteParts.length > localParts.length ? remoteParts.length : localParts.length;

    for (int i = 0; i < maxLength; i++) {
      final remotePart = i < remoteParts.length ? remoteParts[i] : 0;
      final localPart = i < localParts.length ? localParts[i] : 0;

      if (remotePart > localPart) return VersionComparison.newer;
      if (remotePart < localPart) return VersionComparison.older;
    }

    return VersionComparison.same;
  }

  /// Perform the actual update download and install
  static Future<void> _performUpdate(
    String apkUrl, {
    void Function(String message)? onLog,
    void Function(String error)? onError,
  }) async {
    try {
      _log('Starting download and install...', onLog);

      // Check if platform is supported
      if (!Platform.isAndroid) {
        _error('In-app update is only supported on Android', onError);
        return;
      }

      // Use in_app_update_me to download and install
      final result = await InAppUpdateMe.downloadAndInstallUpdate(apkUrl);

      if (result) {
        _log('Update installed successfully!', onLog);
      } else {
        _error('Update installation failed', onError);
      }
    } catch (e) {
      _error('Error during update: $e', onError);
    }
  }

  /// Log message
  static void _log(String message, void Function(String message)? onLog) {
    final logMessage = '[GithubUpdateService] $message';
    debugPrint(logMessage);
    onLog?.call(logMessage);
  }

  /// Log error
  static void _error(String message, void Function(String error)? onError) {
    final errorMessage = '[GithubUpdateService] ERROR: $message';
    debugPrint(errorMessage);
    onError?.call(errorMessage);
  }

  /// Format bytes to human readable string
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Set custom GitHub credentials (if repo is private)
  static void setCredentials({
    required String owner,
    required String repo,
  }) {
    // Note: In production, you might want to store these securely
    // This is a simple implementation for public repos
    throw UnimplementedError('Use static const fields or environment config instead');
  }
}
