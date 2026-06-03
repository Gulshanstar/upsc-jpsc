import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';

class SyllabusSelectionScreen extends StatelessWidget {
  const SyllabusSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('All set! 🎉',
                  style: GoogleFonts.instrumentSerif(
                      fontSize: 36, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Text(
                'Your full UPSC & JPSC syllabus is pre-loaded.\nStart tracking your progress from the app.',
                style: GoogleFonts.inter(
                    fontSize: 15, color: AppColors.textSecondary, height: 1.6),
              ),
              const SizedBox(height: 40),
              _InfoCard('📚', 'Full syllabus loaded',
                  'GS-1 to GS-4, Essay, Optional & complete JPSC papers'),
              const SizedBox(height: 12),
              _InfoCard('🔁', 'Spaced repetition ready',
                  'Smart revision scheduling using SM-2 algorithm'),
              const SizedBox(height: 12),
              _InfoCard('📊', 'Analytics from day one',
                  'Track hours, coverage, and recall accuracy'),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => context.go('/dashboard'),
                  child: Text('Start My Journey',
                      style: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  const _InfoCard(this.emoji, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
