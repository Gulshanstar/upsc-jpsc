import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../providers/journey_provider.dart';
import '../providers/session_provider.dart';

class HeatmapCalendar extends ConsumerStatefulWidget {
  final Map<DateTime, double> datasets;
  final Function(DateTime, double)? onDayTap;

  const HeatmapCalendar({
    required this.datasets,
    this.onDayTap,
    super.key,
  });

  @override
  ConsumerState<HeatmapCalendar> createState() => _HeatmapCalendarState();
}

class _HeatmapCalendarState extends ConsumerState<HeatmapCalendar> {
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedMonth = DateTime(now.year, now.month, 1);
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;

    // Days to show before the 1st of the month (Monday-start alignment)
    // weekday is 1 for Mon, 7 for Sun. So weekday - 1 is the number of empty cells
    final leadDays = firstDayOfMonth.weekday - 1;

    final List<DateTime?> calendarDays = [];
    for (int i = 0; i < leadDays; i++) {
      calendarDays.add(null);
    }
    for (int d = 1; d <= daysInMonth; d++) {
      calendarDays.add(DateTime(_focusedMonth.year, _focusedMonth.month, d));
    }

    final monthName = DateFormat('MMMM yyyy').format(_focusedMonth);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left_rounded, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                monthName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Weekday headers
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return Center(
                child: Text(
                  day,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Calendar Grid
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

              final normalizedDay = DateTime(day.year, day.month, day.day);
              final hours = widget.datasets[normalizedDay] ?? 0.0;
              final isToday = normalizedDay == today;
              final color = _getCellColor(hours);

              // Check if studied or completed exercise
              final sessions = ref.watch(sessionProvider);
              final hasStudied = sessions.any((s) =>
                  s.date.year == day.year &&
                  s.date.month == day.month &&
                  s.date.day == day.day);

              final journalEntries = ref.watch(journeyProvider);
              bool hasRun = false;
              bool missedRun = false;
              String activityType = 'Exercise';
              bool isMissedAndAccountable = false;
              try {
                final entry = journalEntries.firstWhere((e) =>
                    e.date.year == day.year &&
                    e.date.month == day.month &&
                    e.date.day == day.day);
                hasRun = entry.didExercise == true;
                missedRun = entry.didExercise == false;
                isMissedAndAccountable = !hasStudied && !entry.didStudy && entry.missedReason != null;
                if (hasRun && entry.exerciseNote != null) {
                  final rawNote = entry.exerciseNote!;
                  if (rawNote.startsWith('[') && rawNote.contains(']')) {
                    activityType = rawNote.substring(1, rawNote.indexOf(']'));
                  }
                }
              } catch (_) {}

              return GestureDetector(
                onTap: () {
                  if (widget.onDayTap != null) {
                    widget.onDayTap!(normalizedDay, hours);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday
                        ? Border.all(color: AppColors.gold, width: 2)
                        : Border.all(color: AppColors.border.withOpacity(0.3), width: 0.5),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                                color: hours > 0
                                    ? (hours >= 6 ? AppColors.background : AppColors.textPrimary)
                                    : (isMissedAndAccountable ? AppColors.red : AppColors.textSecondary),
                              ),
                            ),
                            if (hours > 0) ...[
                              const SizedBox(height: 1),
                              Text(
                                '${hours.toStringAsFixed(1)}h',
                                style: GoogleFonts.inter(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: hours >= 6 ? AppColors.background : AppColors.gold,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isMissedAndAccountable)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            Icons.close_rounded,
                            size: 10,
                            color: AppColors.red.withOpacity(0.85),
                          ),
                        ),
                      Positioned(
                        bottom: 3,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isMissedAndAccountable)
                              Icon(
                                Icons.close_rounded,
                                size: 8,
                                color: AppColors.red,
                              )
                            else if (hasStudied)
                              Icon(
                                Icons.menu_book_rounded,
                                size: 7,
                                color: hours >= 6 ? AppColors.background : AppColors.gold,
                              ),
                            if ((hasStudied || isMissedAndAccountable) && (hasRun || missedRun)) const SizedBox(width: 2),
                            if (hasRun)
                              Icon(
                                _getExerciseIcon(activityType),
                                size: 7,
                                color: hours >= 6 ? AppColors.background : AppColors.green,
                              )
                            else if (missedRun)
                              Icon(
                                Icons.close_rounded,
                                size: 8,
                                color: AppColors.red,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
              ),
              const SizedBox(width: 6),
              _buildLegendCell(_getCellColor(0)),
              _buildLegendCell(_getCellColor(1)),
              _buildLegendCell(_getCellColor(3)),
              _buildLegendCell(_getCellColor(5)),
              _buildLegendCell(_getCellColor(8)),
              const SizedBox(width: 6),
              Text(
                'More',
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendCell(Color color) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  IconData _getExerciseIcon(String type) {
    switch (type.trim().toLowerCase()) {
      case 'running':
        return Icons.directions_run_rounded;
      case 'yoga':
        return Icons.self_improvement_rounded;
      case 'gym':
        return Icons.fitness_center_rounded;
      case 'exercise':
      default:
        return Icons.fitness_center_rounded;
    }
  }

  Color _getCellColor(double hours) {
    if (hours <= 0) return AppColors.surfaceElevated;
    if (hours < 2) return AppColors.gold.withValues(alpha: 0.15);
    if (hours < 4) return AppColors.gold.withValues(alpha: 0.4);
    if (hours < 6) return AppColors.gold.withValues(alpha: 0.7);
    return AppColors.gold;
  }
}
