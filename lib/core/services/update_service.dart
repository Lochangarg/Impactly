import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/update_model.dart';
import '../utils/version_utils.dart';

class UpdateService {
  final String updateConfigUrl;
  UpdateService({required this.updateConfigUrl});

  Future<UpdateModel?> checkForUpdate() async {
    try {
      // 1. Check debounce: Only check once per app session (or day)
      // to avoid repeated requests and dialogs.
      if (!await _shouldCheckUpdate()) return null;

      // 2. Fetch remote JSON
      final response = await http.get(Uri.parse(updateConfigUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final Map<String, dynamic> data = json.decode(response.body);
      final updateData = UpdateModel.fromJson(data);

      // 3. Get local version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 4. Compare versions
      if (VersionUtils.isUpdateAvailable(currentVersion, updateData.latestVersion)) {
        return updateData;
      }
    } catch (e) {
      // Fail silently for network or parsing errors
      return null;
    }
    return null;
  }

  Future<bool> _shouldCheckUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final lastChecked = prefs.getInt('last_update_check_ts') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // Check once every 12 hours (43,200,000 ms)
    if (now - lastChecked < 43200000) {
      return false;
    }

    prefs.setInt('last_update_check_ts', now);
    return true;
  }
}
