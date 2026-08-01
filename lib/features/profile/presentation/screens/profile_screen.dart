import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/data/repositories/auth_repository.dart';

// Restores default system UI overlay when leaving the profile screen
class _RestoreSystemUi extends StatefulWidget {
  final Widget child;
  const _RestoreSystemUi({required this.child});
  @override
  State<_RestoreSystemUi> createState() => _RestoreSystemUiState();
}

class _RestoreSystemUiState extends State<_RestoreSystemUi> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}


/// Student Profile Screen — premium, editable, and minimal.
class ProfileScreen extends StatefulWidget {
  final UserModel? user;
  final AuthRepository? authRepository;

  const ProfileScreen({
    super.key,
    this.user,
    this.authRepository,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final AuthRepository _authRepository;
  late final TextEditingController _nameController;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  UserModel? _currentUser;
  bool _isEditingName = false;
  bool _isSaving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? AuthRepository();
    _currentUser = widget.user;
    _nameController = TextEditingController(
      text: _currentUser?.name?.isNotEmpty == true ? _currentUser!.name! : 'Student',
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    _loadStoredUser();
  }

  Future<void> _loadStoredUser() async {
    final stored = await _authRepository.getStoredUser();
    if (stored != null && mounted) {
      setState(() {
        _currentUser = stored;
        if (!_isEditingName && stored.name != null && stored.name!.isNotEmpty) {
          _nameController.text = stored.name!;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final newName = _nameController.text.trim();
    setState(() => _isSaving = true);
    HapticFeedback.lightImpact();

    try {
      final updatedUser = await _authRepository.updateProfileName(newName);
      if (!mounted) return;
      setState(() {
        _currentUser = updatedUser;
        _isEditingName = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Name updated!', style: TextStyle(fontWeight: FontWeight.w600)),
          ]),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String get _studentName =>
      _currentUser?.name?.isNotEmpty == true ? _currentUser!.name! : 'Student';

  String get _mobileDisplay =>
      _currentUser?.mobileNumber.isNotEmpty == true
          ? '+91 ${_currentUser!.mobileNumber}'
          : '+91 XXXXXXXXXX';

  String get _initials {
    final parts = _studentName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _studentName.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return _RestoreSystemUi(
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // Collapsible App Bar with Profile Header
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: AppColors.primaryDark,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'My Profile',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Avatar with initials
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _initials,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _studentName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _mobileDisplay,
                          style: const TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 22),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Page Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),

                    // Account Section Label
                    const Text(
                      'ACCOUNT INFORMATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Information Card
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.cardBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Name Row — Editable
                          _buildInfoRow(
                            icon: Icons.person_rounded,
                            label: 'Full Name',
                            value: _studentName,
                            onEdit: () => setState(() {
                              _nameController.text = _studentName;
                              _isEditingName = true;
                            }),
                            showDivider: true,
                          ),

                          // Mobile Number Row — Read-only
                          _buildInfoRow(
                            icon: Icons.phone_android_rounded,
                            label: 'Mobile Number',
                            value: _mobileDisplay,
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),

                    // Inline Name Edit Panel
                    if (_isEditingName) ...[
                      const SizedBox(height: 20),
                      const Text(
                        'EDIT NAME',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMuted,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Form(
                        key: _formKey,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _nameController,
                                autofocus: true,
                                textCapitalization: TextCapitalization.words,
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) return 'Name cannot be empty';
                                  if (v.trim().length < 2) return 'Name too short';
                                  return null;
                                },
                                decoration: InputDecoration(
                                  hintText: 'Enter your full name',
                                  prefixIcon: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.cardBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                                  ),
                                  filled: true,
                                  fillColor: AppColors.background,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => setState(() => _isEditingName = false),
                                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    onPressed: _isSaving ? null : _saveName,
                                    icon: _isSaving
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                          )
                                        : const Icon(Icons.check_rounded, size: 16),
                                    label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onEdit,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                  ),
                ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }
}
