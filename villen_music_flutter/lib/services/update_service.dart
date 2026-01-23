import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String? latestVersion;
  final String? releaseUrl;

  UpdateInfo({
    required this.hasUpdate,
    this.latestVersion,
    this.releaseUrl,
  });
}

class UpdateService {
  final Dio _dio = Dio();
  static const String _repoOwner = 'rahulkumar-andc';
  static const String _repoName = 'villen-music';
  
  /// Checks if a newer version is available on GitHub
  Future<UpdateInfo> checkForUpdate() async {
    try {
      // 1. Get current installed version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      debugPrint("Current Version: $currentVersion");

      // 2. Fetch latest release from GitHub
      final response = await _dio.get(
        'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        String tagName = data['tag_name'] ?? '';
        final htmlUrl = data['html_url'];
        
        // Remove 'v' prefix if present (e.g., v1.2.0 -> 1.2.0)
        final latestVersion = tagName.startsWith('v') 
            ? tagName.substring(1) 
            : tagName;

        debugPrint("Latest Version: $latestVersion");

        // 3. Compare versions
        if (_isNewerVersion(latestVersion, currentVersion)) {
          return UpdateInfo(
            hasUpdate: true,
            latestVersion: tagName,
            releaseUrl: htmlUrl,
          );
        }
      }
    } catch (e) {
      debugPrint("Error checking for updates: $e");
    }

    return UpdateInfo(hasUpdate: false);
  }

  /// Returns true if [remote] is newer than [local]
  bool _isNewerVersion(String remote, String local) {
    try {
      List<int> remoteParts = remote.split('.').map((e) => int.parse(e)).toList();
      List<int> localParts = local.split('.').map((e) => int.parse(e)).toList();

      for (int i = 0; i < remoteParts.length; i++) {
        // If local doesn't have this part (e.g. 1.0 vs 1.0.1), remote is newer
        if (i >= localParts.length) return true;

        if (remoteParts[i] > localParts[i]) return true;
        if (remoteParts[i] < localParts[i]) return false;
      }
    } catch (e) {
      debugPrint("Error comparing versions: $e");
    }
    return false;
  }

  /// Launches the update URL
  Future<void> launchUpdateUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
