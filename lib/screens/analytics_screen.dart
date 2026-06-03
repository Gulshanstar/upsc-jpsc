import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../providers/session_provider.dart';
import '../providers/syllabus_provider.dart';
import '../providers/user_provider.dart';
import '../models/user_profile.dart';
import '../models/study_session.dart' as ss;
import '../widgets/session_tile.dart';
import '../providers/journey_provider.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(sessionProvider); // Watch session provider for reactive updates on session changes
    ref.watch(userProfileProvider); // Watch user profile for reactive updates on examMode/prepStartDate changes
    final sessionNotifier = ref.read(sessionProvider.notifier);
    final syllabusState = ref.watch(syllabusProvider);

    final dailyHours = sessionNotifier.last14DaysHours;
    final subjectHours = sessionNotifier.hoursPerSubjectThisMonth;
    final timeOfDayHours = sessionNotifier.hoursByTimeOfDay;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(
              'Performance Analytics',
              style: GoogleFonts.instrumentSerif(fontSize: 24),
            ),
            backgroundColor: AppColors.background,
            floating: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 14-Day Study Hours Bar Chart
                _buildBarChartCard(dailyHours),
                const SizedBox(height: 20),

                // Subject Time Pie Chart
                _buildPieChartCard(subjectHours),
                const SizedBox(height: 20),

                // Study hours by time of day
                _buildTimeOfDayCard(timeOfDayHours),
                const SizedBox(height: 20),

                // Overall Syllabus Progress Cards
                _buildSyllabusAnalysis(syllabusState, ref.watch(userProfileProvider)),
                const SizedBox(height: 20),

                // Missed Study Days Gap Analytics!
                _buildGapReasonAnalysisCard(context, ref),
                const SizedBox(height: 20),

                // Study Sessions Log history
                _buildSessionHistorySection(context, ref, sessionNotifier.filteredState),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChartCard(List<double> dailyHours) {
    final maxVal = dailyHours.fold<double>(4.0, (m, e) => e > m ? e : m);
    final days = List.generate(14, (i) {
      final date = DateTime.now().subtract(Duration(days: 13 - i));
      return DateFormat('dd').format(date);
    });

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
          Text(
            'Daily Study Hours',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          Text(
            'Last 14 days progress log',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (maxVal + 1.0).roundToDouble(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceElevated,
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)}h',
                        GoogleFonts.inter(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < 14) {
                          // Show every alternate day to avoid text overlap
                          if (idx % 2 == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                days[idx],
                                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 24,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value % 2 == 0) {
                          return Text(
                            '${value.toInt()}h',
                            style: GoogleFonts.inter(fontSize: 9, color: AppColors.textMuted),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 28,
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(14, (idx) {
                  final h = dailyHours[idx];
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(
                        toY: h,
                        color: h >= 6.0 ? AppColors.green : AppColors.gold,
                        width: 10,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildPieChartCard(Map<String, double> subjectHours) {
    final colors = [
      AppColors.gold,
      AppColors.green,
      AppColors.blue,
      AppColors.orange,
      const Color(0xFFC77DFF),
      const Color(0xFF4EA8DE),
      const Color(0xFFFF7096),
    ];

    final hasData = subjectHours.values.any((h) => h > 0);

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
          Text(
            'Subject Distribution',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          Text(
            'Time division by subjects this month',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          if (!hasData)
            Container(
              height: 180,
              alignment: Alignment.center,
              child: Text(
                'No subject logs this month.',
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 160,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 35,
                        sections: subjectHours.entries.map((e) {
                          final idx = subjectHours.keys.toList().indexOf(e.key) % colors.length;
                          return PieChartSectionData(
                            color: colors[idx],
                            value: e.value,
                            title: '${(e.value).toStringAsFixed(1)}h',
                            radius: 40,
                            titleStyle: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.background,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: subjectHours.entries.map((e) {
                      final idx = subjectHours.keys.toList().indexOf(e.key) % colors.length;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: colors[idx],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                e.key,
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ).animate().fadeIn(delay: 150.ms),
    );
  }

  Widget _buildTimeOfDayCard(Map<int, double> timeHours) {
    final maxVal = timeHours.values.fold<double>(1.0, (m, e) => e > m ? e : m);
    // Standard periods
    final hours = [8, 10, 12, 14, 16, 18, 20, 22];

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
          Text(
            'Study Habits Trend',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          Text(
            'Hourly analysis of your study sessions',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                maxY: maxVal * 1.2,
                minY: 0,
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final hr = value.toInt();
                        if (hours.contains(hr)) {
                          final label = hr > 12 ? '${hr - 12} PM' : hr == 12 ? '12 PM' : '$hr AM';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              label,
                              style: GoogleFonts.inter(fontSize: 8.5, color: AppColors.textMuted),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.border,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(24, (i) {
                      final h = timeHours[i] ?? 0.0;
                      return FlSpot(i.toDouble(), h);
                    }),
                    isCurved: true,
                    color: AppColors.gold,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.gold.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ).animate().fadeIn(delay: 200.ms),
    );
  }

  Widget _buildSyllabusAnalysis(SyllabusState state, UserProfile profile) {
    final showUpsc = profile.examMode == ExamMode.upsc || profile.examMode == ExamMode.both;
    final showJpsc = profile.examMode == ExamMode.jpsc || profile.examMode == ExamMode.both;

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
          Text(
            'Syllabus Coverage Breakdown',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),
          if (showUpsc) ...[
            _buildSubjectProgressBar(
              'UPSC Civil Services',
              state.completedUpscTopics(),
              state.totalUpscTopics,
              state.upscProgress,
              AppColors.gold,
            ),
            if (showJpsc) const SizedBox(height: 18),
          ],
          if (showJpsc)
            _buildSubjectProgressBar(
              'JPSC Exam papers',
              state.completedJpscTopics(),
              state.totalJpscTopics,
              state.jpscProgress,
              AppColors.green,
            ),
        ],
      ).animate().fadeIn(delay: 250.ms),
    );
  }

  Widget _buildSubjectProgressBar(
    String exam,
    int completed,
    int total,
    double progress,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              exam,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
            ),
            Text(
              '$completed/$total topics',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSessionHistorySection(BuildContext context, WidgetRef ref, List<ss.StudySession> sessions) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Study Session Logs',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${sessions.length} sessions',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.gold),
                ),
              ),
            ],
          ),
          Text(
            'Tap any session to view its detailed Forgetting Curve timeline',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          if (sessions.isEmpty)
            Container(
              height: 100,
              alignment: Alignment.center,
              child: Text(
                'No sessions logged yet.',
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return SessionTile(session: session);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGapReasonAnalysisCard(BuildContext context, WidgetRef ref) {
    final journalEntries = ref.watch(journeyProvider);
    final gapEntries = journalEntries.where((e) => !e.didStudy && e.missedReason != null).toList();

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gap Analysis & Obstacles',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${gapEntries.length} gap days',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.gold),
                ),
              ),
            ],
          ),
          Text(
            'Obstacles affecting your consistency streak',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),
          if (gapEntries.isEmpty)
            Container(
              height: 100,
              alignment: Alignment.center,
              child: Text(
                'No study gap reasons registered yet.',
                style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
              ),
            )
          else ...[
            // Calculate reasons frequencies
            () {
              final Map<String, int> frequencies = {};
              for (final entry in gapEntries) {
                frequencies[entry.missedReason!] = (frequencies[entry.missedReason!] ?? 0) + 1;
              }

              final sorted = frequencies.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
              final totalGaps = gapEntries.length;

              final topReason = sorted.first.key;
              String recommendation = 'Keep tracking your gaps to identify patterns and optimize consistency.';
              if (topReason.toLowerCase().contains('burnout')) {
                recommendation = '🔥 Burnout is your top study obstacle. Consider adding planned 10-minute breaks, study shorter blocks, or dedicate a complete guilt-free rest day to avoid mental exhaustion.';
              } else if (topReason.toLowerCase().contains('motivation') || topReason.toLowerCase().contains('procrastination')) {
                recommendation = '⏳ Procrastination is affecting your streak. Break large topics into micro-tasks and try starting with a tiny 15-minute goal to lower the entry barrier.';
              } else if (topReason.toLowerCase().contains('health') || topReason.toLowerCase().contains('sickness')) {
                recommendation = '💧 Physical health/sickness is your main obstacle. Prioritize sleep, regular exercise, and stay hydrated; a healthy body sustains long preparation journeys.';
              } else if (topReason.toLowerCase().contains('social') || topReason.toLowerCase().contains('family')) {
                recommendation = '🤝 Social and family obligations are your primary gap driver. Set clear boundaries with friends and family during study blocks, or practice early morning sessions before distractions begin.';
              } else if (topReason.toLowerCase().contains('travel') || topReason.toLowerCase().contains('transit')) {
                recommendation = '✈️ Travel or transit is taking a major toll. Leverage offline audio podcasts, print revision sheets, or pocket-sized notes to convert transit time into active preparation.';
              } else if (topReason.toLowerCase().contains('exam') || topReason.toLowerCase().contains('college')) {
                recommendation = '📝 Academic exams are keeping you away. Dedicate focused study slots on weekends, or align your preparation syllabus with college topics if possible.';
              } else if (topReason.toLowerCase().contains('emergency') || topReason.toLowerCase().contains('unforeseen')) {
                recommendation = '⚠️ Emergencies are interrupting your schedule. Build a small 2-hour "buffer block" on weekends to catch up on lessons missed due to unexpected emergencies.';
              } else if (topReason.toLowerCase().contains('revision')) {
                recommendation = '🔄 Revision fatigue is holding you back. Try active recall methods (flashcards, mock questions) instead of passive reading to make sessions highly interactive.';
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...sorted.map((e) {
                    final reason = e.key;
                    final count = e.value;
                    final pct = count / totalGaps;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  reason,
                                  style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                '$count times (${(pct * 100).toInt()}%)',
                                style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 6,
                              backgroundColor: AppColors.surfaceElevated,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 16),
                  // Accountability Advice Panel
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.goldSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.tips_and_updates_rounded, color: AppColors.gold, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            recommendation,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }(),
          ],
        ],
      ),
    );
  }
}

