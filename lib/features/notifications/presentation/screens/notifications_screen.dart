import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/notification_model.dart';
import '../../data/repositories/notification_repository.dart';

/// Notification Screen — clean, grouped by date, type-coded icon chips, swipe/button delete.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repository = NotificationRepository();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final items = await _repository.getMyNotifications();
    await _repository.markNotificationsAsRead();
    if (!mounted) return;
    setState(() {
      _notifications = items;
      _isLoading = false;
    });
  }

  Future<void> _deleteSingleNotification(String id) async {
    setState(() {
      _notifications.removeWhere((item) => item.id == id);
    });
    await _repository.deleteNotification(id);
  }

  Future<void> _clearAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Notifications',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content:
            const Text('Are you sure you want to remove all notifications?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final toDelete = List<NotificationModel>.from(_notifications);
    setState(() {
      _notifications.clear();
    });

    await Future.wait(toDelete.map((n) => _repository.deleteNotification(n.id)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary),
        ),
        actions: [
          if (_notifications.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded,
                  color: Colors.redAccent, size: 22),
              tooltip: 'Clear All',
              onPressed: _clearAllNotifications,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_notifications.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.primary,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_off_outlined,
                    size: 48, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              const Text('No Notifications Yet',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              const Text('New updates and announcements\nwill appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    // Group notifications by relative date
    final grouped = <String, List<NotificationModel>>{};
    for (final n in _notifications) {
      final label = _dateLabel(n.createdAt);
      grouped.putIfAbsent(label, () => []).add(n);
    }

    final entries = grouped.entries.toList();

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: entries.fold<int>(0, (sum, e) => sum + 1 + e.value.length),
      itemBuilder: (context, index) {
        int cursor = 0;
        for (final entry in entries) {
          if (index == cursor) {
            return _buildDateHeader(entry.key);
          }
          cursor++;
          for (final n in entry.value) {
            if (index == cursor) return _buildNotificationCard(n);
            cursor++;
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel n) {
    final meta = _typeMeta(n.type);
    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 24),
      ),
      onDismissed: (_) => _deleteSingleNotification(n.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon chip
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: meta.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(meta.icon, color: meta.color, size: 20),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: meta.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            meta.label,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: meta.color,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _timeAgo(n.createdAt),
                          style: const TextStyle(
                              fontSize: 10.5, color: AppColors.textMuted),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => _deleteSingleNotification(n.id),
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.close_rounded,
                                size: 16, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      n.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    if (n.body.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        n.body,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dtDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(dtDay).inDays;
    if (diff == 0) return 'TODAY';
    if (diff == 1) return 'YESTERDAY';
    if (diff < 7) return 'THIS WEEK';
    return 'EARLIER';
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  _NotifMeta _typeMeta(String type) {
    switch (type) {
      case 'LIVE_CLASS':
        return _NotifMeta(
            icon: Icons.live_tv_rounded,
            color: const Color(0xFF10B981),
            label: 'LIVE CLASS');
      case 'DPP':
        return _NotifMeta(
            icon: Icons.assignment_rounded,
            color: const Color(0xFF8B5CF6),
            label: 'DPP');
      case 'ANNOUNCEMENT':
        return _NotifMeta(
            icon: Icons.campaign_rounded,
            color: const Color(0xFFEF4444),
            label: 'ANNOUNCEMENT');
      case 'RESULT':
        return _NotifMeta(
            icon: Icons.bar_chart_rounded,
            color: const Color(0xFFF59E0B),
            label: 'RESULT');
      case 'VIDEO':
        return _NotifMeta(
            icon: Icons.play_circle_fill_rounded,
            color: AppColors.primary,
            label: 'NEW VIDEO');
      default:
        return _NotifMeta(
            icon: Icons.info_outline_rounded,
            color: AppColors.primary,
            label: 'GENERAL');
    }
  }
}

class _NotifMeta {
  final IconData icon;
  final Color color;
  final String label;
  const _NotifMeta(
      {required this.icon, required this.color, required this.label});
}
