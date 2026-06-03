import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../providers/user_provider.dart';
import '../providers/session_provider.dart';
import '../providers/revision_provider.dart';
import '../providers/journey_provider.dart';
import '../providers/syllabus_provider.dart';
import '../models/study_session.dart' as ss;
import '../models/user_profile.dart';
import '../widgets/session_log_sheet.dart';
import '../widgets/session_tile.dart';
import '../widgets/gap_resolver_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    ref.watch(sessionProvider);
    final filteredSessions = ref.read(sessionProvider.notifier).filteredState;
    ref.watch(revisionProvider);
    final revisions = ref.read(revisionProvider.notifier).filteredState;
    final syllabus = ref.watch(syllabusProvider);

    final sessionNotifier = ref.read(sessionProvider.notifier);
    final todayHours = sessionNotifier.todayHours;
    final dueCount = revisions.where((r) => r.isDueToday).length;
    final journeyNotifier = ref.read(journeyProvider.notifier);
    final streak = journeyNotifier.currentStreak;
    final totalHoursDevoted = filteredSessions.fold<double>(0.0, (sum, s) => sum + s.durationHours);
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    
    final daysToExam = profile.daysToExam;
    // Watch journeyProvider so that updates to the state list automatically re-trigger this build
    ref.watch(journeyProvider);
    final pendingGaps = ref.read(journeyProvider.notifier).pendingGapDays;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            backgroundColor: AppColors.background,
            title: Row(
              children: [
                const Icon(Icons.auto_stories_rounded, color: AppColors.gold, size: 22),
                const SizedBox(width: 8),
                Text('StudyPath', style: GoogleFonts.instrumentSerif(fontSize: 20, color: AppColors.textPrimary)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textSecondary),
                onPressed: () {},
              ),
              IconButton(
                onPressed: () => context.push('/profile-setup'),
                padding: const EdgeInsets.only(right: 16),
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.goldSurface,
                  child: Text(
                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'A',
                    style: GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Greeting
                Text('$greeting,', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted))
                    .animate().fadeIn(duration: 400.ms),
                Text(profile.name, style: GoogleFonts.instrumentSerif(fontSize: 32, color: AppColors.textPrimary))
                    .animate().fadeIn(delay: 100.ms, duration: 400.ms),
                if (daysToExam > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.goldSurface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('$daysToExam days to exam',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600)),
                  ).animate().fadeIn(delay: 200.ms),
                ],
                const SizedBox(height: 16),
                _QuoteCard().animate().fadeIn(delay: 150.ms),
                const SizedBox(height: 20),

                // Today's snapshot card
                _TodayCard(
                  todayHours: todayHours,
                  goalHours: profile.dailyGoalHours,
                  topicsToday: sessionNotifier.todaySessions.fold<int>(0, (s, e) => s + e.topicsCovered.length),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                
                // Gap Day Accountability Banner
                if (pendingGaps.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => GapResolverSheet.show(context, ref, pendingGaps),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.goldSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.goldSurface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock_person_rounded, color: AppColors.gold, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Study Log Locked 🔒',
                                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'You have ${pendingGaps.length} unresolved study gap days. Tap to log reasons and unlock today\'s logging.',
                                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                        ],
                      ),
                    ),
                  ).animate().shake(delay: 300.ms, duration: 600.ms),
                ],
                const SizedBox(height: 16),

                // Quick stats grid (2x2 Layout)
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _QuickStat(
                            icon: Icons.local_fire_department_rounded,
                            iconColor: AppColors.gold,
                            value: '$streak',
                            label: 'Day streak',
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickStat(
                            icon: Icons.flip_rounded,
                            iconColor: AppColors.blue,
                            value: '$dueCount',
                            label: 'Due today',
                          ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickStat(
                            icon: Icons.hourglass_empty_rounded,
                            iconColor: AppColors.green,
                            value: '${totalHoursDevoted.toStringAsFixed(1)}h',
                            label: 'Hours Completed',
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickStat(
                            icon: Icons.check_circle_outline_rounded,
                            iconColor: AppColors.orange,
                            value: '${((profile.examMode == ExamMode.jpsc ? syllabus.jpscProgress : syllabus.upscProgress) * 100).toInt()}%',
                            label: 'Syllabus done',
                          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Revision due banner
                if (dueCount > 0)
                  GestureDetector(
                    onTap: () => context.go('/revision'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.orange.withOpacity(0.15), AppColors.goldSurface],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.orange.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.flip_rounded, color: AppColors.orange, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$dueCount topics due for revision',
                                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                Text('Tap to start your revision session',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                        ],
                      ),
                    ).animate().fadeIn(delay: 450.ms),
                  ),

                if (dueCount > 0) const SizedBox(height: 16),

                // Syllabus progress
                _SectionHeader('Syllabus Progress', onTap: () => context.go('/syllabus')),
                const SizedBox(height: 12),
                _SyllabusProgressCard(syllabus: syllabus, examMode: profile.examMode)
                    .animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
                const SizedBox(height: 24),

                // Recent sessions
                _SectionHeader('Recent Sessions', onTap: () => context.go('/analytics')),
                const SizedBox(height: 12),
                if (filteredSessions.isEmpty)
                  _EmptyState('No sessions yet. Log your first session!')
                else
                  ...filteredSessions.take(3).map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: SessionTile(session: s),
                  )).toList().animate(interval: 80.ms).fadeIn(delay: 550.ms).slideX(begin: 0.1),
               ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSessionSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text('Log Session', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ).animate().scale(delay: 800.ms),
    );
  }

  void _showSessionSheet(BuildContext context, WidgetRef ref) {
    final pendingGaps = ref.read(journeyProvider.notifier).pendingGapDays;
    if (pendingGaps.isNotEmpty) {
      GapResolverSheet.show(context, ref, pendingGaps);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SessionLogSheet(ref: ref),
    );
  }
}

