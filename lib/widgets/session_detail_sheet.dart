import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_colors.dart';
import '../models/study_session.dart' as ss;
import '../models/revision_item.dart';
import '../providers/revision_provider.dart';
import '../providers/syllabus_provider.dart';
import 'session_log_sheet.dart';

class SessionDetailSheet extends ConsumerWidget {
  final ss.StudySession session;

  const SessionDetailSheet({required this.session, super.key});

  static void show(BuildContext context, WidgetRef ref, ss.StudySession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SessionDetailSheet(session: session),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(revisionProvider);
    final revisionNotifier = ref.read(revisionProvider.notifier);
    final revisions = revisionNotifier.filteredState;

    // Get shift label and icon
    String shiftLabel = '';
    IconData shiftIcon = Icons.wb_sunny_rounded;
    Color shiftColor = AppColors.gold;

    if (session.shift == 'morning') {
      shiftLabel = 'Morning';
      shiftIcon = Icons.wb_twighlight;
      shiftColor = AppColors.gold;
    } else if (session.shift == 'afternoon') {
      shiftLabel = 'Afternoon';
      shiftIcon = Icons.wb_sunny_rounded;
      shiftColor = AppColors.orange;
    } else if (session.shift == 'evening') {
      shiftLabel = 'Evening';
      shiftIcon = Icons.nights_stay_rounded;
      shiftColor = AppColors.blue;
    } else if (session.shift == 'night') {
      shiftLabel = 'Night';
      shiftIcon = Icons.dark_mode_rounded;
      shiftColor = const Color(0xFFC77DFF);
    }

    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(session.date);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
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

                // Title Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.subjectName,
                            style: GoogleFonts.instrumentSerif(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            session.sectionName,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: AppColors.gold),
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
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const Divider(height: 32, color: AppColors.border),

                // Session Meta Grid
                Row(
                  children: [
                    Expanded(
                      child: _buildMetaCard(
                        icon: Icons.calendar_month_rounded,
                        label: 'Date & Time',
                        value: formattedDate,
                        subtext: DateFormat('hh:mm a').format(session.date),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetaCard(
                        icon: shiftIcon,
                        label: 'Study Shift',
                        value: shiftLabel,
                        valueColor: shiftColor,
                        subtext: '${session.durationHours.toStringAsFixed(1)} hours logged',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Notes Section if present
                if (session.notes != null && session.notes!.isNotEmpty) ...[
                  Text(
                    'Session Notes',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      session.notes!,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Topics Covered Section
                Text(
                  'Topics Covered & Forgetting Curves',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                if (session.topicsCovered.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    child: Text(
                      'No specific topics linked to this session.',
                      style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                    ),
                  )
                else
                  ...session.topicsCovered.map((topicTitle) {
                    // Try to find if a revision item exists for this topic
                    final revisionItem = revisions.firstWhere(
                      (r) => r.topicTitle.toLowerCase() == topicTitle.toLowerCase(),
                      orElse: () => RevisionItem(
                        id: '',
                        topicId: '',
                        topicTitle: topicTitle,
                        subjectName: session.subjectName,
                        sectionName: session.sectionName,
                        subjectId: session.subjectId,
                        examType: session.examType,
                        nextDueDate: DateTime.now(),
                      ),
                    );

                    final hasActiveRevision = revisionItem.id.isNotEmpty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  topicTitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              if (hasActiveRevision)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.greenSurface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Active Revision (${revisionItem.revisionCount} Done)',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.green,
                                    ),
                                  ),
                                )
                              else
                                TextButton.icon(
                                  onPressed: () async {
                                    // Let's find topicId from syllabus if possible or just use a generated/mock ID
                                    String targetTopicId = const Uuid().v4();
                                    try {
                                      final subjects = ref.read(syllabusProvider).sectionsFor(session.examType).expand((s) => s.subjects);
                                      final actualSubject = subjects.firstWhere((sub) => sub.id == session.subjectId);
                                      final actualTopic = actualSubject.topics.firstWhere((t) => t.title.toLowerCase() == topicTitle.toLowerCase());
                                      targetTopicId = actualTopic.id;
                                    } catch (_) {}

                                    final newItem = RevisionItem(
                                      id: const Uuid().v4(),
                                      topicId: targetTopicId,
                                      topicTitle: topicTitle,
                                      subjectName: session.subjectName,
                                      sectionName: session.sectionName,
                                      subjectId: session.subjectId,
                                      examType: session.examType,
                                      nextDueDate: DateTime.now().add(const Duration(days: 1)),
                                    );
                                    await revisionNotifier.addRevisionItem(newItem);
                                  },
                                  icon: const Icon(Icons.add_alarm_rounded, size: 12, color: AppColors.gold),
                                  label: Text(
                                    'Schedule',
                                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w600),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Forgetting Curve Schedule (calculated from study date):',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildForgettingCurveTimelineForSession(session.date, revisionItem, hasActiveRevision),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetaCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
    Color valueColor = AppColors.textPrimary,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildForgettingCurveTimelineForSession(DateTime sessionDate, RevisionItem item, bool isActive) {
    final intervals = [
      (1, '1st Review', 1),
      (2, '2nd Review', 3),
      (3, '3rd Review', 8),
      (4, '4th Review', 20),
      (5, '5th Review', 50),
    ];

    return Column(
      children: intervals.map((i) {
        final stepNum = i.$1;
        final stepTitle = i.$2;
        final delayDays = i.$3;
        final targetDate = sessionDate.add(Duration(days: delayDays));
        final dateStr = DateFormat('dd MMM yyyy').format(targetDate);

        // Status determinations
        bool isDone = false;
        bool isCurrent = false;

        if (isActive) {
          if (item.revisionCount >= stepNum) {
            isDone = true;
          } else if (item.revisionCount == stepNum - 1) {
            isCurrent = true;
          }
        }

        Color stepColor = AppColors.textMuted;
        IconData stepIcon = Icons.radio_button_unchecked_rounded;

        if (isDone) {
          stepColor = AppColors.green;
          stepIcon = Icons.check_circle_rounded;
        } else if (isCurrent) {
          stepColor = AppColors.gold;
          stepIcon = Icons.pending_rounded;
        }

        final now = DateTime.now();
        final daysDiff = targetDate.difference(DateTime(now.year, now.month, now.day)).inDays;
        String relativeDays = '';
        if (daysDiff == 0) {
          relativeDays = 'Today';
        } else if (daysDiff == 1) {
          relativeDays = 'Tomorrow';
        } else if (daysDiff == -1) {
          relativeDays = 'Yesterday';
        } else if (daysDiff > 1) {
          relativeDays = 'In $daysDiff days';
        } else {
          relativeDays = '${-daysDiff} days ago';
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left Timeline nodes
              Column(
                children: [
                  Icon(stepIcon, size: 16, color: stepColor),
                  if (stepNum < 5)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isDone ? AppColors.green.withValues(alpha: 0.5) : AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Right contents
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$stepTitle (Day $delayDays)',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                              color: isCurrent ? AppColors.gold : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '$dateStr • $relativeDays',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (isDone)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.greenSurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Completed',
                            style: GoogleFonts.inter(fontSize: 9, color: AppColors.green, fontWeight: FontWeight.bold),
                          ),
                        )
                      else if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.goldSurface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Next Up',
                            style: GoogleFonts.inter(fontSize: 9, color: AppColors.gold, fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        Text(
                          'Scheduled',
                          style: GoogleFonts.inter(fontSize: 9.5, color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
