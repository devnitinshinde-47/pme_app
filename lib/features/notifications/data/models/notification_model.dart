/// Notification model returned from Spring Boot `/api/notifications`
class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // ANNOUNCEMENT, LIVE_CLASS, DPP, RESULT, GENERAL
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Notification',
      body: json['body']?.toString() ?? '',
      type: json['type']?.toString().toUpperCase() ?? 'GENERAL',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
