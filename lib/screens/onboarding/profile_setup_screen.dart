import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../models/user_profile.dart';
import '../../providers/user_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/journey_provider.dart';
import '../../providers/revision_provider.dart';
import '../../providers/syllabus_provider.dart';
import '../../utils/supabase_service.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  DateTime _examDate = DateTime(2026, 6, 1);
  DateTime _prepStartDate = DateTime.now();
  double _dailyGoal = 8.0;
  int _examModeIndex = 0;

  final List<String> _optionals = [
    'Anthropology', 'History', 'Geography', 'Sociology', 'Public Administration',
    'Political Science & IR', 'Philosophy', 'Psychology', 'Economics',
    'Mathematics', 'Law', 'Management', 'Commerce & Accountancy',
    'Physics', 'Chemistry', 'Agriculture', 'Botany', 'Zoology', 'Geology',
    'Animal Husbandry & Veterinary Science', 'Civil Engineering',
    'Electrical Engineering', 'Mechanical Engineering', 'Medical Science',
    'Statistics', 'Literature — Hindi', 'Literature — English',
    'Literature — Sanskrit', 'Literature — Urdu', 'Literature — Bengali',
    'Literature — Tamil', 'Literature — Telugu',
  ];
  String? _selectedOptional;
  String? _selectedExercise; // null/none, 'Yoga', 'Running', 'Exercise'

  @override
  void initState() {
    super.initState();
    // Pre-populate fields if settings are being viewed after onboarding
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(userProfileProvider);
      if (profile.onboardingComplete) {
        _nameController.text = profile.name;
        setState(() {
          _examDate = profile.examTargetDate ?? DateTime(2026, 6, 1);
          _prepStartDate = profile.preparationStartDate ?? DateTime.now();
          _dailyGoal = profile.dailyGoalHours;
          _examModeIndex = profile.examMode.index;
          _selectedOptional = profile.optionalSubject;
          _selectedExercise = profile.dailyExerciseType;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra;
    if (extra is int) _examModeIndex = extra;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _examDate,
      firstDate: DateTime.now().isBefore(_examDate) ? DateTime.now() : _examDate.subtract(const Duration(days: 30)),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.gold,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  Future<void> _pickPrepStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _prepStartDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.gold,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _prepStartDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final isEditMode = profile.onboardingComplete;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: isEditMode 
            ? Text('Edit Settings', style: GoogleFonts.inter(fontSize: 16, color: AppColors.textPrimary, fontWeight: FontWeight.w600))
            : null,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        actions: isEditMode ? [
          TextButton(
            onPressed: () async {
              // Sign out from Supabase & Google
              await SupabaseService.instance.signOut();
              // Reset profile state
              await ref.read(userProfileProvider.notifier).update(UserProfile.defaultProfile());
              // Reset syllabus progress
              await ref.read(syllabusProvider.notifier).resetAllStatuses();
              if (context.mounted) {
                context.go('/onboarding');
              }
            },
            child: Text('Log Out', style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ] : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEditMode ? 'Profile Settings' : 'Set up your profile',
                  style: GoogleFonts.instrumentSerif(
                      fontSize: 32, color: AppColors.textPrimary))
                  .animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

              const SizedBox(height: 8),
              Text(isEditMode ? 'Update your target exam and daily study goals' : 'Personalise your preparation journey',
                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted))
                  .animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 40),

              _SectionLabel('Your name'),
              const SizedBox(height: 10),
              TextField(
                controller: _nameController,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'e.g. Gulshan',
                  prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textMuted, size: 20),
                ),
              ),

              const SizedBox(height: 28),
              _SectionLabel('Target exam'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ExamModeChip(
                      label: 'UPSC',
                      isSelected: _examModeIndex == 0,
                      onTap: () => setState(() => _examModeIndex = 0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ExamModeChip(
                      label: 'JPSC',
                      isSelected: _examModeIndex == 1,
                      onTap: () => setState(() => _examModeIndex = 1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ExamModeChip(
                      label: 'Both',
                      isSelected: _examModeIndex == 2,
                      onTap: () => setState(() => _examModeIndex = 2),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              _SectionLabel('Preparation start date'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickPrepStartDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle_outline_rounded, color: AppColors.gold, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${_prepStartDate.day} ${_monthName(_prepStartDate.month)} ${_prepStartDate.year}',
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
                      ),
                      const Spacer(),
                      Text(
                        _prepStartDate.isBefore(DateTime.now())
                            ? 'Started ${DateTime.now().difference(_prepStartDate).inDays} days ago'
                            : 'Starts in ${_prepStartDate.difference(DateTime.now()).inDays} days',
                        style: GoogleFonts.inter(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
              _SectionLabel('Target exam date'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: AppColors.gold, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${_examDate.day} ${_monthName(_examDate.month)} ${_examDate.year}',
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 15),
                      ),
                      const Spacer(),
                      Text(
                        _examDate.isAfter(DateTime.now())
                            ? '${_examDate.difference(DateTime.now()).inDays} days left'
                            : 'Exam day reached',
                        style: GoogleFonts.inter(color: AppColors.gold, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
              _SectionLabel('Daily study goal'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: _dailyGoal,
                      min: 2, max: 16, divisions: 14,
                      activeColor: AppColors.gold,
                      inactiveColor: AppColors.surfaceElevated,
                      onChanged: (v) => setState(() => _dailyGoal = v),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.goldSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${_dailyGoal.toInt()}h',
                        style: GoogleFonts.inter(
                            color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ],
              ),

              const SizedBox(height: 28),
              _SectionLabel('Optional subject'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedOptional,
                isExpanded: true,
                dropdownColor: AppColors.surfaceElevated,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Select your optional subject',
                  prefixIcon: const Icon(Icons.book_outlined, color: AppColors.textMuted, size: 20),
                ),
                items: _optionals
                    .map((o) => DropdownMenuItem(
                          value: o,
                          child: Text(o, overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedOptional = v),
              ),

              const SizedBox(height: 28),
              _SectionLabel('Daily Exercise (Optional)'),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedExercise,
                isExpanded: true,
                dropdownColor: AppColors.surfaceElevated,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'I do not want to track exercise',
                  prefixIcon: const Icon(Icons.directions_run_rounded, color: AppColors.textMuted, size: 20),
                ),
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text('None / Hide this section', style: GoogleFonts.inter(color: AppColors.textMuted)),
                  ),
                  const DropdownMenuItem<String>(
                    value: 'Running',
                    child: Text('🏃 Running'),
                  ),
                  const DropdownMenuItem<String>(
                    value: 'Yoga',
                    child: Text('🧘 Yoga'),
                  ),
                  const DropdownMenuItem<String>(
                    value: 'Exercise',
                    child: Text('💪 General Exercise'),
                  ),
                  const DropdownMenuItem<String>(
                    value: 'Gym',
                    child: Text('🏋️ Gym / Workout'),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedExercise = v),
              ),

              const SizedBox(height: 28),
              _SectionLabel('Data Management'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                  label: Text(
                    'Delete logs in a date range',
                    style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    final pickedRange = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                      builder: (ctx, child) => Theme(
                        data: Theme.of(ctx).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.gold,
                            onPrimary: Colors.white,
                            surface: AppColors.surface,
                            onSurface: AppColors.textPrimary,
                          ),
                        ),
                        child: child!,
                      ),
                    );

                    if (pickedRange != null && mounted) {
                      final start = pickedRange.start;
                      final end = pickedRange.end;
                      
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: AppColors.surfaceElevated,
                          title: Text('Delete Study Logs?', style: GoogleFonts.instrumentSerif(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          content: Text(
                            'Are you sure you want to delete all study shifts and consistency logs between ${start.day}/${start.month}/${start.year} and ${end.day}/${end.month}/${end.year}?\n\nThis action cannot be undone.',
                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                          ),
                          actions: [
                            TextButton(
                              child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted)),
                              onPressed: () => Navigator.pop(ctx, false),
                            ),
                            TextButton(
                              child: Text('Delete', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                              onPressed: () => Navigator.pop(ctx, true),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        // Clear in sessionProvider, journeyProvider, revisionProvider, and syllabusProvider!
                        await ref.read(sessionProvider.notifier).deleteSessionsInRange(start, end);
                        await ref.read(journeyProvider.notifier).clearJournalEntriesInRange(start, end);
                        await ref.read(revisionProvider.notifier).clearRevisionsInRange(start, end);
                        await ref.read(syllabusProvider.notifier).resetStatusesInRange(start, end);
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Study shifts and syllabus progress in range deleted successfully.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent, width: 1.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.redAccent, size: 20),
                  label: Text(
                    'Reset all syllabus progress',
                    style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surfaceElevated,
                        title: Text('Reset Syllabus Progress?', style: GoogleFonts.instrumentSerif(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        content: Text(
                          'Are you sure you want to reset all syllabus completion percentages, topics studied, and in-progress flags?\n\nThis will return all subjects and topics to "Not Started". This action cannot be undone.',
                          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        actions: [
                          TextButton(
                            child: Text('Cancel', style: GoogleFonts.inter(color: AppColors.textMuted)),
                            onPressed: () => Navigator.pop(ctx, false),
                          ),
                          TextButton(
                            child: Text('Reset', style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                            onPressed: () => Navigator.pop(ctx, true),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true && mounted) {
                      await ref.read(syllabusProvider.notifier).resetAllStatuses();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('All syllabus progress has been reset.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _nameController.text.trim().isEmpty ? null : _proceed,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isEditMode ? 'Save Settings' : 'Continue', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      Icon(isEditMode ? Icons.check_rounded : Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _proceed() {
    final examMode = ExamMode.values[_examModeIndex];
    final profile = ref.read(userProfileProvider);
    final isEditMode = profile.onboardingComplete;

    if (isEditMode) {
      ref.read(userProfileProvider.notifier).update(
        UserProfile(
          name: _nameController.text.trim(),
          examMode: examMode,
          examTargetDate: _examDate,
          preparationStartDate: _prepStartDate,
          dailyGoalHours: _dailyGoal,
          optionalSubject: _selectedOptional,
          onboardingComplete: true,
          dailyExerciseType: _selectedExercise,
        ),
      );
      context.pop(); // Go back to Dashboard
    } else {
      ref.read(userProfileProvider.notifier).completeOnboarding(
        name: _nameController.text.trim(),
        examMode: examMode,
        examTargetDate: _examDate,
        preparationStartDate: _prepStartDate,
        dailyGoalHours: _dailyGoal,
        optionalSubject: _selectedOptional,
        dailyExerciseType: _selectedExercise,
      );
      context.go('/dashboard');
    }
  }

  String _monthName(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m-1];
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 12, color: AppColors.textMuted,
            fontWeight: FontWeight.w600, letterSpacing: 0.8));
  }
}

class _ExamModeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ExamModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldSurface : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? AppColors.goldDark : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
