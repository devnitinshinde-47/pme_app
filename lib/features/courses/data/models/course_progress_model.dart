class CourseProgressModel {
  final String courseId;
  final int totalVideos;
  final int completedVideos;
  final double progressPercentage;
  final Set<String> completedVideoIds;

  const CourseProgressModel({
    required this.courseId,
    required this.totalVideos,
    required this.completedVideos,
    required this.progressPercentage,
    required this.completedVideoIds,
  });

  CourseProgressModel copyWith({
    String? courseId,
    int? totalVideos,
    int? completedVideos,
    double? progressPercentage,
    Set<String>? completedVideoIds,
  }) {
    return CourseProgressModel(
      courseId: courseId ?? this.courseId,
      totalVideos: totalVideos ?? this.totalVideos,
      completedVideos: completedVideos ?? this.completedVideos,
      progressPercentage: progressPercentage ?? this.progressPercentage,
      completedVideoIds: completedVideoIds ?? this.completedVideoIds,
    );
  }

  factory CourseProgressModel.fromJson(Map<String, dynamic> json) {
    final rawList = json['completedVideoIds'];
    final Set<String> completedList = rawList is Iterable
        ? rawList.map((e) => e.toString()).toSet()
        : <String>{};

    final int rawCompleted = json['completedVideos'] is int ? (json['completedVideos'] as int) : completedList.length;
    final int completedCount = rawCompleted >= completedList.length ? rawCompleted : completedList.length;

    final int rawTotal = json['totalVideos'] is int ? (json['totalVideos'] as int) : 0;
    final int totalCount = rawTotal > completedCount
        ? rawTotal
        : (completedCount > 0 ? completedCount : (rawTotal > 0 ? rawTotal : 4));

    final double rawPct = (json['progressPercentage'] is num) ? (json['progressPercentage'] as num).toDouble() : 0.0;
    final double pct = rawPct > 0
        ? rawPct
        : (totalCount > 0 ? double.parse(((completedCount / totalCount) * 100.0).toStringAsFixed(1)) : 0.0);

    return CourseProgressModel(
      courseId: json['courseId']?.toString() ?? '',
      totalVideos: totalCount,
      completedVideos: completedCount,
      progressPercentage: pct,
      completedVideoIds: completedList,
    );
  }
}