class _TodayCard extends StatelessWidget {
  final double todayHours;
  final double goalHours;
  final int topicsToday;
  const _TodayCard({required this.todayHours, required this.goalHours, required this.topicsToday});

  @override
  Widget build(BuildContext context) {
    final progress = goalHours > 0 ? (todayHours / goalHours).clamp(0.0, 1.0) : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("Today's Progress",
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('${todayHours.toStringAsFixed(1)}h / ${goalHours.toInt()}h goal',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppColors.green : AppColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _TodayStat(Icons.schedule_rounded, '${todayHours.toStringAsFixed(1)}h', 'Studied'),
              _TodayStat(Icons.topic_rounded, '$topicsToday', 'Topics'),
              _TodayStat(Icons.percent_rounded, '${(progress * 100).toInt()}%', 'of Goal'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _TodayStat(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  const _QuickStat({required this.icon, required this.iconColor, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  const _SectionHeader(this.title, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const Spacer(),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Text('See all', style: GoogleFonts.inter(fontSize: 13, color: AppColors.gold)),
          ),
      ],
    );
  }
}

class _SyllabusProgressCard extends StatelessWidget {
  final SyllabusState syllabus;
  final ExamMode examMode;
  const _SyllabusProgressCard({required this.syllabus, required this.examMode});

  @override
  Widget build(BuildContext context) {
    final items = [
      if (examMode == ExamMode.upsc || examMode == ExamMode.both)
        ('UPSC', syllabus.upscProgress, AppColors.gold),
      if (examMode == ExamMode.jpsc || examMode == ExamMode.both)
        ('JPSC', syllabus.jpscProgress, AppColors.green),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: items.map((item) {
          final (name, progress, color) = item;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const Spacer(),
                    Text('${(progress * 100).toInt()}%',
                        style: GoogleFonts.inter(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  final _quotes = const [
    '"Success is the sum of small efforts, repeated day in and day out."',
    '"The secret of getting ahead is getting started."',
    '"An investment in knowledge pays the best interest."',
    '"Discipline is the bridge between goals and accomplishment."',
    '"Hard work beats talent when talent doesn\'t work hard."',
  ];

  const _QuoteCard();

  @override
  Widget build(BuildContext context) {
    final quote = _quotes[DateTime.now().day % _quotes.length];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.goldSurface, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.format_quote_rounded, color: AppColors.gold, size: 24),
          const SizedBox(height: 8),
          Text(quote,
              style: GoogleFonts.instrumentSerif(fontSize: 17, color: AppColors.textPrimary, height: 1.6)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(message,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
            textAlign: TextAlign.center),
      ),
    );
  }
}
