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

  @override
  Widget build(BuildContext context) {
    ref.watch(revisionProvider); // Watch revisions to reactively update on revision state changes
    ref.watch(userProfileProvider); // Watch profile to reactively update on examMode changes
    final revisionNotifier = ref.read(revisionProvider.notifier);
    final dueItems = revisionNotifier.filteredState.where((r) => r.isDueToday).toList();
    
    // Tomorrow Items
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowStart = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    final tomorrowEnd = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 23, 59, 59);
    final tomorrowItems = revisionNotifier.filteredState.where((r) =>
        r.nextDueDate.isAfter(tomorrowStart.subtract(const Duration(seconds: 1))) &&
        r.nextDueDate.isBefore(tomorrowEnd.add(const Duration(seconds: 1)))).toList();
        
    // Upcoming Items (Next 7 days, excluding today & tomorrow)
    final upcomingStart = DateTime.now().add(const Duration(days: 2));
    final upcomingStartDay = DateTime(upcomingStart.year, upcomingStart.month, upcomingStart.day);
    final upcomingCutoff = DateTime.now().add(const Duration(days: 7));
    final upcomingCutoffDay = DateTime(upcomingCutoff.year, upcomingCutoff.month, upcomingCutoff.day, 23, 59, 59);
    final upcomingItems = revisionNotifier.filteredState.where((r) =>
        r.nextDueDate.isAfter(upcomingStartDay.subtract(const Duration(seconds: 1))) &&
        r.nextDueDate.isBefore(upcomingCutoffDay.add(const Duration(seconds: 1)))).toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Revision', style: GoogleFonts.instrumentSerif(fontSize: 24)),
            backgroundColor: AppColors.background,
            floating: true,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.goldSurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${dueItems.length} due',
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

                // Horizontal Pill Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabPill('Today', dueItems.length),
                      const SizedBox(width: 8),
                      _buildTabPill('Tomorrow', tomorrowItems.length),
                      const SizedBox(width: 8),
                      _buildTabPill('Upcoming (7 Days)', upcomingItems.length),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Tab Content
                if (_selectedTab == 'Today') ...[
                  if (dueItems.isEmpty || _sessionComplete) ...[
                    _DoneCard(onReset: () => setState(() {
                      _cardIndex = 0;
                      _sessionComplete = false;
                    })).animate().scale(duration: 400.ms),
                  ] else ...[
                    Text("Due Today",
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text("${dueItems.length - _cardIndex} cards remaining",
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                    const SizedBox(height: 16),

                    // Swipe card stack
                    if (_cardIndex < dueItems.length)
                      _SwipeCardStack(
                        items: dueItems,
                        currentIndex: _cardIndex,
                        onRemembered: (item) async {
                          await ref.read(revisionProvider.notifier).reviewItem(item.id, true);
                          setState(() {
                            if (_cardIndex >= dueItems.length - 1) _sessionComplete = true;
                            else _cardIndex++;
                          });
                        },
                        onForgot: (item) async {
                          await ref.read(revisionProvider.notifier).reviewItem(item.id, false);
                          setState(() {
                            if (_cardIndex >= dueItems.length - 1) _sessionComplete = true;
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
      onTap: () => setState(() => _selectedTab = tabName),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldSurface : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Text(
              tabName,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.gold : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold.withValues(alpha: 0.12) : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 10,
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
  final Function(RevisionItem) onForgot;

  const _SwipeCardStack({
    required this.items,
    required this.currentIndex,
    required this.onRemembered,
    required this.onForgot,
  });

  @override
  Widget build(BuildContext context) {
    final item = items[currentIndex];
    return Column(
      children: [
        // Card
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 220),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.surfaceElevated, AppColors.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.goldSurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(item.sectionName,
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w600)),
                  ),
                  const Spacer(),
                  if (item.examType == 'jpsc')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.greenSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('JPSC',
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.green, fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(item.topicTitle,
                  style: GoogleFonts.instrumentSerif(fontSize: 26, color: AppColors.textPrimary, height: 1.3)),
              const SizedBox(height: 8),
              Text(item.subjectName,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.event_repeat_rounded, size: 13, color: AppColors.gold),
                  const SizedBox(width: 6),
                  Text(
                    'Scheduled: ${item.nextDueDate.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][item.nextDueDate.month - 1]}',
                    style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.gold, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (item.lastReviewedDate != null) ...[
                const SizedBox(height: 8),
                Text('Last reviewed ${item.daysSinceLastReview} days ago • Reviewed ${item.revisionCount}x',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
              ],
              const SizedBox(height: 16),
              _buildCardTimeline(item),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => onForgot(item),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.redSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.red.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.close_rounded, color: AppColors.red, size: 22),
                      const SizedBox(width: 8),
                      Text('Forgot', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.red)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: GestureDetector(
                onTap: () => onRemembered(item),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.greenSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.green.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_rounded, color: AppColors.green, size: 22),
                      const SizedBox(width: 8),
                      Text('Got it!', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.green)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Progress dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            items.length.clamp(0, 8),
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: i == currentIndex ? 20 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i < currentIndex
                    ? AppColors.green
                    : i == currentIndex
                        ? AppColors.gold
                        : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardTimeline(RevisionItem item) {
    final initialDate = item.lastReviewedDate?.subtract(Duration(days: item.intervalDays)) ?? DateTime.now().subtract(Duration(days: item.intervalDays));
    final intervals = [
      (1, '1st', 1),
      (2, '2nd', 3),
      (3, '3rd', 8),
      (4, '4th', 20),
      (5, '5th', 50),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, size: 12, color: AppColors.gold),
              const SizedBox(width: 6),
              Text(
                'Forgetting Curve Progression',
                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.gold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: intervals.map((i) {
              final stepNum = i.$1;
              final stepTitle = i.$2;
              final delayDays = i.$3;
              final targetDate = initialDate.add(Duration(days: delayDays));
              
              bool isDone = item.revisionCount >= stepNum;
              bool isCurrent = item.revisionCount == stepNum - 1;

              Color color = AppColors.border;
              if (isDone) color = AppColors.green;
              if (isCurrent) color = AppColors.gold;

              return Column(
                children: [
                  Container(
                    width: 18, height: 18,
                    decoration: BoxDecoration(
                      color: isDone ? AppColors.greenSurface : isCurrent ? AppColors.goldSurface : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 1.5),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check_rounded, size: 10, color: AppColors.green)
                          : isCurrent
                              ? const Icon(Icons.pending_rounded, size: 10, color: AppColors.gold)
                              : Text('$stepNum', style: GoogleFonts.inter(fontSize: 8.5, color: AppColors.textMuted)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$stepTitle Rev',
                    style: GoogleFonts.inter(
                      fontSize: 8, 
                      color: isCurrent ? AppColors.gold : AppColors.textMuted, 
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal
                    ),
                  ),
                  Text(
                    '${targetDate.day}/${targetDate.month}',
                    style: GoogleFonts.inter(fontSize: 7.5, color: AppColors.textMuted),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  final RevisionItem item;
  const _UpcomingTile({required this.item});

  void _showUpcomingDetailSheet(BuildContext context, RevisionItem item) {
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
              Text(
                item.topicTitle, 
                style: GoogleFonts.instrumentSerif(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary)
              ),
              Text(
                '${item.subjectName} • ${item.sectionName}', 
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)
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
  Widget build(BuildContext context) {
    final daysLeft = item.nextDueDate.difference(DateTime.now()).inDays;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showUpcomingDetailSheet(context, item),
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
  final VoidCallback onReset;
  const _DoneCard({required this.onReset});

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
          Text("All done for today! 🎉",
              style: GoogleFonts.instrumentSerif(fontSize: 26, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          Text("You've completed all revision due today.\nGreat job staying consistent!",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted, height: 1.6)),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.replay_rounded, size: 18),
            label: Text("Review Again", style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
