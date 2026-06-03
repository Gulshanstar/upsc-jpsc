import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

class HeatmapCalendar extends StatelessWidget {
  final Map<DateTime, double> datasets;
  final Function(DateTime, double)? onDayTap;

  const HeatmapCalendar({
    required this.datasets,
    this.onDayTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Generate dates for the last 20 weeks
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Find the Monday/Sunday of 20 weeks ago
    final startDay = today.subtract(Duration(days: 20 * 7 - (today.weekday - 1)));

    // Group days by week
    final List<List<DateTime>> weeks = [];
    DateTime currentDay = startDay;
    for (int w = 0; w < 20; w++) {
      final List<DateTime> week = [];
      for (int d = 0; d < 7; d++) {
        week.add(currentDay);
        currentDay = currentDay.add(const Duration(days: 1));
      }
      weeks.add(week);
    }

    return Container(
      padding: const EdgeInsets.all(18),
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
                'Study Heatmap',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                'Last 20 Weeks',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Heatmap scroll view
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // scroll to the latest week by default
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Weekday labels
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(height: 12), // spacer for month labels
                    _buildWeekdayLabel('Mon'),
                    const SizedBox(height: 4),
                    _buildWeekdayLabel(''),
                    const SizedBox(height: 4),
                    _buildWeekdayLabel('Wed'),
                    const SizedBox(height: 4),
                    _buildWeekdayLabel(''),
                    const SizedBox(height: 4),
                    _buildWeekdayLabel('Fri'),
                    const SizedBox(height: 4),
                    _buildWeekdayLabel(''),
                    const SizedBox(height: 4),
                    _buildWeekdayLabel('Sun'),
                  ],
                ),
                const SizedBox(width: 8),
                // Heatmap Columns
                Row(
                  children: weeks.map((week) {
                    // Check if month label should be displayed
                    // Display month if the first day of the week is in a new month or if it's the first week in the list
                    final firstDayOfWeek = week.first;
                    final isFirstWeekOfMonth = firstDayOfWeek.day <= 7;
                    final monthLabel = isFirstWeekOfMonth ? DateFormat('MMM').format(firstDayOfWeek) : '';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month label placeholder or value
                        SizedBox(
                          height: 14,
                          child: Text(
                            monthLabel,
                            style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 7 days of the week
                        ...week.map((day) {
                          // Normalise day key
                          final normalizedDay = DateTime(day.year, day.month, day.day);
                          final hours = datasets[normalizedDay] ?? 0.0;
                          final isToday = normalizedDay == today;
                          final color = _getCellColor(hours);

                          return GestureDetector(
                            onTap: () {
                              if (onDayTap != null) {
                                onDayTap!(normalizedDay, hours);
                              }
                            },
                            child: Container(
                              width: 12,
                              height: 12,
                              margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                                border: isToday
                                    ? Border.all(color: AppColors.gold, width: 1)
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
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

  Widget _buildWeekdayLabel(String text) {
    return SizedBox(
      height: 12,
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted),
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

  Color _getCellColor(double hours) {
    if (hours <= 0) return AppColors.surfaceElevated;
    if (hours < 2) return AppColors.gold.withValues(alpha: 0.15);
    if (hours < 4) return AppColors.gold.withValues(alpha: 0.4);
    if (hours < 6) return AppColors.gold.withValues(alpha: 0.7);
    return AppColors.gold;
  }
}
