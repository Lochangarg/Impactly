class UpdateModel {
  final String latestVersion;
  final String updateUrl;
  final bool forceUpdate;
  final String message;

  UpdateModel({
    required this.latestVersion,
    required this.updateUrl,
    required this.forceUpdate,
    required this.message,
  });

  factory UpdateModel.fromJson(Map<String, dynamic> json) {
    return UpdateModel(
      latestVersion: json['latest_version'] ?? '1.0.0',
      updateUrl: json['update_url'] ?? '',
      forceUpdate: json['force_update'] ?? false,
      message: json['message'] ?? 'A new version is available.',
    );
  }
}
