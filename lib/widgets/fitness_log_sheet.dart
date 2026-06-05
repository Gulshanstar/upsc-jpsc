import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../providers/journey_provider.dart';
import '../providers/user_provider.dart';
import '../models/journal_entry.dart';

class FitnessLogSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  final DateTime? initialDate;
  const FitnessLogSheet({required this.ref, this.initialDate, super.key});

  @override
  ConsumerState<FitnessLogSheet> createState() => _FitnessLogSheetState();
}

class _FitnessLogSheetState extends ConsumerState<FitnessLogSheet> {
  DateTime _selectedDate = DateTime.now();
  bool _didExercise = true;
  String _selectedActivity = 'Running';
  final _activityCustomController = TextEditingController();
  final _noteController = TextEditingController();
  String _missedReason = 'Rest day';
  final _customReasonController = TextEditingController();

  final List<String> _activities = ['Running', 'Gym', 'Yoga', 'Exercise', 'Other'];

  final List<String> _reasons = [
    'Rest day',
    'Tired / Lack of energy',
    'Injured / Soreness',
    'Weather conditions',
    'Busy studying / Lack of time',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();

    // Prefill if there is an existing journal entry for this date
    final journeyNotifier = ref.read(journeyProvider.notifier);
    final entry = journeyNotifier.entryForDay(_selectedDate);
    final profile = ref.read(userProfileProvider);
    final defaultActivity = profile.dailyExerciseType ?? 'Running';

    if (entry != null) {
      _didExercise = entry.didExercise ?? true;
      final rawNote = entry.exerciseNote;
      if (rawNote != null && rawNote.startsWith('[') && rawNote.contains(']')) {
        final end = rawNote.indexOf(']');
        final activity = rawNote.substring(1, end);
        if (_activities.contains(activity)) {
          _selectedActivity = activity;
        } else {
          _selectedActivity = 'Other';
          _activityCustomController.text = activity;
        }

        if (end + 1 < rawNote.length) {
          _noteController.text = rawNote.substring(end + 1).trim();
        } else {
          _noteController.text = '';
        }
      } else {
        _selectedActivity = _activities.contains(defaultActivity) ? defaultActivity : 'Exercise';
        _noteController.text = rawNote ?? '';
      }

      if (_reasons.contains(entry.missedExerciseReason)) {
        _missedReason = entry.missedExerciseReason!;
      } else if (entry.missedExerciseReason != null) {
        _missedReason = 'Other';
        _customReasonController.text = entry.missedExerciseReason!;
      }
    } else {
      _selectedActivity = _activities.contains(defaultActivity) ? defaultActivity : 'Exercise';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _customReasonController.dispose();
    _activityCustomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final formattedDate = DateFormat('MMMM d, yyyy').format(_selectedDate);

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
                  'Log Fitness / Exercise',
                  style: GoogleFonts.instrumentSerif(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Date Selector
            Text(
              'Date',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final firstDate = profile.preparationStartDate ?? now.subtract(const Duration(days: 365));
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate.isBefore(firstDate) ? firstDate : _selectedDate,
                  firstDate: firstDate,
                  lastDate: now,
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: const ColorScheme.light(
                          primary: AppColors.gold,
                          onPrimary: AppColors.background,
                          onSurface: AppColors.textPrimary,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (pickedDate != null) {
                  setState(() {
                    _selectedDate = pickedDate;
                    // reload state if journal exists
                    final journeyNotifier = ref.read(journeyProvider.notifier);
                    final entry = journeyNotifier.entryForDay(_selectedDate);
                    final defaultAct = profile.dailyExerciseType ?? 'Running';
                    if (entry != null) {
                      _didExercise = entry.didExercise ?? true;
                      final rawNote = entry.exerciseNote;
                      if (rawNote != null && rawNote.startsWith('[') && rawNote.contains(']')) {
                        final end = rawNote.indexOf(']');
                        final activity = rawNote.substring(1, end);
                        if (_activities.contains(activity)) {
                          _selectedActivity = activity;
                        } else {
                          _selectedActivity = 'Other';
                          _activityCustomController.text = activity;
                        }
                        if (end + 1 < rawNote.length) {
                          _noteController.text = rawNote.substring(end + 1).trim();
                        } else {
                          _noteController.text = '';
                        }
                      } else {
                        _selectedActivity = _activities.contains(defaultAct) ? defaultAct : 'Exercise';
                        _noteController.text = rawNote ?? '';
                      }
                      if (_reasons.contains(entry.missedExerciseReason)) {
                        _missedReason = entry.missedExerciseReason!;
                      } else if (entry.missedExerciseReason != null) {
                        _missedReason = 'Other';
                        _customReasonController.text = entry.missedExerciseReason!;
                      }
                    } else {
                      _didExercise = true;
                      _selectedActivity = _activities.contains(defaultAct) ? defaultAct : 'Exercise';
                      _noteController.clear();
                      _missedReason = 'Rest day';
                      _customReasonController.clear();
                      _activityCustomController.clear();
                    }
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.gold),
                    const SizedBox(width: 10),
                    Text(
                      formattedDate,
                      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Toggle Completed Exercise
            Text(
              'Did you complete your daily fitness session?',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildToggleButton(true, 'Yes, Completed', AppColors.green),
                const SizedBox(width: 12),
                _buildToggleButton(false, 'No, Skipped', AppColors.red),
              ],
            ),
            const SizedBox(height: 20),

            if (_didExercise) ...[
              // Activity Type Selector
              Text(
                'Activity Type',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _activities.map((activity) {
                  final isSelected = _selectedActivity == activity;
                  return ChoiceChip(
                    label: Text(activity),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedActivity = activity;
                        });
                      }
                    },
                    selectedColor: AppColors.green.withValues(alpha: 0.15),
                    backgroundColor: AppColors.surfaceElevated,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.green : AppColors.textSecondary,
                    ),
                    checkmarkColor: AppColors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(
                        color: isSelected ? AppColors.green : AppColors.border,
                        width: 1.0,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_selectedActivity == 'Other') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _activityCustomController,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Enter custom activity type (e.g. Swimming, Cycling)...',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
              ],
              const SizedBox(height: 20),

              Text(
                'Note',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'e.g. Feeling fresh, recorded 30 minutes...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ] else ...[
              Text(
                'Reason for skipping fitness',
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
                      if (val != null) {
                        setState(() {
                          _missedReason = val;
                        });
                      }
                    },
                  ),
                ),
              ),
              if (_missedReason == 'Other') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _customReasonController,
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
            const SizedBox(height: 24),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (() {
                  if (!_didExercise && _missedReason == 'Other' && _customReasonController.text.trim().isEmpty) {
                    return null;
                  }
                  if (_didExercise && _selectedActivity == 'Other' && _activityCustomController.text.trim().isEmpty) {
                    return null;
                  }
                  return _saveFitness;
                })(),
                child: Text('Save Fitness Log', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(bool val, String label, Color activeColor) {
    final isSelected = _didExercise == val;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _didExercise = val),
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

  void _saveFitness() async {
    final journeyNotifier = ref.read(journeyProvider.notifier);
    final existingEntry = journeyNotifier.entryForDay(_selectedDate);

    final finalReason = !_didExercise
        ? (_missedReason == 'Other' ? _customReasonController.text.trim() : _missedReason)
        : null;

    final activityName = _selectedActivity == 'Other' 
        ? _activityCustomController.text.trim() 
        : _selectedActivity;

    final finalNote = _didExercise
        ? '[$activityName] ${_noteController.text.trim()}'
        : null;

    final entry = JournalEntry(
      id: existingEntry?.id ?? const Uuid().v4(),
      date: DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day),
      didStudy: existingEntry?.didStudy ?? false,
      hoursStudied: existingEntry?.hoursStudied ?? 0.0,
      topicsCount: existingEntry?.topicsCount ?? 0,
      mood: existingEntry?.mood ?? 3,
      note: existingEntry?.note,
      goal: existingEntry?.goal,
      missedReason: existingEntry?.missedReason,
      didExercise: _didExercise,
      exerciseNote: finalNote,
      missedExerciseReason: finalReason,
    );

    await journeyNotifier.upsertEntry(entry);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fitness log saved successfully.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
