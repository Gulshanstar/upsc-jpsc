import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../models/study_session.dart' as ss;
import 'session_detail_sheet.dart';

class SessionTile extends ConsumerWidget {
  final ss.StudySession session;

  const SessionTile({required this.session, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isToday = session.date.day == DateTime.now().day &&
        session.date.month == DateTime.now().month;
    
    String shiftLabel = '';
    if (session.shift == 'morning') {
      shiftLabel = '🌅 Morning';
    } else if (session.shift == 'afternoon') {
      shiftLabel = '☀️ Afternoon';
    } else if (session.shift == 'evening') {
      shiftLabel = '🌇 Evening';
    } else if (session.shift == 'night') {
      shiftLabel = '🌙 Night';
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => SessionDetailSheet.show(context, ref, session),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.blueSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_rounded, color: AppColors.blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.subjectName,
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${session.sectionName}${shiftLabel.isNotEmpty ? ' • $shiftLabel' : ''} • ${session.durationHours.toStringAsFixed(1)}h',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    isToday ? 'Today' : '${session.date.day}/${session.date.month}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.insights_rounded, size: 10, color: AppColors.gold),
                      const SizedBox(width: 3),
                      Text(
                        'Curve',
                        style: GoogleFonts.inter(fontSize: 9, color: AppColors.gold, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
