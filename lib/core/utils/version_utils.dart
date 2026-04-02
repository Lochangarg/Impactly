class VersionUtils {
  /// Returns true if [latestVersion] is strictly greater than [currentVersion]
  /// using semantic versioning. 
  /// Supports formats like "1.0.0", "1.0.10", "1.1.0+5"
  static bool isUpdateAvailable(String currentVersion, String latestVersion) {
    try {
      // Handle build numbers if present (e.g., 1.0.0+1)
      final List<String> currentParts = _cleanVersion(currentVersion).split('.');
      final List<String> latestParts = _cleanVersion(latestVersion).split('.');

      final int maxLength = currentParts.length > latestParts.length 
          ? currentParts.length 
          : latestParts.length;

      for (int i = 0; i < maxLength; i++) {
        final int currentComponent = i < currentParts.length ? int.parse(currentParts[i]) : 0;
        final int latestComponent = i < latestParts.length ? int.parse(latestParts[i]) : 0;

        if (latestComponent > currentComponent) return true;
        if (latestComponent < currentComponent) return false;
      }
    } catch (e) {
      // In case of parsing error, assume no update to be safe
      return false;
    }
    return false;
  }

  static String _cleanVersion(String version) {
    // Remove "+n" build numbers for basic semver comparison if only latest_version is "1.0.2"
    if (version.contains('+')) {
      return version.split('+').first;
    }
    return version;
  }
}
