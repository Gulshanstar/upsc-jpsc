import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../providers/revision_provider.dart';
import '../providers/user_provider.dart';
import '../models/revision_item.dart';

class RevisionScreen extends ConsumerStatefulWidget {
  const RevisionScreen({super.key});

  @override
  ConsumerState<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends ConsumerState<RevisionScreen> {
  int _cardIndex = 0;
  bool _sessionComplete = false;
  String _selectedTab = 'Today';
  bool _firstLoad = true;

  // Undo facility properties
  String? _lastReviewedId;
  DateTime? _lastReviewedPrevDate;
  int? _lastReviewedPrevInterval;
  double? _lastReviewedPrevEase;

  @override
  Widget build(BuildContext context) {
    ref.watch(revisionProvider); // Watch revisions to reactively update on revision state changes
    ref.watch(userProfileProvider); // Watch profile to reactively update on examMode changes
    final revisionNotifier = ref.read(revisionProvider.notifier);
    
    // Split into strictly overdue and strictly today
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final overdueItems = revisionNotifier.filteredState.where((r) => !r.lockedForEver && r.nextDueDate.isBefore(todayStart)).toList();
    final todayItems = revisionNotifier.filteredState.where((r) =>
        !r.lockedForEver &&
        r.nextDueDate.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
        r.nextDueDate.isBefore(todayEnd.add(const Duration(seconds: 1)))).toList();
    
    // Tomorrow Items
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowStart = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final tomorrowEnd = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);
    final tomorrowItems = revisionNotifier.filteredState.where((r) =>
        !r.lockedForEver &&
        r.nextDueDate.isAfter(tomorrowStart.subtract(const Duration(seconds: 1))) &&
        r.nextDueDate.isBefore(tomorrowEnd.add(const Duration(seconds: 1)))).toList();
        
    // Upcoming Items (Next 7 days starting from tomorrow, e.g. tomorrow to day 7)
    final upcomingStart = DateTime.now().add(const Duration(days: 1));
    final upcomingStartDay = DateTime(upcomingStart.year, upcomingStart.month, upcomingStart.day);
    final upcomingCutoff = DateTime.now().add(const Duration(days: 7));
    final upcomingCutoffDay = DateTime(upcomingCutoff.year, upcomingCutoff.month, upcomingCutoff.day, 23, 59, 59);
    final upcomingItems = revisionNotifier.filteredState.where((r) =>
        !r.lockedForEver &&
        r.nextDueDate.isAfter(upcomingStartDay.subtract(const Duration(seconds: 1))) &&
        r.nextDueDate.isBefore(upcomingCutoffDay.add(const Duration(seconds: 1)))).toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    // Completed/Done Items
    final completedItems = revisionNotifier.filteredState.where((r) {
      if (r.lockedForEver) return true;
      if (r.lastReviewedDate != null) {
        return r.lastReviewedDate!.isAfter(todayStart.subtract(const Duration(seconds: 1))) &&
               r.lastReviewedDate!.isBefore(todayEnd.add(const Duration(seconds: 1)));
      }
      return false;
    }).toList();

    if (_firstLoad) {
      if (overdueItems.isNotEmpty) {
        _selectedTab = 'Overdue';
      } else {
        _selectedTab = 'Today';
      }
      _firstLoad = false;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Revision', style: GoogleFonts.instrumentSerif(fontSize: 24)),
            backgroundColor: AppColors.background,
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month_rounded, color: AppColors.gold),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => _RevisionCalendarSheet(revisions: revisionNotifier.filteredState),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.goldSurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${overdueItems.length + todayItems.length} due',
                        style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Stats strip
                _StatsStrip(notifier: revisionNotifier),
                const SizedBox(height: 16),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTabPill('Overdue', overdueItems.length),
                    _buildTabPill('Today', todayItems.length),
                    _buildTabPill('Tomorrow', tomorrowItems.length),
                    _buildTabPill('Upcoming', upcomingItems.length),
                    _buildTabPill('Completed', completedItems.length),
                  ],
                ),
                const SizedBox(height: 20),

                // Tab Content
                if (_selectedTab == 'Overdue') ...[
                  if (overdueItems.isEmpty || _sessionComplete) ...[
                    _DoneCard(
                      title: "All caught up! 🎉",
                      subtitle: "You have no overdue revisions right now. Excellent study discipline!",
                      onReset: () => setState(() {
                        _cardIndex = 0;
                        _sessionComplete = false;
                      }),
                      onUndo: _lastReviewedId == null ? null : () async {
                        await ref.read(revisionProvider.notifier).revertReview(
                          _lastReviewedId!,
                          _lastReviewedPrevDate,
                          _lastReviewedPrevInterval!,
                          _lastReviewedPrevEase!,
                        );
                        setState(() {
                          _lastReviewedId = null;
                          if (_cardIndex > 0) _cardIndex--;
                          _sessionComplete = false;
                        });
                      },
                    ).animate().scale(duration: 400.ms),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Overdue Revisions",
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text("${overdueItems.length - _cardIndex} cards remaining",
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                          ],
                        ),
                        if (_lastReviewedId != null)
                          TextButton.icon(
                            onPressed: () async {
                              await ref.read(revisionProvider.notifier).revertReview(
                                _lastReviewedId!,
                                _lastReviewedPrevDate,
                                _lastReviewedPrevInterval!,
                                _lastReviewedPrevEase!,
                              );
                              setState(() {
                                _lastReviewedId = null;
                                if (_cardIndex > 0) _cardIndex--;
                                _sessionComplete = false;
                              });
                            },
                            icon: const Icon(Icons.undo_rounded, size: 16, color: AppColors.gold),
                            label: Text('Undo', style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 13)),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.goldSurface,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Swipe card stack
                    if (_cardIndex < overdueItems.length)
                      _SwipeCardStack(
                        items: overdueItems,
                        currentIndex: _cardIndex,
                        onRemembered: (item) async {
                          setState(() {
                            _lastReviewedId = item.id;
                            _lastReviewedPrevDate = item.lastReviewedDate;
                            _lastReviewedPrevInterval = item.intervalDays;
                            _lastReviewedPrevEase = item.easeFactor;
                          });
                          await ref.read(revisionProvider.notifier).reviewItem(item.id, true);
                          setState(() {
                            if (_cardIndex >= overdueItems.length - 1) _sessionComplete = true;
                            else _cardIndex++;
                          });
                        },
                        onForgot: (item) async {
                          setState(() {
                            _lastReviewedId = item.id;
                            _lastReviewedPrevDate = item.lastReviewedDate;
                            _lastReviewedPrevInterval = item.intervalDays;
                            _lastReviewedPrevEase = item.easeFactor;
                          });
                          await ref.read(revisionProvider.notifier).reviewItem(item.id, false);
                          setState(() {
                            if (_cardIndex >= overdueItems.length - 1) _sessionComplete = true;
                            else _cardIndex++;
                          });
                        },
                      ).animate().fadeIn(duration: 300.ms),
                  ],
                ] else if (_selectedTab == 'Today') ...[
                  if (todayItems.isEmpty || _sessionComplete) ...[
                    _DoneCard(
                      title: "All done for today! 🎉",
                      subtitle: "You've completed all revision due today.\nGreat job staying consistent!",
                      onReset: () => setState(() {
                        _cardIndex = 0;
                        _sessionComplete = false;
                      }),
                      onUndo: _lastReviewedId == null ? null : () async {
                        await ref.read(revisionProvider.notifier).revertReview(
                          _lastReviewedId!,
                          _lastReviewedPrevDate,
                          _lastReviewedPrevInterval!,
                          _lastReviewedPrevEase!,
                        );
                        setState(() {
                          _lastReviewedId = null;
                          if (_cardIndex > 0) _cardIndex--;
                          _sessionComplete = false;
                        });
                      },
                    ).animate().scale(duration: 400.ms),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Due Today",
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text("${todayItems.length - _cardIndex} cards remaining",
                                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                          ],
                        ),
                        if (_lastReviewedId != null)
                          TextButton.icon(
                            onPressed: () async {
                              await ref.read(revisionProvider.notifier).revertReview(
                                _lastReviewedId!,
                                _lastReviewedPrevDate,
                                _lastReviewedPrevInterval!,
                                _lastReviewedPrevEase!,
                              );
                              setState(() {
                                _lastReviewedId = null;
                                if (_cardIndex > 0) _cardIndex--;
                                _sessionComplete = false;
                              });
                            },
                            icon: const Icon(Icons.undo_rounded, size: 16, color: AppColors.gold),
                            label: Text('Undo', style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w600, fontSize: 13)),
                            style: TextButton.styleFrom(
                              backgroundColor: AppColors.goldSurface,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Swipe card stack
                    if (_cardIndex < todayItems.length)
                      _SwipeCardStack(
                        items: todayItems,
                        currentIndex: _cardIndex,
                        onRemembered: (item) async {
                          setState(() {
                            _lastReviewedId = item.id;
                            _lastReviewedPrevDate = item.lastReviewedDate;
                            _lastReviewedPrevInterval = item.intervalDays;
                            _lastReviewedPrevEase = item.easeFactor;
                          });
                          await ref.read(revisionProvider.notifier).reviewItem(item.id, true);
                          setState(() {
                            if (_cardIndex >= todayItems.length - 1) _sessionComplete = true;
                            else _cardIndex++;
                          });
                        },
                        onForgot: (item) async {
                          setState(() {
                            _lastReviewedId = item.id;
                            _lastReviewedPrevDate = item.lastReviewedDate;
                            _lastReviewedPrevInterval = item.intervalDays;
                            _lastReviewedPrevEase = item.easeFactor;
                          });
                          await ref.read(revisionProvider.notifier).reviewItem(item.id, false);
                          setState(() {
                            if (_cardIndex >= todayItems.length - 1) _sessionComplete = true;
                            else _cardIndex++;
                          });
                        },
                      ).animate().fadeIn(duration: 300.ms),
                  ],
                ] else if (_selectedTab == 'Tomorrow') ...[
                  Text("Revisions Tomorrow",
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  if (tomorrowItems.isEmpty)
                    _buildEmptyPlaceholder("No revisions due tomorrow. Take some rest or study new topics!")
                  else
                    ...tomorrowItems.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _UpcomingTile(item: e.value),
                        )).toList().animate(interval: 60.ms).fadeIn().slideX(begin: 0.1),
                ] else if (_selectedTab == 'Completed') ...[
                  Text("Completed Revisions Today",
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  if (completedItems.isEmpty)
                    _buildEmptyPlaceholder("No completed revisions yet. Complete revisions in Overdue or Today tabs!")
                  else
                    ...completedItems.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.lockedForEver 
                                ? AppColors.gold.withValues(alpha: 0.4) 
                                : AppColors.border
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(
                                color: item.lockedForEver 
                                    ? AppColors.goldSurface 
                                    : AppColors.greenSurface,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                item.lockedForEver 
                                    ? Icons.lock_rounded 
                                    : Icons.check_circle_rounded, 
                                color: item.lockedForEver 
                                    ? AppColors.gold 
                                    : AppColors.green, 
                                size: 16
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.topicTitle,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.5, 
                                      fontWeight: FontWeight.w600, 
                                      color: AppColors.textPrimary,
                                      decoration: item.lockedForEver ? TextDecoration.lineThrough : null,
                                    ),
                                    maxLines: 1, 
                                    overflow: TextOverflow.ellipsis
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.subjectName} • ${item.sectionName}', 
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Action buttons
                            if (!item.lockedForEver) ...[
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                tooltip: 'Undo Review',
                                icon: const Icon(Icons.undo_rounded, color: AppColors.gold, size: 18),
                                onPressed: () async {
                                  // Revert review back to rotation
                                  await ref.read(revisionProvider.notifier).revertReview(
                                    item.id,
                                    _lastReviewedId == item.id ? _lastReviewedPrevDate : item.lastReviewedDate?.subtract(Duration(days: item.intervalDays)),
                                    _lastReviewedId == item.id ? (_lastReviewedPrevInterval ?? 1) : item.intervalDays,
                                    _lastReviewedId == item.id ? (_lastReviewedPrevEase ?? 2.5) : item.easeFactor,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Reverted "${item.topicTitle}" back to active rotation.'),
                                      backgroundColor: AppColors.green,
                                    ),
                                  );
                                },
                              ),
                            ],
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              tooltip: item.lockedForEver ? 'Unlock Revision' : 'Lock Forever',
                              icon: Icon(
                                item.lockedForEver ? Icons.lock_open_rounded : Icons.lock_rounded, 
                                color: item.lockedForEver ? AppColors.textMuted : AppColors.gold, 
                                size: 18
                              ),
                              onPressed: () async {
                                await ref.read(revisionProvider.notifier).toggleLockRevision(item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(item.lockedForEver 
                                        ? 'Unlocked "${item.topicTitle}".' 
                                        : 'Locked "${item.topicTitle}" forever! It will no longer show up as due.'),
                                    backgroundColor: AppColors.gold,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList().animate(interval: 60.ms).fadeIn().slideX(begin: 0.1),
                ] else ...[
                  Text("Upcoming This Week",
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  if (upcomingItems.isEmpty)
                    _buildEmptyPlaceholder("No upcoming revisions scheduled for this week.")
                  else
                    ...upcomingItems.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _UpcomingTile(item: e.value),
                        )).toList().animate(interval: 60.ms).fadeIn().slideX(begin: 0.1),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(String tabName, int count) {
    final isSelected = _selectedTab == tabName;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = tabName;
          _cardIndex = 0;
          _sessionComplete = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.border,
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tabName,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.gold : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold.withValues(alpha: 0.12) : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.gold : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.spa_rounded, color: AppColors.gold, size: 40),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  final RevisionNotifier notifier;
  const _StatsStrip({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(Icons.check_rounded, '${(notifier.weeklyRecallRate * 100).toInt()}%', 'Recall Rate', AppColors.green),
        const SizedBox(width: 10),
        _StatChip(Icons.replay_rounded, '${notifier.totalRevisedThisWeek}', 'This Week', AppColors.blue),
        const SizedBox(width: 10),
        _StatChip(Icons.warning_amber_rounded, '${notifier.overdue.length}', 'Overdue', AppColors.orange),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatChip(this.icon, this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _SwipeCardStack extends StatelessWidget {
  final List<RevisionItem> items;
  final int currentIndex;
  final Function(RevisionItem) onRemembered;
  final Function(RevisionItem) onForgot; // kept for signature compatibility but unused

  const _SwipeCardStack({
    required this.items,
    required this.currentIndex,
    required this.onRemembered,
    required this.onForgot,
  });

  @override
  Widget build(BuildContext context) {
    // Render all items together in a Column so they are visible at the same time
    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isReviewed = index < currentIndex;

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isReviewed ? 0.4 : 1.0,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isReviewed 
                    ? [AppColors.surface, AppColors.surface] 
                    : [AppColors.surfaceElevated, AppColors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isReviewed ? AppColors.border : AppColors.gold.withValues(alpha: 0.2)
              ),
              boxShadow: isReviewed ? [] : [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.goldSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item.sectionName,
                        style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.gold, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    if (item.examType == 'jpsc')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.greenSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'JPSC',
                          style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.green, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.topicTitle,
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 22, 
                    color: AppColors.textPrimary, 
                    height: 1.2,
                    decoration: isReviewed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.subjectName,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event_repeat_rounded,
                          size: 13,
                          color: item.isOverdue ? AppColors.red : AppColors.gold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Scheduled: ${item.nextDueDate.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][item.nextDueDate.month - 1]}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: item.isOverdue ? AppColors.red : AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (!isReviewed)
                      GestureDetector(
                        onTap: () => onRemembered(item),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.greenSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.green.withOpacity(0.4)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_rounded, color: AppColors.green, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Got it!',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.green),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Completed',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.green, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}



class _UpcomingTile extends ConsumerWidget {
  final RevisionItem item;
  const _UpcomingTile({required this.item, super.key});

  void _showUpcomingDetailSheet(BuildContext context, RevisionItem item, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final initialDate = item.lastReviewedDate?.subtract(Duration(days: item.intervalDays)) ?? item.nextDueDate.subtract(Duration(days: item.intervalDays));
        final formattedInitial = DateFormat('dd MMM yyyy').format(initialDate);
        final intervals = [
          (1, '1st Review', 1),
          (2, '2nd Review', 3),
          (3, '3rd Review', 8),
          (4, '4th Review', 20),
          (5, '5th Review', 50),
        ];

        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4, 
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.topicTitle, 
                          style: GoogleFonts.instrumentSerif(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary)
                        ),
                        Text(
                          '${item.subjectName} • ${item.sectionName}', 
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24, color: AppColors.border),
              Text(
                'Initial Study Session: $formattedInitial', 
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)
              ),
              const SizedBox(height: 16),
              ...intervals.map((i) {
                final stepNum = i.$1;
                final stepTitle = i.$2;
                final delayDays = i.$3;
                final targetDate = initialDate.add(Duration(days: delayDays));
                final dateStr = DateFormat('dd MMM yyyy').format(targetDate);

                bool isDone = item.revisionCount >= stepNum;
                bool isCurrent = item.revisionCount == stepNum - 1;

                Color stepColor = AppColors.textMuted;
                IconData stepIcon = Icons.radio_button_unchecked_rounded;

                if (isDone) {
                  stepColor = AppColors.green;
                  stepIcon = Icons.check_circle_rounded;
                } else if (isCurrent) {
                  stepColor = AppColors.gold;
                  stepIcon = Icons.pending_rounded;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Row(
                    children: [
                      Icon(stepIcon, size: 16, color: stepColor),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$stepTitle (Day $delayDays)', 
                            style: GoogleFonts.inter(
                              fontSize: 12, 
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, 
                              color: AppColors.textPrimary
                            )
                          ),
                          Text(
                            dateStr, 
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (isDone)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.greenSurface, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            'Done', 
                            style: GoogleFonts.inter(fontSize: 9, color: AppColors.green, fontWeight: FontWeight.bold)
                          ),
                        )
                      else if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: AppColors.goldSurface, borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            'Upcoming', 
                            style: GoogleFonts.inter(fontSize: 9, color: AppColors.gold, fontWeight: FontWeight.bold)
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(item.nextDueDate.year, item.nextDueDate.month, item.nextDueDate.day);
    final daysLeft = target.difference(today).inDays;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showUpcomingDetailSheet(context, item, ref),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.blueSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flip_rounded, color: AppColors.blue, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.topicTitle,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(item.subjectName, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                        Text(' • ', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                        Text(
                          '${item.nextDueDate.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][item.nextDueDate.month - 1]}',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.blueSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(daysLeft <= 1 ? 'Tomorrow' : 'In $daysLeft days',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoneCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onReset;
  final VoidCallback? onUndo;
  const _DoneCard({required this.title, required this.subtitle, required this.onReset, this.onUndo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.greenSurface, AppColors.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.green.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.celebration_rounded, color: AppColors.green, size: 56),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: GoogleFonts.instrumentSerif(fontSize: 26, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted, height: 1.6)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: Text("Review Again", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              ),
              if (onUndo != null)
                TextButton.icon(
                  onPressed: onUndo,
                  icon: const Icon(Icons.undo_rounded, size: 18, color: AppColors.gold),
                  label: Text('Undo Revert', style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.goldSurface,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevisionCalendarSheet extends StatefulWidget {
  final List<RevisionItem> revisions;
  const _RevisionCalendarSheet({required this.revisions});

  @override
  State<_RevisionCalendarSheet> createState() => _RevisionCalendarSheetState();
}

class _RevisionCalendarSheetState extends State<_RevisionCalendarSheet> {
  late DateTime _focusedMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final leadDays = firstDayOfMonth.weekday - 1;

    final List<DateTime?> calendarDays = [];
    for (int i = 0; i < leadDays; i++) {
      calendarDays.add(null);
    }
    for (int d = 1; d <= daysInMonth; d++) {
      calendarDays.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }

    final monthName = DateFormat('MMMM yyyy').format(_focusedMonth);

    // Filter revisions for the selected day
    final revisionsForSelectedDay = _selectedDay == null
        ? <RevisionItem>[]
        : widget.revisions.where((r) {
            return r.nextDueDate.year == _selectedDay!.year &&
                r.nextDueDate.month == _selectedDay!.month &&
                r.nextDueDate.day == _selectedDay!.day;
          }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revision Calendar',
                style: GoogleFonts.instrumentSerif(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Keep track of your scheduled revisions. Dates with dots indicate how many topic reviews are scheduled for that day. Tap any day to inspect them.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 16),
          
          // Calendar structure
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _previousMonth,
                      icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
                    ),
                    Text(
                      monthName,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                    return Center(
                      child: Text(
                        day,
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: calendarDays.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemBuilder: (context, index) {
                    final day = calendarDays[index];
                    if (day == null) {
                      return const SizedBox.shrink();
                    }

                    final count = widget.revisions.where((r) {
                      return r.nextDueDate.year == day.year &&
                          r.nextDueDate.month == day.month &&
                          r.nextDueDate.day == day.day;
                    }).length;

                    final isSelected = _selectedDay != null &&
                        _selectedDay!.year == day.year &&
                        _selectedDay!.month == day.month &&
                        _selectedDay!.day == day.day;

                    final isToday = DateTime.now().year == day.year &&
                        DateTime.now().month == day.month &&
                        DateTime.now().day == day.day;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDay = day;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.goldSurface
                              : isToday
                                  ? AppColors.goldSurface.withValues(alpha: 0.5)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.gold
                                : isToday
                                    ? AppColors.gold.withValues(alpha: 0.5)
                                    : Colors.transparent,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                                color: isSelected
                                    ? AppColors.gold
                                    : isToday
                                        ? AppColors.gold
                                        : AppColors.textPrimary,
                              ),
                            ),
                            if (count > 0)
                              Positioned(
                                bottom: 4,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: const BoxDecoration(
                                    color: AppColors.gold,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$count',
                                      style: GoogleFonts.inter(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            _selectedDay == null
                ? 'Select a day to see revisions'
                : 'Revisions for ${DateFormat('dd MMM yyyy').format(_selectedDay!)}',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: revisionsForSelectedDay.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'No revisions scheduled for this day.',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: revisionsForSelectedDay.length,
                    itemBuilder: (context, index) {
                      final item = revisionsForSelectedDay[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.goldSurface,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.menu_book_rounded, color: AppColors.gold, size: 14),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.topicTitle,
                                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${item.subjectName} • ${item.sectionName}',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
     ),
    );
  }
}
