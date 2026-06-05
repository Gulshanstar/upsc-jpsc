import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_colors.dart';
import '../models/journal_entry.dart';
import '../providers/journey_provider.dart';
import '../providers/user_provider.dart';
import '../providers/session_provider.dart';
import '../models/user_profile.dart';
import '../widgets/heatmap_calendar.dart';
import '../widgets/gap_resolver_sheet.dart';
import '../widgets/session_log_sheet.dart';
import '../widgets/fitness_log_sheet.dart';

class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

enum LogFilter { all, studyCompleted, fitnessCompleted, studyMissing, fitnessMissing, nothingMissing }

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  bool _isExpanded = false;
  LogFilter _selectedFilter = LogFilter.all;

  @override
  Widget build(BuildContext context) {
    ref.watch(journeyProvider);
    final sessions = ref.watch(sessionProvider);
    final journalEntries = ref.read(journeyProvider.notifier).filteredState;
    final journeyNotifier = ref.read(journeyProvider.notifier);
    final sessionNotifier = ref.read(sessionProvider.notifier);

    final studySessionDays = sessions.map((s) => DateTime(s.date.year, s.date.month, s.date.day)).toSet();
    final allCount = journalEntries.length;
    final studyCompletedCount = journalEntries.where((e) {
      final dateOnly = DateTime(e.date.year, e.date.month, e.date.day);
      return e.didStudy || studySessionDays.contains(dateOnly);
    }).length;
    final fitnessCompletedCount = journalEntries.where((e) => e.didExercise == true).length;
    final studyMissingCount = journalEntries.where((e) {
      final dateOnly = DateTime(e.date.year, e.date.month, e.date.day);
      return !e.didStudy && !studySessionDays.contains(dateOnly);
    }).length;
    final fitnessMissingCount = journalEntries.where((e) => e.didExercise == false).length;
    final nothingMissingCount = journalEntries.where((e) {
      final dateOnly = DateTime(e.date.year, e.date.month, e.date.day);
      final hasStudied = e.didStudy || studySessionDays.contains(dateOnly);
      final hasFitness = e.didExercise != false;
      return hasStudied && hasFitness;
    }).length;

    final filteredEntries = journalEntries.where((e) {
      if (_selectedFilter == LogFilter.studyCompleted) {
        final dateOnly = DateTime(e.date.year, e.date.month, e.date.day);
        return e.didStudy || studySessionDays.contains(dateOnly);
      } else if (_selectedFilter == LogFilter.fitnessCompleted) {
        return e.didExercise == true;
      } else if (_selectedFilter == LogFilter.studyMissing) {
        final dateOnly = DateTime(e.date.year, e.date.month, e.date.day);
        return !e.didStudy && !studySessionDays.contains(dateOnly);
      } else if (_selectedFilter == LogFilter.fitnessMissing) {
        return e.didExercise == false;
      } else if (_selectedFilter == LogFilter.nothingMissing) {
        final dateOnly = DateTime(e.date.year, e.date.month, e.date.day);
        final hasStudied = e.didStudy || studySessionDays.contains(dateOnly);
        final hasFitness = e.didExercise != false;
        return hasStudied && hasFitness;
      }
      return true;
    }).toList();

    final currentStreak = journeyNotifier.currentStreak;
    final longestStreak = journeyNotifier.longestStreak;
    final totalStudyDays = journeyNotifier.totalStudyDays;
    final avgHours = journeyNotifier.avgHoursPerStudyDay;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              'Activity Tracker',
              style: GoogleFonts.instrumentSerif(fontSize: 24),
            ),
            backgroundColor: AppColors.background,
            floating: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Heatmap Calendar
                HeatmapCalendar(
                  datasets: sessionNotifier.heatmapData,
                  onDayTap: (date, hours) {
                    final profile = ref.read(userProfileProvider);
                    final startOfPrep = profile.preparationStartDate != null
                        ? DateTime(profile.preparationStartDate!.year, profile.preparationStartDate!.month, profile.preparationStartDate!.day)
                        : null;
                    final now = DateTime.now();
                    final todayStart = DateTime(now.year, now.month, now.day);
                    
                    if (startOfPrep != null && date.isBefore(startOfPrep)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Cannot log or view activities before your preparation start date (${DateFormat('dd/MM/yyyy').format(startOfPrep)}).'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    if (date.isAfter(todayStart)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cannot log or view activities for future dates.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      return;
                    }
                    _showDayDetailSheet(context, ref, date);
                  },
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 12),

                // Independent Fitness Button
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => FitnessLogSheet(ref: ref),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green.withValues(alpha: 0.12),
                          foregroundColor: AppColors.green,
                          side: const BorderSide(color: AppColors.green, width: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.directions_run_rounded, size: 18),
                        label: Text(
                          'Log Fitness / Exercise',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 20),

                // Stats row
                Row(
                  children: [
                    Expanded(
                      child: _buildJourneyStatCard(
                        'Streak',
                        '$currentStreak',
                        'Longest: $longestStreak',
                        AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildJourneyStatCard(
                        'Study Days',
                        '$totalStudyDays',
                        'Total Logged: ${journalEntries.length}',
                        AppColors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildJourneyStatCard(
                        'Avg. Study',
                        '${avgHours.toStringAsFixed(1)}h',
                        'Per Study Day',
                        AppColors.blue,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
                const SizedBox(height: 28),

                // Gap analysis or advice panel
                if (journeyNotifier.missedDaysThisMonth > 0)
                  GestureDetector(
                    onTap: () {
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final studySessionDays = sessions.map((s) => DateTime(s.date.year, s.date.month, s.date.day)).toSet();
                      final missedEntries = journalEntries.where((e) {
                        final dateOnly = DateTime(e.date.year, e.date.month, e.date.day);
                        return e.date.year == now.year &&
                            e.date.month == now.month &&
                            dateOnly.isBefore(today) &&
                            !e.didStudy &&
                            !studySessionDays.contains(dateOnly);
                      }).toList()
                        ..sort((a, b) => b.date.compareTo(a.date));

                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: AppColors.surface,
                            title: Text(
                              'Missed Study Dates',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: missedEntries.length,
                                itemBuilder: (context, index) {
                                  final entry = missedEntries[index];
                                  final dateStr = DateFormat('EEEE, dd MMMM yyyy').format(entry.date);
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.cancel_rounded, color: AppColors.red, size: 20),
                                    title: Text(
                                      dateStr,
                                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                                    ),
                                    subtitle: Text(
                                      'Reason: ${entry.missedReason ?? "Unspecified"}',
                                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  );
                                },
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Dismiss',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.gold),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: AppColors.red, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You missed ${journeyNotifier.missedDaysThisMonth} days of study this month. Keep up the revision consistency to retain what you learned! (Tap to see dates)',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 28),

                 Row(
                  children: [
                    Text(
                      'Recent Log Entries',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Premium Filter Tab Chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterChip(LogFilter.all, 'All', allCount),
                    _buildFilterChip(LogFilter.studyCompleted, 'Study Completed', studyCompletedCount),
                    _buildFilterChip(LogFilter.fitnessCompleted, 'Fitness Completed', fitnessCompletedCount),
                    _buildFilterChip(LogFilter.studyMissing, 'Study Missing', studyMissingCount),
                    _buildFilterChip(LogFilter.fitnessMissing, 'Fitness Missing', fitnessMissingCount),
                    _buildFilterChip(LogFilter.nothingMissing, 'Nothing Missing', nothingMissingCount),
                  ],
                ),
                const SizedBox(height: 16),

                if (filteredEntries.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: Text(
                      'No matching logs found.',
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                    ),
                  )
                else ...[
                  // If not expanded, show only 5 items. If expanded, show everything.
                  ...(_isExpanded ? filteredEntries : filteredEntries.take(5)).map((entry) {
                    return _buildJournalCard(context, ref, entry);
                  }).toList().animate(interval: 40.ms).fadeIn().slideY(begin: 0.05),

                  // Collapse/Expand toggle wrapper button
                  if (filteredEntries.length > 5) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: _isExpanded ? AppColors.surfaceElevated : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isExpanded 
                                    ? 'Show Less' 
                                    : 'View All Logs (${journalEntries.length})',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.gold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _isExpanded 
                                    ? Icons.keyboard_arrow_up_rounded 
                                    : Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: AppColors.gold,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJourneyStatCard(String label, String value, String subtext, Color color) {
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
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalCard(BuildContext context, WidgetRef ref, JournalEntry entry) {
    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(entry.date);
    final moodIcon = const [
      Icons.sentiment_very_dissatisfied_rounded,
      Icons.sentiment_dissatisfied_rounded,
      Icons.sentiment_neutral_rounded,
      Icons.sentiment_satisfied_rounded,
      Icons.sentiment_very_satisfied_rounded,
    ][entry.mood.clamp(1, 5) - 1];
    
    final moodColor = const [
      AppColors.red,
      AppColors.orange,
      AppColors.blue,
      AppColors.green,
      AppColors.gold,
    ][entry.mood.clamp(1, 5) - 1];

    final sessions = ref.read(sessionProvider);
    final studySessionDays = sessions.map((s) => DateTime(s.date.year, s.date.month, s.date.day)).toSet();
    final dateOnly = DateTime(entry.date.year, entry.date.month, entry.date.day);
    final hasStudied = entry.didStudy || studySessionDays.contains(dateOnly);

    final daySessions = sessions.where((s) =>
        s.date.year == entry.date.year &&
        s.date.month == entry.date.month &&
        s.date.day == entry.date.day).toList();
    final actualHours = daySessions.fold<double>(0.0, (sum, s) => sum + s.durationHours);
    final actualTopics = daySessions.fold<int>(0, (sum, s) => sum + s.topicsCovered.length);

    final displayHours = hasStudied
        ? (actualHours > 0 ? actualHours : entry.hoursStudied)
        : 0.0;
    final displayTopics = hasStudied
        ? (actualTopics > 0 ? actualTopics : entry.topicsCount)
        : 0;

    return GestureDetector(
      onTap: () => _showDayDetailSheet(context, ref, entry.date),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(
                  moodIcon,
                  color: moodColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                (() {
                  final bool showFitnessBadge = _selectedFilter == LogFilter.fitnessMissing || _selectedFilter == LogFilter.fitnessCompleted;
                  final String badgeText = showFitnessBadge
                      ? (entry.didExercise == true ? 'Fitness Done' : 'Fitness Missed')
                      : (hasStudied ? 'Studied' : 'Missed');
                  final Color badgeColor = showFitnessBadge
                      ? (entry.didExercise == true ? AppColors.green : AppColors.red)
                      : (hasStudied ? AppColors.green : AppColors.red);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeText,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeColor,
                      ),
                    ),
                  );
                })(),
              ],
            ),
            const SizedBox(height: 12),
            // Study Status Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  hasStudied ? Icons.menu_book_rounded : Icons.cancel_outlined,
                  size: 13,
                  color: hasStudied ? AppColors.gold : AppColors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasStudied
                        ? 'Study: ${displayHours.toStringAsFixed(1)} hrs ($displayTopics topics covered)'
                        : 'Study Missed: ${entry.missedReason ?? "Unspecified"}',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: hasStudied ? FontWeight.w500 : FontWeight.w600,
                      color: hasStudied ? AppColors.textSecondary : AppColors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Fitness Status Row
            if (entry.didExercise != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    entry.didExercise == true ? Icons.directions_run_rounded : Icons.cancel_outlined,
                    size: 13,
                    color: entry.didExercise == true ? AppColors.green : AppColors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.didExercise == true
                          ? 'Fitness: Completed ${_extractActivity(entry.exerciseNote, "Exercise")}'
                          : 'Fitness Missed: ${entry.missedExerciseReason ?? "Unspecified"}',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: entry.didExercise == true ? FontWeight.w500 : FontWeight.w600,
                        color: entry.didExercise == true ? AppColors.textSecondary : AppColors.red,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (entry.note != null && entry.note!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                entry.note!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDayDetailSheet(BuildContext context, WidgetRef ref, DateTime date) {
    final entry = ref.read(journeyProvider.notifier).entryForDay(date);
    final formattedDate = DateFormat('MMMM d, yyyy').format(date);

    final sessions = ref.read(sessionProvider).where((s) =>
        s.date.year == date.year &&
        s.date.month == date.month &&
        s.date.day == date.day).toList();

    final profile = ref.read(userProfileProvider);
    final exerciseType = profile.dailyExerciseType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedDate,
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 24,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Logged Study Sessions Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Study Sessions',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Builder(
                      builder: (context) {
                        final isAccountable = entry != null && !entry.didStudy && entry.missedReason != null;
                        return TextButton.icon(
                          onPressed: isAccountable ? null : () {
                            Navigator.pop(context);
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => SessionLogSheet(ref: ref, initialDate: date),
                            );
                          },
                          icon: Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: isAccountable ? AppColors.textMuted : AppColors.gold,
                          ),
                          label: Text(
                            'Log Session',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: isAccountable ? AppColors.textMuted : AppColors.gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (sessions.isEmpty)
                  Text(
                    'No study sessions logged for this day.',
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  )
                else
                  Column(
                    children: sessions.map((session) {
                      final durationHours = session.durationMinutes / 60.0;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        session.subjectName,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${durationHours.toStringAsFixed(1)}h',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.gold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (session.topicsCovered.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      session.topicsCovered.join(', '),
                                      style: GoogleFonts.inter(
                                        fontSize: 11.5,
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.gold),
                              onPressed: () {
                                Navigator.pop(context);
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => SessionLogSheet(
                                    ref: ref,
                                    editingSession: session,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: AppColors.surface,
                                    title: Text('Delete Session?', style: GoogleFonts.instrumentSerif(fontSize: 20)),
                                    content: Text('Are you sure you want to delete this study session?', style: GoogleFonts.inter(fontSize: 13)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted)),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: Text('Delete', style: GoogleFonts.inter(color: AppColors.red, fontWeight: FontWeight.w600)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ref.read(sessionProvider.notifier).deleteSession(session.id);
                                  Navigator.pop(context); // close details sheet
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Study session deleted successfully.'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                if (entry != null && !entry.didStudy && sessions.isEmpty) ...[
                  const Divider(height: 32, color: AppColors.border),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Accountability Log',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          GapResolverSheet.show(context, ref, [date]);
                        },
                        icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.gold),
                        label: Text(
                          'Edit Reason',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.red.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.red.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.cancel_outlined, size: 16, color: AppColors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Study Missed: ${entry.missedReason ?? "Unspecified"}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (entry.note != null && entry.note!.isNotEmpty && !entry.note!.startsWith('Missed study day reason:')) ...[
                          const SizedBox(height: 8),
                          Text(
                            entry.note!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const Divider(height: 32, color: AppColors.border),

                // Fitness Section
                if (exerciseType != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$exerciseType Log',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => FitnessLogSheet(ref: ref, initialDate: date),
                          );
                        },
                        icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.green),
                        label: Text(
                          'Log $exerciseType',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (entry == null || entry.didExercise == null)
                    Text(
                      'No fitness logged for this day.',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  else ...[
                    Builder(
                      builder: (context) {
                        final activityName = _extractActivity(entry.exerciseNote, exerciseType);
                        final noteContent = _extractNoteContent(entry.exerciseNote);
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    entry.didExercise == true ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                    size: 16,
                                    color: entry.didExercise == true ? AppColors.green : AppColors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    entry.didExercise == true ? '$activityName - Completed' : 'Skipped',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: entry.didExercise == true ? AppColors.green : AppColors.red,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.green),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        backgroundColor: Colors.transparent,
                                        builder: (_) => FitnessLogSheet(ref: ref, initialDate: date),
                                      );
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              if (entry.didExercise == true && noteContent.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  noteContent,
                                  style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
                                ),
                              ] else if (entry.didExercise == false && entry.missedExerciseReason != null && entry.missedExerciseReason!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Reason: ${entry.missedExerciseReason!}',
                                  style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        );
                      }
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _extractActivity(String? note, String defaultActivity) {
    if (note == null) return defaultActivity;
    if (note.startsWith('[') && note.contains(']')) {
      return note.substring(1, note.indexOf(']'));
    }
    return defaultActivity;
  }

  String _extractNoteContent(String? note) {
    if (note == null) return '';
    if (note.startsWith('[') && note.contains(']')) {
      final end = note.indexOf(']');
      if (end + 1 < note.length) {
        return note.substring(end + 1).trim();
      }
      return '';
    }
    return note;
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(LogFilter filter, String label, int count) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldSurface : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.gold : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.gold.withValues(alpha: 0.15) : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.gold : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEntrySheet(BuildContext context, WidgetRef ref, DateTime date) {
    final entry = ref.read(journeyProvider.notifier).entryForDay(date);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _JournalEditSheet(ref: ref, date: date, initialEntry: entry),
    );
  }
}

class _JournalEditSheet extends StatefulWidget {
  final WidgetRef ref;
  final DateTime date;
  final JournalEntry? initialEntry;

  const _JournalEditSheet({
    required this.ref,
    required this.date,
    this.initialEntry,
  });

  @override
  State<_JournalEditSheet> createState() => _JournalEditSheetState();
}

class _JournalEditSheetState extends State<_JournalEditSheet> {
  bool _didStudy = true;
  double _hours = 4.0;
  int _topics = 2;
  int _mood = 3;
  String _missedReason = 'Personal work';
  final _noteController = TextEditingController();
  final _goalController = TextEditingController();
  
  // Exercise tracking state variables
  bool _didExercise = false;
  final _exerciseNoteController = TextEditingController();
  String _missedExerciseReason = 'Rest day';
  final _customExerciseReasonController = TextEditingController();
  final List<String> _exerciseReasons = [
    'Rest day',
    'Tired / Lack of energy',
    'Injured / Soreness',
    'Weather conditions',
    'Busy studying / Lack of time',
    'Other'
  ];

  final List<String> _reasons = ['Personal work', 'Not feeling well', 'Family event', 'Burnout', 'Travel', 'Other'];

  @override
  void initState() {
    super.initState();
    if (widget.initialEntry != null) {
      final entry = widget.initialEntry!;
      _didStudy = entry.didStudy;
      _hours = entry.hoursStudied;
      _topics = entry.topicsCount;
      _mood = entry.mood;
      _didExercise = entry.didExercise ?? false;
      _exerciseNoteController.text = entry.exerciseNote ?? '';
      if (_exerciseReasons.contains(entry.missedExerciseReason)) {
        _missedExerciseReason = entry.missedExerciseReason!;
      } else if (entry.missedExerciseReason != null) {
        _missedExerciseReason = 'Other';
        _customExerciseReasonController.text = entry.missedExerciseReason!;
      }
      if (_reasons.contains(entry.missedReason)) {
        _missedReason = entry.missedReason!;
      } else if (entry.missedReason != null) {
        _missedReason = 'Other';
      }
      _noteController.text = entry.note ?? '';
      _goalController.text = entry.goal ?? '';
    } else {
      // New entry: aggregate from sessions on widget.date
      final sessions = widget.ref.read(sessionProvider);
      final daySessions = sessions.where((s) =>
          s.date.year == widget.date.year &&
          s.date.month == widget.date.month &&
          s.date.day == widget.date.day);
      if (daySessions.isNotEmpty) {
        _didStudy = true;
        final totalHours = daySessions.fold<double>(0.0, (sum, s) => sum + (s.durationMinutes / 60.0));
        _hours = totalHours > 16.0 ? 16.0 : double.parse(totalHours.toStringAsFixed(1));
        _topics = daySessions.fold<int>(0, (sum, s) => sum + s.topicsCovered.length);
      } else {
        final today = DateTime.now();
        final isToday = widget.date.year == today.year &&
            widget.date.month == today.month &&
            widget.date.day == today.day;
        _didStudy = isToday;
        _hours = isToday ? 4.0 : 0.0;
        _topics = isToday ? 2 : 0;
      }
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _exerciseNoteController.dispose();
    _customExerciseReasonController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMMM d, yyyy').format(widget.date);
    final profile = widget.ref.read(userProfileProvider);
    final exerciseType = profile.dailyExerciseType;

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
        top: 24,
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
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.initialEntry != null ? 'Edit Log Entry' : 'Log Daily Progress',
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 24,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  formattedDate,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Did Study Toggle
            Text(
              'Did you study on this day?',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final hasAccountability = widget.initialEntry != null && 
                    !widget.initialEntry!.didStudy && 
                    widget.initialEntry!.missedReason != null;
                return Row(
                  children: [
                    _buildToggleButton(true, 'Yes, I studied', AppColors.green, disabled: hasAccountability),
                    const SizedBox(width: 12),
                    _buildToggleButton(false, 'No, I missed it', AppColors.red, disabled: hasAccountability),
                  ],
                );
              }
            ),
            const SizedBox(height: 20),

            if (_didStudy) ...[
              // Hours Studied
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hours Studied',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  ),
                  Text(
                    '${_hours.toStringAsFixed(1)} hrs',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Slider(
                min: 0,
                max: 16,
                divisions: 32,
                value: _hours,
                activeColor: AppColors.gold,
                inactiveColor: AppColors.surfaceElevated,
                onChanged: (val) => setState(() => _hours = val),
              ),
              const SizedBox(height: 16),

              // Topics Covered Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Topics Covered Count',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.textSecondary),
                        onPressed: _topics > 0 ? () => setState(() => _topics--) : null,
                      ),
                      Text(
                        '$_topics',
                        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.textSecondary),
                        onPressed: () => setState(() => _topics++),
                      ),
                    ],
                  ),
                ],
              ),
            ] else ...[
              // Reason for missing
              Text(
                'Reason for missing',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _missedReason,
                    dropdownColor: AppColors.surface,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                    items: _reasons.map((r) {
                      return DropdownMenuItem<String>(
                        value: r,
                        child: Text(
                          r,
                          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _missedReason = val);
                    },
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Mood
            Text(
              'How was your focus/mood today?',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(5, (index) {
                final score = index + 1;
                final icon = const [
                  Icons.sentiment_very_dissatisfied_rounded,
                  Icons.sentiment_dissatisfied_rounded,
                  Icons.sentiment_neutral_rounded,
                  Icons.sentiment_satisfied_rounded,
                  Icons.sentiment_very_satisfied_rounded,
                ][index];
                final iconColor = const [
                  AppColors.red,
                  AppColors.orange,
                  AppColors.blue,
                  AppColors.green,
                  AppColors.gold,
                ][index];
                final isSelected = _mood == score;
                return GestureDetector(
                  onTap: () => setState(() => _mood = score),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? iconColor.withValues(alpha: 0.12)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? iconColor : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: isSelected ? iconColor : AppColors.textMuted,
                      size: 26,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Exercise Section
            if (exerciseType != null) ...[
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Track Daily $exerciseType',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Did you complete your daily $exerciseType session?',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _didExercise,
                    activeColor: AppColors.gold,
                    onChanged: (val) {
                      setState(() {
                        _didExercise = val;
                      });
                    },
                  ),
                ],
              ),
              if (_didExercise) ...[
                const SizedBox(height: 10),
                TextField(
                  controller: _exerciseNoteController,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g. Completed 30 mins, feeling fresh...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                  'Reason for skipping $exerciseType',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _missedExerciseReason,
                      dropdownColor: AppColors.surface,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                      items: _exerciseReasons.map((r) {
                        return DropdownMenuItem<String>(
                          value: r,
                          child: Text(
                            r,
                            style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _missedExerciseReason = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                if (_missedExerciseReason == 'Other') ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _customExerciseReasonController,
                    style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Specify reason...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                ],
              ],
            ],

            const SizedBox(height: 20),
            Text(
              'Goal / Thought of the Day',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _goalController,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'e.g. Complete GS-1 physical geography, maintain focus...',
              ),
            ),

            const SizedBox(height: 20),
            Text(
              'Journal Note',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Share how the day went, hurdles faced, or thoughts...',
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (() {
                  final hasExerciseEnabled = exerciseType != null;
                  if (hasExerciseEnabled && !_didExercise) {
                    if (_missedExerciseReason == 'Other' && _customExerciseReasonController.text.trim().isEmpty) {
                      return null;
                    }
                  }
                  return _saveJournalEntry;
                })(),
                child: Text('Save Log Entry', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(bool val, String label, Color activeColor, {bool disabled = false}) {
    final isSelected = _didStudy == val;
    return Expanded(
      child: GestureDetector(
        onTap: disabled ? null : () => setState(() => _didStudy = val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? (disabled ? AppColors.border.withValues(alpha: 0.2) : activeColor.withValues(alpha: 0.15))
                : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected 
                  ? (disabled ? AppColors.textMuted : activeColor)
                  : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected 
                  ? (disabled ? AppColors.textMuted : activeColor)
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  void _saveJournalEntry() async {
    final profile = widget.ref.read(userProfileProvider);
    final isExerciseEnabled = profile.dailyExerciseType != null;

    final entry = JournalEntry(
      id: widget.initialEntry?.id ?? const Uuid().v4(),
      date: DateTime(widget.date.year, widget.date.month, widget.date.day),
      didStudy: _didStudy,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      hoursStudied: _didStudy ? _hours : 0,
      topicsCount: _didStudy ? _topics : 0,
      mood: _mood,
      missedReason: !_didStudy ? _missedReason : null,
      didExercise: isExerciseEnabled ? _didExercise : null,
      exerciseNote: (isExerciseEnabled && _didExercise && _exerciseNoteController.text.trim().isNotEmpty)
          ? _exerciseNoteController.text.trim()
          : null,
      missedExerciseReason: (isExerciseEnabled && !_didExercise)
          ? (_missedExerciseReason == 'Other'
              ? _customExerciseReasonController.text.trim()
              : _missedExerciseReason)
          : null,
      goal: _goalController.text.trim().isNotEmpty ? _goalController.text.trim() : null,
    );

    await widget.ref.read(journeyProvider.notifier).upsertEntry(entry);
    Navigator.pop(context);
  }
}
