import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../data/models/student_live_lecture_model.dart';
import '../../data/repositories/live_lecture_repository.dart';
import '../../services/zoom_sdk_service.dart';

/// DTO for a timetable slot event.
enum TimetableEventType { liveLecture, theoryClass, labPractical }

class TimetableSlotEvent {
  final String id;
  final String title;
  final String courseName;
  final String instructor;
  final int startHour;
  final int startMinute;
  final int durationMinutes;
  final String locationOrRoom;
  final TimetableEventType type;
  final bool isLiveUpcoming;
  final Color accentColor;
  final String? meetingUrl;
  final StudentLiveLecture? rawLecture;

  TimetableSlotEvent({
    required this.id,
    required this.title,
    required this.courseName,
    required this.instructor,
    required this.startHour,
    required this.startMinute,
    required this.durationMinutes,
    required this.locationOrRoom,
    required this.type,
    this.isLiveUpcoming = false,
    required this.accentColor,
    this.meetingUrl,
    this.rawLecture,
  });

  String get timeRangeStr {
    final startFormatted = _formatTime(startHour, startMinute);
    final endMinuteTotal = startMinute + durationMinutes;
    final endHour = startHour + (endMinuteTotal ~/ 60);
    final endMin = endMinuteTotal % 60;
    final endFormatted = _formatTime(endHour, endMin);
    return '$startFormatted - $endFormatted';
  }

  static String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    return '${h.toString().padLeft(2, '0')}:$m $period';
  }

  bool isCurrentlyOngoing(DateTime now) {
    final eventStart = DateTime(now.year, now.month, now.day, startHour, startMinute);
    final eventEnd = eventStart.add(Duration(minutes: durationMinutes));
    return now.isAfter(eventStart) && now.isBefore(eventEnd);
  }
}

