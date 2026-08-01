import 'package:flutter/material.dart';
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

  String _selectedCategoryPill = 'All'; // 'All', 'MSBTE', 'SPPU', 'DBATU', 'DEMO', 'RECORDED', 'LIVE'
  String _selectedType = 'All'; // 'All', 'ENGINEERING', 'POLYTECHNIC'
  String _selectedBranch = 'All'; // 'All', 'Mechanical', 'Computer', etc.
  String _searchQuery = '';

  bool _isLoading = true;
  String? _errorMessage;
  List<CourseModel> _courses = [];
  Set<String> _requestedCourseIds = {};
  Set<String> _enrolledCourseIds = {};

  static const List<Map<String, String>> _categoryPills = [
    {'id': 'All', 'label': 'All Courses'},
    {'id': 'MSBTE', 'label': 'MSBTE'},
    {'id': 'SPPU', 'label': 'SPPU'},
    {'id': 'DBATU', 'label': 'DBATU'},
    {'id': 'LIVE', 'label': 'Live Batches'},
    {'id': 'RECORDED', 'label': 'Recorded'},
    {'id': 'DEMO', 'label': 'Demo'},
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
    // Apply the initial category filter passed from Home Quick Access cards
    if (widget.initialCategoryPill != null &&
        widget.initialCategoryPill!.isNotEmpty) {
      _selectedCategoryPill = widget.initialCategoryPill!;
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
    if (_selectedType != 'All') count++;
    if (_selectedBranch != 'All') count++;
    return count;
  }

  String get _currentPillLabel {
    final pill = _categoryPills.firstWhere(
      (p) => p['id'] == _selectedCategoryPill,
      orElse: () => {'id': 'All', 'label': 'All Courses'},
    );
    return pill['label']!;
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? univFilter;
      if (_selectedCategoryPill == 'MSBTE' ||
          _selectedCategoryPill == 'SPPU' ||
          _selectedCategoryPill == 'DBATU') {
        univFilter = _selectedCategoryPill;
      }

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

      if (_selectedCategoryPill == 'LIVE') {
        content = content
            .where((c) =>
                c.mode.toUpperCase() == 'LIVE' ||
                c.mode.toUpperCase() == 'BOTH' ||
                c.mode.toUpperCase() == 'LIVE_RECORDED')
            .toList();
      } else if (_selectedCategoryPill == 'RECORDED') {
        content = content
            .where((c) =>
                c.mode.toUpperCase() == 'RECORDED' ||
                c.mode.toUpperCase() == 'BOTH' ||
                c.mode.toUpperCase() == 'LIVE_RECORDED')
            .toList();
      } else if (_selectedCategoryPill == 'DEMO') {
        content = content.where((c) => c.price <= 0).toList();
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
      _selectedCategoryPill = 'All';
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
          if (_activeFilterCount > 0 || _selectedCategoryPill != 'All' || _searchQuery.isNotEmpty)
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

                const SizedBox(height: 16),

                // Category Pills (MSBTE, SPPU, DBATU, Demo, Recorded, Live)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categoryPills.map((pill) {
                      final pillId = pill['id']!;
                      final pillLabel = pill['label']!;
                      final isSelected = _selectedCategoryPill == pillId;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategoryPill = pillId);
                            _loadCourses();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.cardBorder,
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
                            child: Text(
                              pillLabel,
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

                const SizedBox(height: 14),

                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategoryPill == 'All'
                          ? 'All Available Courses (${_courses.length})'
                          : '$_currentPillLabel (${_courses.length})',
                      style: AppStyles.headingMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Course Feed / Skeleton / Empty State
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
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
