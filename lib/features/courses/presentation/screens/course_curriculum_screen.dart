import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/blinking_live_badge.dart';
import '../../data/models/course_model.dart';
import '../../data/repositories/course_repository.dart';
import 'bunny_video_player_screen.dart';

/// Interactive Course Curriculum & Study Content Viewer Screen displaying
/// lesson modules, attached video lectures, chapter PDF notes, and global study materials.
class CourseCurriculumScreen extends StatefulWidget {
  final CourseModel course;
  final CourseRepository? repository;

  const CourseCurriculumScreen({
    super.key,
    required this.course,
    this.repository,
  });

  @override
  State<CourseCurriculumScreen> createState() => _CourseCurriculumScreenState();
}

class _CourseCurriculumScreenState extends State<CourseCurriculumScreen> with SingleTickerProviderStateMixin {
  late final CourseRepository _repository;
  late final TabController _tabController;

  List<LessonModel> _lessons = [];
  List<NoteModel> _fetchedCourseNotes = [];
  bool _lessonsLoading = true;
  String? _lessonsError;
  Set<String> _completedVideoIds = {};

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? CourseRepository();
    _tabController = TabController(length: 2, vsync: this);
    _loadLessonsAndProgress();
  }

  /// Fetch lessons, progress, and course-level notes concurrently
  Future<void> _loadLessonsAndProgress() async {
    if (!mounted) return;
    setState(() {
      _lessonsLoading = true;
      _lessonsError = null;
    });
    try {
      final lessonsFuture = _repository.getCourseLessons(widget.course.id);
      final progressFuture = _repository.getCourseProgress(widget.course.id);
      final notesFuture = _repository.getCourseNotes(widget.course.id);

      final lessons = await lessonsFuture;
      final progress = await progressFuture;
      final courseNotes = await notesFuture;

      if (!mounted) return;
      setState(() {
        _completedVideoIds = progress?.completedVideoIds ?? {};
        _lessons = lessons;
        _fetchedCourseNotes = courseNotes;
        _lessonsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lessonsError = e.toString();
        _lessonsLoading = false;
      });
    }
  }

  /// Extracts and merges all course-level, lesson-wise, and video-wise notes into one consolidated list
  List<NoteModel> _getAllCombinedNotes() {
    final Map<String, NoteModel> combinedMap = {};

    // 1. Add notes returned directly from getCourseNotes API endpoint
    for (final note in _fetchedCourseNotes) {
      combinedMap[note.id] = note;
    }

    // 2. Add notes attached to lessons & video lectures inside lessons
    for (final lesson in _lessons) {
      for (final note in lesson.notes) {
        final existing = combinedMap[note.id] ?? note;
        combinedMap[note.id] = NoteModel(
          id: existing.id,
          lessonId: existing.lessonId ?? lesson.id,
          lessonTitle: existing.lessonTitle ?? lesson.title,
          videoId: existing.videoId,
          title: existing.title,
          scope: existing.scope ?? 'LESSON',
          pdfUrl: existing.pdfUrl,
          fileSize: existing.fileSize,
          fileType: existing.fileType,
          isGlobal: existing.isGlobal,
        );
      }

      for (final lecture in lesson.lectures) {
        if (lecture.note != null) {
          final note = lecture.note!;
          final existing = combinedMap[note.id] ?? note;
          combinedMap[note.id] = NoteModel(
            id: existing.id,
            lessonId: existing.lessonId ?? lesson.id,
            lessonTitle: existing.lessonTitle ?? '${lesson.title} • ${lecture.title}',
            videoId: existing.videoId ?? lecture.id,
            title: existing.title,
            scope: existing.scope ?? 'VIDEO',
            pdfUrl: existing.pdfUrl,
            fileSize: existing.fileSize,
            fileType: existing.fileType,
            isGlobal: existing.isGlobal,
          );
        }
      }
    }

    return combinedMap.values.toList();
  }

  /// Called after returning from the video player — refresh progress & lesson state
  Future<void> _refreshProgressOnly() async {
    final progress = await _repository.getCourseProgress(widget.course.id);
    if (progress != null && mounted) {
      setState(() {
        _completedVideoIds = progress.completedVideoIds;
      });
    }
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onPlayLecture(LectureModel lecture) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BunnyVideoPlayerScreen(
          lecture: lecture,
          courseName: widget.course.name,
          courseId: widget.course.id,
          repository: _repository,
        ),
      ),
    );
    // When returning, refresh progress state
    _refreshProgressOnly();
  }

  void _onOpenPdfNote(NoteModel note) {
    if (note.pdfUrl == null || note.pdfUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF document URL not available.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      AppRoutes.pdfReader,
      arguments: {
        'title': note.title,
        'pdfUrl': note.pdfUrl,
        'url': note.pdfUrl,
        'fileSize': note.fileSize,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.course.name),
        elevation: 0,
        backgroundColor: AppColors.surface,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Modules & Lectures'),
            Tab(text: 'Study Notes & PYQs'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_lessonsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_lessonsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                _lessonsError!,
                style: const TextStyle(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadLessonsAndProgress,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        // Tab 1: Modules & Lectures Accordion
        _buildCurriculumTab(_lessons),

        // Tab 2: Course-level & Lesson-wise notes
        _buildNotesTab(_getAllCombinedNotes()),
      ],
    );
  }

  Widget _buildCurriculumTab(List<LessonModel> lessons) {
    if (lessons.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.menu_book_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Modules Available Yet',
                style: AppStyles.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'The instructor has not uploaded curriculum modules or video lectures for this course yet.',
                style: AppStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadLessonsAndProgress,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                label: const Text('Refresh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];

        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          elevation: 0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
              boxShadow: AppStyles.softShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: false,
                  tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${lesson.lessonIndex}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                      ),
                    ),
                  ),
                  title: Text(
                    lesson.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    '${lesson.lectures.length} Video Sessions',
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                  children: [
                    const Divider(height: 1, color: AppColors.cardBorder),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (lesson.description != null && lesson.description!.isNotEmpty) ...[
                            Text(
                              lesson.description!,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Video Lectures List
                          if (lesson.lectures.isNotEmpty) ...[
                            const Text('VIDEO LECTURES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                            const SizedBox(height: 8),
                            Column(
                              children: lesson.lectures.map((lec) => _buildLectureItem(lec)).toList(),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Chapter PDF Notes (only lesson-specific notes, not COURSE-scope, not video-specific)
                          () {
                            final lessonOnlyNotes = lesson.notes.where((n) =>
                              (n.videoId == null || n.videoId!.isEmpty) &&
                              n.scope?.toUpperCase() != 'COURSE' &&
                              !n.isGlobal
                            ).toList();
                            if (lessonOnlyNotes.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('CHAPTER STUDY NOTES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                                const SizedBox(height: 8),
                                ...lessonOnlyNotes.map((note) => _buildNoteItem(note, chapterContext: lesson.title)),
                              ],
                            );
                          }(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLectureItem(LectureModel lecture) {
    final isCompleted = _completedVideoIds.contains(lecture.id) || lecture.isCompleted;
    final thumbnailUrl = lecture.thumbnailUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted ? AppColors.success.withValues(alpha: 0.4) : AppColors.cardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _onPlayLecture(lecture),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Video Thumbnail Container with Play Icon & Checkmark Badge
                Stack(
                  children: [
                    Container(
                      width: 84,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                        image: (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(thumbnailUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (thumbnailUrl == null || thumbnailUrl.isEmpty)
                          ? Container(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              child: const Center(
                                child: Icon(Icons.play_circle_fill_rounded, color: AppColors.primary, size: 26),
                              ),
                            )
                          : Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.black26,
                              ),
                              child: const Center(
                                child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 24),
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                // Title and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (lecture.isLive) ...[
                            const BlinkingLiveBadge(fontSize: 8, padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              lecture.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            lecture.duration ?? "45 mins",
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                          ),
                          if (isCompleted) ...[
                            const SizedBox(width: 8),
                            const Text('•', style: TextStyle(fontSize: 11, color: AppColors.success)),
                            const SizedBox(width: 4),
                            const Text(
                              'Completed',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoteItem(NoteModel note, {String? chapterContext}) {
    final contextText = note.lessonTitle ?? chapterContext;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _onOpenPdfNote(note),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.25),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            note.fileSize ?? "2.4 MB",
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                          ),
                          if (contextText != null && contextText.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            const Text('•', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                contextText,
                                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesTab(List<NoteModel> notes) {
    if (notes.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.picture_as_pdf_rounded, size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Study Notes Available Yet',
                style: AppStyles.headingMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'No chapter notes, PDF summaries, or PYQs have been uploaded for this course yet.',
                style: AppStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final courseNotes = notes.where((n) => n.scope?.toUpperCase() == 'COURSE' || n.isGlobal).toList();
    final lessonNotes = notes.where((n) => n.scope?.toUpperCase() != 'COURSE' && !n.isGlobal).toList();

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (courseNotes.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'COURSE LEVEL NOTES & PYQs (${courseNotes.length})',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...courseNotes.map((note) => _buildNoteItem(note)),
          const SizedBox(height: 18),
        ],

        if (lessonNotes.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(
                'LESSON-WISE STUDY NOTES (${lessonNotes.length})',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...lessonNotes.map((note) => _buildNoteItem(note)),
        ],
      ],
    );
  }
}
