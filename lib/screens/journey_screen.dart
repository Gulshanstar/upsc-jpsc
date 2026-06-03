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
import '../models/user_profile.dart';
import '../widgets/heatmap_calendar.dart';

class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    ref.watch(journeyProvider);
    final journalEntries = ref.read(journeyProvider.notifier).filteredState;
    final journeyNotifier = ref.read(journeyProvider.notifier);

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
              'Journey Journal',
              style: GoogleFonts.instrumentSerif(fontSize: 24),
            ),
            backgroundColor: AppColors.background,
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_comment_rounded, color: AppColors.gold),
                tooltip: "Write today's journal",
                onPressed: () => _showEditEntrySheet(context, ref, DateTime.now()),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Heatmap Calendar
                HeatmapCalendar(
                  datasets: journeyNotifier.heatmapData,
                  onDayTap: (date, hours) => _showDayDetailSheet(context, ref, date),
                ).animate().fadeIn(duration: 400.ms),
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
                  Container(
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
                            'You missed ${journeyNotifier.missedDaysThisMonth} days of study this month. Keep up the revision consistency to retain what you learned!',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Log Entries',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showEditEntrySheet(context, ref, DateTime.now()),
                      child: Text(
                        'Log Today',
                        style: GoogleFonts.inter(fontSize: 13, color: AppColors.gold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (journalEntries.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    child: Text(
                      'No journal logs yet. Start typing your logs today!',
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                    ),
                  )
                else ...[
                  // If not expanded, show only 5 items. If expanded, show everything.
                  ...(_isExpanded ? journalEntries : journalEntries.take(5)).map((entry) {
                    return _buildJournalCard(context, ref, entry);
                  }).toList().animate(interval: 40.ms).fadeIn().slideY(begin: 0.05),

                  // Collapse/Expand toggle wrapper button
                  if (journalEntries.length > 5) ...[
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: entry.didStudy
                        ? AppColors.green.withValues(alpha: 0.12)
                        : AppColors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    entry.didStudy ? 'Studied' : 'Missed',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: entry.didStudy ? AppColors.green : AppColors.red,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (entry.didStudy) ...[
              Row(
                children: [
                  const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.hoursStudied.toStringAsFixed(1)} hrs',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.topic_rounded, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(
                    '${entry.topicsCount} topics covered',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
              if (entry.note != null && entry.note!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  entry.note!,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.cancel_outlined, size: 13, color: AppColors.red),
                  const SizedBox(width: 4),
                  Text(
                    'Reason: ${entry.missedReason ?? "Unspecified"}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (entry.note != null && entry.note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  entry.note!,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showDayDetailSheet(BuildContext context, WidgetRef ref, DateTime date) {
    final entry = ref.read(journeyProvider.notifier).entryForDay(date);
    final formattedDate = DateFormat('MMMM d, yyyy').format(date);
    final moodText = entry != null
        ? const ['Frustrated', 'Neutral', 'Good', 'Focused', 'Outstanding'][entry.mood.clamp(1, 5) - 1]
        : 'Neutral';

    showModalBottomSheet(
      context: context,
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
              if (entry == null) ...[
                Text(
                  'No journal logged for this day.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditEntrySheet(context, ref, date);
                    },
                    child: Text('Create Log Entry', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: entry.didStudy
                            ? AppColors.green.withValues(alpha: 0.15)
                            : AppColors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        entry.didStudy ? 'Studied' : 'Missed Day',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: entry.didStudy ? AppColors.green : AppColors.red,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Focus: $moodText',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (entry.didStudy) ...[
                  _buildDetailRow(Icons.schedule_rounded, 'Hours studied', '${entry.hoursStudied.toStringAsFixed(1)} hrs'),
                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.topic_rounded, 'Topics covered', '${entry.topicsCount} topics'),
                ] else ...[
                  _buildDetailRow(Icons.cancel_outlined, 'Missed reason', entry.missedReason ?? 'Unspecified', color: AppColors.red),
                ],
                
                // Show physical exercise tracker in daily details summary
                if (ref.read(userProfileProvider).dailyExerciseType != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.directions_run_rounded,
                    ref.read(userProfileProvider).dailyExerciseType!,
                    entry.didExercise == true
                        ? (entry.exerciseNote != null && entry.exerciseNote!.isNotEmpty
                            ? 'Completed (${entry.exerciseNote})'
                            : 'Completed ✅')
                        : 'Skipped ❌',
                    color: entry.didExercise == true ? AppColors.green : AppColors.textMuted,
                  ),
                ],

                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Journal Note',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.note!,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showEditEntrySheet(context, ref, date);
                        },
                        child: Text('Edit Log', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
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
  
  // Exercise tracking state variables
  bool _didExercise = false;
  final _exerciseNoteController = TextEditingController();

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
      if (_reasons.contains(entry.missedReason)) {
        _missedReason = entry.missedReason!;
      } else if (entry.missedReason != null) {
        _missedReason = 'Other';
      }
      _noteController.text = entry.note ?? '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _exerciseNoteController.dispose();
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
            Row(
              children: [
                _buildToggleButton(true, 'Yes, I studied', AppColors.green),
                const SizedBox(width: 12),
                _buildToggleButton(false, 'No, I missed it', AppColors.red),
              ],
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
              ],
            ],

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
                onPressed: _saveJournalEntry,
                child: Text('Save Log Entry', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(bool val, String label, Color activeColor) {
    final isSelected = _didStudy == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _didStudy = val),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.15) : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? activeColor : AppColors.textSecondary,
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
    );

    await widget.ref.read(journeyProvider.notifier).upsertEntry(entry);
    Navigator.pop(context);
  }
}
