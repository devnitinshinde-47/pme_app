class SystemConfigModel {
  final bool popupAdEnabled;
  final String? popupAdImageUrl;
  final String? popupAdTitle;
  final String? popupAdActionUrl;
  final String? popupAdButtonText;

  final bool appUpdateEnabled;
  final String latestVersion;
  final String minSupportedVersion;
  final bool forceUpdate;
  final String? updateTitle;
  final String? updateMessage;
  final String? updateSteps;
  final String? updateUrl;

  final bool maintenanceEnabled;
  final String? maintenanceTitle;
  final String? maintenanceMessage;
  final String? estimatedCompletionTime;

  SystemConfigModel({
    required this.popupAdEnabled,
    this.popupAdImageUrl,
    this.popupAdTitle,
    this.popupAdActionUrl,
    this.popupAdButtonText,
    required this.appUpdateEnabled,
    required this.latestVersion,
    required this.minSupportedVersion,
    required this.forceUpdate,
    this.updateTitle,
    this.updateMessage,
    this.updateSteps,
    this.updateUrl,
    required this.maintenanceEnabled,
    this.maintenanceTitle,
    this.maintenanceMessage,
    this.estimatedCompletionTime,
  });

  factory SystemConfigModel.fromJson(Map<String, dynamic> json) {
    return SystemConfigModel(
      popupAdEnabled: json['popupAdEnabled'] ?? false,
      popupAdImageUrl: json['popupAdImageUrl'],
      popupAdTitle: json['popupAdTitle'],
      popupAdActionUrl: json['popupAdActionUrl'],
      popupAdButtonText: json['popupAdButtonText'] ?? 'Claim Offer',
      appUpdateEnabled: json['appUpdateEnabled'] ?? false,
      latestVersion: json['latestVersion'] ?? '1.0.0',
      minSupportedVersion: json['minSupportedVersion'] ?? '1.0.0',
      forceUpdate: json['forceUpdate'] ?? false,
      updateTitle: json['updateTitle'] ?? 'New Version Available!',
      updateMessage: json['updateMessage'],
      updateSteps: json['updateSteps'],
      updateUrl: json['updateUrl'],
      maintenanceEnabled: json['maintenanceEnabled'] ?? false,
      maintenanceTitle: json['maintenanceTitle'] ?? 'System Under Maintenance',
      maintenanceMessage: json['maintenanceMessage'],
      estimatedCompletionTime: json['estimatedCompletionTime'],
    );
  }
}