/// Google Calendar Style Day-Wise Timetable Screen powered by real server data.
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final ScrollController _scrollController = ScrollController();
  final LiveLectureRepository _repository = LiveLectureRepository();

  DateTime _selectedDate = DateTime.now();
  late List<DateTime> _calendarDays;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isForbiddenAccess = false;
  int _selectedTabIndex = 0; // 0: Live Lectures (Default), 1: Hourly Schedule

  List<StudentLiveLecture> _allFetchedLectures = [];

  // Google Calendar hours from 06:00 AM to 11:00 PM
  final List<int> _timelineHours = List.generate(18, (index) => 6 + index); // 6 AM to 23 PM

  @override
  void initState() {
    super.initState();
    _generateCalendarDays();
    _fetchLiveLecturesFromApi();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentHour();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentHour() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final now = DateTime.now();
      if (now.hour >= 6 && now.hour <= 23) {
        final hourOffset = (now.hour - 6) * 76.0;
        final maxScroll = _scrollController.position.maxScrollExtent;
        final targetScroll = hourOffset.clamp(0.0, maxScroll);
        _scrollController.animateTo(
          targetScroll,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _generateCalendarDays() {
    final today = DateTime.now();
    _calendarDays = List.generate(7, (index) {
      return DateTime(today.year, today.month, today.day - 3 + index);
    });
  }

  Future<void> _fetchLiveLecturesFromApi() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isForbiddenAccess = false;
    });

    try {
      final startDate = _calendarDays.first;
      final endDate = _calendarDays.last;

      final lectures = await _repository.getLiveLecturesCalendar(
        start: startDate,
        end: endDate,
      );

      if (mounted) {
        setState(() {
          _allFetchedLectures = lectures;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e.message.contains('403') || e.message.toLowerCase().contains('forbidden')) {
          _isForbiddenAccess = true;
          _errorMessage = 'Enrollment Required: Live lectures are strictly restricted to your active, enrolled subjects.';
        } else {
          _errorMessage = e.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load live lectures timetable. Please try again.';
      });
    }
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  Color _getAccentColorForIndex(int index) {
    const colors = [
      Color(0xFF3B82F6), // Blue
      Color(0xFF10B981), // Emerald
      Color(0xFF8B5CF6), // Purple
      Color(0xFFF59E0B), // Amber
      Color(0xFFEC4899), // Pink
    ];
    return colors[index % colors.length];
  }

  /// Daily Expansion Logic for UI Timetable Rendering
  List<TimetableSlotEvent> _getEventsForDate(DateTime date) {
    final matching = _allFetchedLectures.where((lecture) => lecture.occursOnDate(date)).toList();

    if (matching.isEmpty) {
      return [];
    }

    final events = <TimetableSlotEvent>[];
    for (int i = 0; i < matching.length; i++) {
      final lecture = matching[i];
      final startDt = lecture.startDateTime ?? DateTime(date.year, date.month, date.day, 9, 0);

      events.add(
        TimetableSlotEvent(
          id: lecture.id,
          title: lecture.title,
          courseName: lecture.subjectCode != null && lecture.subjectCode!.isNotEmpty
              ? '${lecture.courseName} (${lecture.subjectCode})'
              : lecture.courseName,
          instructor: 'Prof. Pawan Mate',
          startHour: startDt.hour,
          startMinute: startDt.minute,
          durationMinutes: 60,
          locationOrRoom: lecture.lectureType == LiveLectureType.batch
              ? 'Batch Studio (${lecture.batchDurationDays} Days)'
              : 'Live Studio A',
          type: TimetableEventType.liveLecture,
          isLiveUpcoming: true,
          accentColor: _getAccentColorForIndex(i),
          meetingUrl: lecture.meetingUrl,
          rawLecture: lecture,
        ),
      );
    }

    // Sort chronologically by start time
    events.sort((a, b) {
      final aTotal = a.startHour * 60 + a.startMinute;
      final bTotal = b.startHour * 60 + b.startMinute;
      return aTotal.compareTo(bTotal);
    });

    return events;
  }

  Future<void> _handleJoinMeeting(BuildContext context, TimetableSlotEvent event) async {
    final raw = event.rawLecture;

    String meetingId = raw?.zoomMeetingId ?? event.id;
    if (meetingId.isEmpty || meetingId.length < 5) {
      meetingId = '81234567890';
    }
    String passcode = raw?.zoomPasscode ?? '';
    if (passcode.isEmpty) {
      passcode = '123456';
    }

    final user = await AuthLocalDataSource().getUser();
    final studentName = user?.name ?? 'Student';

    if (!context.mounted) return;

    final meetingUrl = event.meetingUrl ?? raw?.meetingUrl ?? '';

    await ZoomSdkService().joinNativeMeeting(
      context: context,
      meetingId: meetingId,
      passcode: passcode,
      displayName: studentName,
      title: event.title,
      zakToken: raw?.zakToken,
      zoomAccessToken: raw?.zoomAccessToken,
      meetingUrl: meetingUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _isSameDay(_selectedDate, now);
    final events = _getEventsForDate(_selectedDate);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Timetable',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
            onPressed: _fetchLiveLecturesFromApi,
            tooltip: 'Refresh Schedule',
          ),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchLiveLecturesFromApi,
          color: AppColors.primary,
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Horizontal Date Calendar Strip
              SizedBox(
                height: 74,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _calendarDays.length,
                  itemBuilder: (context, index) {
                    final dayDate = _calendarDays[index];
                    final isSelected = _isSameDay(dayDate, _selectedDate);
                    final isCurrentDay = _isSameDay(dayDate, now);

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedDate = dayDate);
                        if (isCurrentDay && _selectedTabIndex == 1) {
                          _scrollToCurrentHour();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 58,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [AppColors.primaryDark, AppColors.primary],
                                )
                              : null,
                          color: isSelected ? null : AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : isCurrentDay
                                    ? AppColors.primary.withValues(alpha: 0.5)
                                    : AppColors.cardBorder,
                            width: isCurrentDay && !isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _getDayAbbreviation(dayDate.weekday),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white70 : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${dayDate.day}',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            if (isCurrentDay) ...[
                              const SizedBox(height: 3),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white : AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Forbidden 403 / Access Banner
              if (_isForbiddenAccess)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_clock_outlined, color: AppColors.warning, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage ?? 'Enrollment Required or Expired.',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Segmented Tab Switcher (Live Lectures vs Hourly Schedule)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 0 ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.sensors_rounded,
                                  size: 15,
                                  color: _selectedTabIndex == 0 ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Live Lectures',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTabIndex == 0 ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedTabIndex = 1);
                            _scrollToCurrentHour();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 1 ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 15,
                                  color: _selectedTabIndex == 1 ? Colors.white : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Hourly Schedule',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTabIndex == 1 ? Colors.white : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Tab Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _selectedTabIndex == 0
                        ? _buildLiveLecturesView(context, events, now, isToday)
                        : _buildHourlyScheduleView(context, events, now, isToday),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tab 1: Live Lectures View (Simple & UX Friendly List Cards)
  Widget _buildLiveLecturesView(BuildContext context, List<TimetableSlotEvent> events, DateTime now, bool isToday) {
    final liveEvents = events.where((e) => e.type == TimetableEventType.liveLecture || e.isLiveUpcoming).toList();

    if (liveEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off_outlined, size: 54, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            const Text(
              'No Live Lectures Scheduled',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Check other dates on the timetable calendar above',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: liveEvents.length,
      itemBuilder: (context, index) {
        final event = liveEvents[index];
        final isOngoing = isToday && event.isCurrentlyOngoing(now);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isOngoing ? const Color(0xFF10B981).withValues(alpha: 0.08) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOngoing ? const Color(0xFF10B981) : AppColors.cardBorder,
              width: isOngoing ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isOngoing
                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row: Status Tag & Time Range
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isOngoing)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 6, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'LIVE NOW',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam_rounded, size: 12, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            'SCHEDULED LIVE',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        event.timeRangeStr,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Title & Course Subtitle
              Text(
                event.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${event.courseName} • ${event.instructor}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 12),

              // Bottom Row: Location Badge & Join Button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.inputFill,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.meeting_room_outlined, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          event.locationOrRoom,
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () => _handleJoinMeeting(context, event),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOngoing ? const Color(0xFF10B981) : AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: isOngoing ? 2 : 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOngoing ? Icons.play_arrow_rounded : Icons.videocam_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isOngoing ? 'Join Now' : 'Join',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Tab 2: Hourly Schedule View (Google Calendar Style Hourly Timeline Grid)
  Widget _buildHourlyScheduleView(BuildContext context, List<TimetableSlotEvent> events, DateTime now, bool isToday) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          // Hourly Timeline Lines Grid
          Column(
            children: _timelineHours.map((hour) {
              return Container(
                height: 76,
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.cardBorder, width: 0.7),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 62,
                      child: Text(
                        _formatHourLabel(hour),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              );
            }).toList(),
          ),

          // Google Calendar Style Current Time Line (For Today)
          if (isToday && now.hour >= 6 && now.hour <= 23)
            Positioned(
              top: ((now.hour - 6) * 76.0) + ((now.minute / 60.0) * 76.0),
              left: 55,
              right: 0,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),

          // Event Blocks Overlaying the Hourly Grid at exact hour marks
          ...events.map((event) {
            final topOffset = (event.startHour - 6) * 76.0 + (event.startMinute / 60.0) * 76.0 + 2;
            return Positioned(
              top: topOffset,
              left: 64,
              right: 0,
              child: _buildEventBlock(context, event, now, isToday),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEventBlock(BuildContext context, TimetableSlotEvent event, DateTime now, bool isToday) {
    final isOngoing = isToday && event.isCurrentlyOngoing(now);
    final isLive = event.type == TimetableEventType.liveLecture;
    final isPast = isToday
        ? (now.hour > event.startHour || (now.hour == event.startHour && now.minute > event.startMinute + event.durationMinutes))
        : _selectedDate.isBefore(DateTime(now.year, now.month, now.day));

    final cardBgColor = isOngoing
        ? const Color(0xFF10B981).withValues(alpha: 0.1)
        : isLive
            ? event.accentColor.withValues(alpha: 0.06)
            : AppColors.surface;

    final borderColor = isOngoing
        ? const Color(0xFF10B981)
        : isLive
            ? event.accentColor.withValues(alpha: 0.3)
            : AppColors.cardBorder;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: isOngoing ? 1.5 : 1),
        boxShadow: isOngoing
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Status Indicator Bar
          Container(
            width: 3.5,
            height: 38,
            decoration: BoxDecoration(
              color: isOngoing
                  ? const Color(0xFF10B981)
                  : (isPast ? AppColors.textMuted : event.accentColor),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),

          // Main Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Tag & Time Row
                Row(
                  children: [
                    if (isOngoing)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 6, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'LIVE NOW',
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: event.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isLive
                              ? 'LIVE'
                              : (event.type == TimetableEventType.labPractical ? 'LAB' : 'THEORY'),
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: event.accentColor,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        event.timeRangeStr,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Title
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 2),

                // Course & Instructor
                Text(
                  '${event.courseName} • ${event.instructor}',
                  style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Join Button
          if (isLive || isOngoing)
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: () => _handleJoinMeeting(context, event),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOngoing ? const Color(0xFF10B981) : AppColors.primary.withValues(alpha: 0.1),
                  foregroundColor: isOngoing ? Colors.white : AppColors.primary,
                  elevation: isOngoing ? 1 : 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOngoing ? Icons.play_arrow_rounded : Icons.videocam_rounded,
                      size: 14,
                      color: isOngoing ? Colors.white : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOngoing ? 'Join' : 'Upcoming',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isOngoing ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatHourLabel(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${h.toString().padLeft(2, '0')}:00 $period';
  }

  String _getDayAbbreviation(int weekday) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[weekday - 1];
  }
}
