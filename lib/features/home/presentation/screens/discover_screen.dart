import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_styles.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../courses/data/models/course_model.dart';
import '../../../courses/data/repositories/course_repository.dart';
import '../../../courses/presentation/widgets/course_card.dart';

/// Clean, uncluttered modern Discover Screen for browsing university courses,
/// featuring search, horizontal category pills (MSBTE, SPPU, DBATU, Demo, Recorded, Live),
/// and a modern bottom sheet for branch & level filtering.
class DiscoverScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onNavigateToMyCourses;
  final CourseRepository? courseRepository;
  /// Optional initial category pill to pre-select (e.g. 'LIVE', 'RECORDED', 'DEMO').
  final String? initialCategoryPill;

  const DiscoverScreen({
    super.key,
    this.onOpenDrawer,
    this.onNavigateToMyCourses,
    this.courseRepository,
    this.initialCategoryPill,
  });

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  late final CourseRepository _courseRepository;
  late final TextEditingController _searchController;

  String _selectedUniversity = 'All'; // 'All', 'MSBTE', 'SPPU', 'DBATU'
  String _selectedModeFilter = 'All'; // 'All', 'COMBO', 'LIVE', 'RECORDED', 'DEMO'
  String _selectedType = 'All'; // 'All', 'ENGINEERING', 'POLYTECHNIC'
  String _selectedBranch = 'All'; // 'All', 'Mechanical', 'Computer', etc.
  String _searchQuery = '';

  bool _isLoading = true;
  String? _errorMessage;
  List<CourseModel> _courses = [];
  Set<String> _requestedCourseIds = {};
  Set<String> _enrolledCourseIds = {};

  static const List<Map<String, String>> _universities = [
    {'id': 'All', 'label': 'All'},
    {'id': 'MSBTE', 'label': 'MSBTE'},
    {'id': 'SPPU', 'label': 'SPPU'},
    {'id': 'DBATU', 'label': 'DBATU'},
  ];

  static const List<Map<String, String>> _modePills = [
    {'id': 'All', 'label': 'All Courses'},
    {'id': 'COMBO', 'label': '🎁 Combo Offers'},
    {'id': 'LIVE', 'label': '🔴 Live Batches'},
    {'id': 'RECORDED', 'label': '📹 Recorded'},
    {'id': 'DEMO', 'label': '⚡ Free / Demo'},
  ];

  static const List<String> _courseTypes = ['All', 'ENGINEERING', 'POLYTECHNIC'];
  List<String> _branches = [
    'All',
    'Mechanical',
    'Computer',
    'Civil',
    'E&TC',
    'IT',
    'Electrical',
  ];

  @override
  void initState() {
    super.initState();
    _courseRepository = widget.courseRepository ?? CourseRepository();
    _searchController = TextEditingController();
    
    // Apply initial category filter passed from Home Quick Access cards
    if (widget.initialCategoryPill != null && widget.initialCategoryPill!.isNotEmpty) {
      final initVal = widget.initialCategoryPill!;
      if (['MSBTE', 'SPPU', 'DBATU'].contains(initVal)) {
        _selectedUniversity = initVal;
      } else if (['COMBO', 'LIVE', 'RECORDED', 'DEMO'].contains(initVal)) {
        _selectedModeFilter = initVal;
      }
    }
    _loadMasterBranches();
    _loadCourses();
  }

  Future<void> _loadMasterBranches() async {
    try {
      final masterBranches = await _courseRepository.getMasterBranches();
      if (mounted && masterBranches.isNotEmpty) {
        setState(() {
          _branches = ['All', ...masterBranches];
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedUniversity != 'All') count++;
    if (_selectedModeFilter != 'All') count++;
    if (_selectedType != 'All') count++;
    if (_selectedBranch != 'All') count++;
    return count;
  }

  String get _resultsHeaderTitle {
    final parts = <String>[];
    if (_selectedUniversity != 'All') parts.add(_selectedUniversity);
    if (_selectedModeFilter != 'All') {
      final modePill = _modePills.firstWhere(
        (p) => p['id'] == _selectedModeFilter,
        orElse: () => {'id': 'All', 'label': 'All Courses'},
      );
      parts.add(modePill['label']!.replaceAll(RegExp(r'[^\w\s]'), '').trim());
    }

    if (parts.isEmpty) {
      return 'All Available Courses (${_courses.length})';
    }
    return '${parts.join(" • ")} (${_courses.length})';
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final univFilter = _selectedUniversity == 'All' ? null : _selectedUniversity;

      final response = await _courseRepository.getCourses(
        university: univFilter,
        type: _selectedType == 'All' ? null : _selectedType,
        branch: _selectedBranch == 'All' ? null : _selectedBranch,
        searchQuery: _searchQuery,
      );

      final requestedSet = await _courseRepository.getRequestedCourseIds();
      final enrolledSet = await _courseRepository.getEnrolledCourseIds();

      if (!mounted) return;

      List<CourseModel> content = response.content;

      if (_selectedModeFilter == 'COMBO') {
        var comboCourses = await _courseRepository.getComboCourses();
        if (univFilter != null) {
          comboCourses = comboCourses.where((c) {
            final u = (c.university ?? '').toUpperCase();
            final name = c.name.toUpperCase();
            final target = univFilter.toUpperCase();
            return u.contains(target) || name.contains(target);
          }).toList();
        }
        content = comboCourses;
      } else {
        // Exclude combo offer packages from single course discovery views
        content = content.where((c) => !c.isCombo).toList();

        if (_selectedModeFilter == 'LIVE') {
          content = content
              .where((c) =>
                  c.mode.toUpperCase() == 'LIVE' ||
                  c.mode.toUpperCase() == 'BOTH' ||
                  c.mode.toUpperCase() == 'LIVE_RECORDED')
              .toList();
        } else if (_selectedModeFilter == 'RECORDED') {
          content = content
              .where((c) =>
                  c.mode.toUpperCase() == 'RECORDED' ||
                  c.mode.toUpperCase() == 'BOTH' ||
                  c.mode.toUpperCase() == 'LIVE_RECORDED')
              .toList();
        } else if (_selectedModeFilter == 'DEMO') {
          content = content.where((c) => c.price <= 0).toList();
        }
      }

      setState(() {
        _courses = content;
        _requestedCourseIds = requestedSet;
        _enrolledCourseIds = enrolledSet;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _selectedUniversity = 'All';
      _selectedModeFilter = 'All';
      _selectedType = 'All';
      _selectedBranch = 'All';
      _searchQuery = '';
      _searchController.clear();
    });
    _loadCourses();
  }

  Future<void> _handleCancelRequestForCourse(CourseModel course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppStyles.borderRadiusLarge),
        title: const Text('Cancel Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel your enrollment request for "${course.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No, Keep Request', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _courseRepository.cancelPurchaseRequest(course.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase request for "${course.name}" has been cancelled.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadCourses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String tempType = _selectedType;
        String tempBranch = _selectedBranch;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle & Header
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filter Courses', style: AppStyles.headingMedium),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            tempType = 'All';
                            tempBranch = 'All';
                          });
                        },
                        child: const Text('Reset', style: TextStyle(color: AppColors.accent, fontSize: 13)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Course Level
                  const Text('Course Level', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _courseTypes.map((type) {
                      final isSelected = tempType == type;
                      return ChoiceChip(
                        label: Text(type == 'All' ? 'All Levels' : type),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.inputFill,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) setSheetState(() => tempType = type);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 20),

                  // Branch Selector
                  const Text('Engineering Branch', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _branches.map((branch) {
                      final isSelected = tempBranch == branch;
                      return ChoiceChip(
                        label: Text(branch == 'All' ? 'All Branches' : branch),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.inputFill,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) setSheetState(() => tempBranch = branch);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 28),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedType = tempType;
                          _selectedBranch = tempBranch;
                        });
                        Navigator.pop(context);
                        _loadCourses();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        'Apply Filters',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Renders 5 shimmer skeleton cards that match the CourseCard layout.
  Widget _buildShimmerCardList() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8EAF0),
      highlightColor: const Color(0xFFF5F6FA),
      period: const Duration(milliseconds: 1100),
      child: Column(
        children: List.generate(5, (index) => _buildShimmerCard()),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail placeholder (16:9)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(color: const Color(0xFFE8EAF0)),
          ),
          // Text lines placeholder
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title line 1
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                // Title line 2 (shorter)
                Container(
                  height: 12,
                  width: 180,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 12),
                // Subtitle line
                Container(
                  height: 10,
                  width: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8EAF0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 14),
                // Price + button row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 16,
                      width: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF0),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    Container(
                      height: 32,
                      width: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8EAF0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.notes_rounded, color: AppColors.textPrimary, size: 26),
          tooltip: 'Open Menu',
          onPressed: () {
            if (widget.onOpenDrawer != null) {
              widget.onOpenDrawer!();
            } else {
              Scaffold.of(context).openDrawer();
            }
          },
        ),
        title: const Text(
          'Discover',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_activeFilterCount > 0 || _searchQuery.isNotEmpty)
            TextButton(
              onPressed: _resetFilters,
              child: const Text('Reset', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCourses,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 18.0, right: 18.0, top: 14.0, bottom: 90.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar + Filter Button
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                          boxShadow: AppStyles.softShadow,
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            _searchQuery = val.trim();
                            _loadCourses();
                          },
                          decoration: InputDecoration(
                            hintText: 'Search courses, subjects, topics...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.textMuted),
                                    onPressed: () {
                                      _searchController.clear();
                                      _searchQuery = '';
                                      _loadCourses();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Filter Icon Button with Counter Badge
                    InkWell(
                      onTap: _openFilterBottomSheet,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _activeFilterCount > 0 ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _activeFilterCount > 0 ? AppColors.primary : AppColors.cardBorder,
                          ),
                          boxShadow: AppStyles.softShadow,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              color: _activeFilterCount > 0 ? Colors.white : AppColors.textPrimary,
                              size: 20,
                            ),
                            if (_activeFilterCount > 0)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.accent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Tier 1: University Selector Bar ───────────────────────────────
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: _universities.map((u) {
                      final id = u['id']!;
                      final label = u['label']!;
                      final isSelected = _selectedUniversity == id;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedUniversity = id);
                            _loadCourses();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.all(3.5),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.25),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // ── Tier 2: Delivery & Offer Mode Pills ──────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _modePills.map((pill) {
                      final pillId = pill['id']!;
                      final pillLabel = pill['label']!;
                      final isSelected = _selectedModeFilter == pillId;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedModeFilter = pillId);
                            _loadCourses();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primaryLight : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.cardBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              pillLabel,
                              style: TextStyle(
                                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _resultsHeaderTitle,
                      style: AppStyles.headingMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Course Feed / Skeleton / Empty State
                if (_isLoading)
                  _buildShimmerCardList()
                else if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: AppStyles.cardDecoration,
                    child: Column(
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 40, color: AppColors.error),
                        const SizedBox(height: 10),
                        Text(_errorMessage!, textAlign: TextAlign.center, style: AppStyles.bodyMedium),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadCourses,
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                          child: const Text('Retry', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                else if (_courses.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
                    decoration: AppStyles.cardDecoration,
                    child: Column(
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text(
                          'No courses found',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Try adjusting your search term or clearing active category filters.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _resetFilters,
                          child: const Text('Reset All Filters'),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _courses.length,
                    itemBuilder: (context, index) {
                      final course = _courses[index];
                      final isRequested = _requestedCourseIds.contains(course.id);
                      final isEnrolled = _enrolledCourseIds.contains(course.id);

                      return CourseCard(
                        course: course,
                        isRequested: isRequested,
                        isEnrolled: isEnrolled,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.courseDetails,
                            arguments: course,
                          ).then((_) => _loadCourses());
                        },
                        onEnrollTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.courseDetails,
                            arguments: course,
                          ).then((_) => _loadCourses());
                        },
                        onCancelTap: () => _handleCancelRequestForCourse(course),
                        onGoToMyCoursesTap: () {
                          if (widget.onNavigateToMyCourses != null) {
                            widget.onNavigateToMyCourses!();
                          } else {
                            Navigator.pushNamed(
                              context,
                              AppRoutes.courseCurriculum,
                              arguments: course,
                            );
                          }
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
