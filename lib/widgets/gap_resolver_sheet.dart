import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../providers/journey_provider.dart';

class GapResolverSheet extends ConsumerStatefulWidget {
  final List<DateTime> pendingDays;
  const GapResolverSheet({required this.pendingDays, super.key});

  static void show(BuildContext context, WidgetRef ref, List<DateTime> pendingDays) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => GapResolverSheet(pendingDays: pendingDays),
    );
  }

  @override
  ConsumerState<GapResolverSheet> createState() => _GapResolverSheetState();
}

class _GapResolverSheetState extends ConsumerState<GapResolverSheet> {
  int _currentIndex = 0;
  String? _selectedReason;
  bool _isBatchMode = false;
  final Set<DateTime> _selectedBatchDays = {};

  final List<String> _gapReasons = const [
    'Burnout & mental fatigue',
    'Health issues / sick day',
    'Family function / social obligation',
    'Travel / relocation',
    'Lack of motivation / procrastination',
    'Emergency / unforeseen work',
    'Revision-only day (no new sessions)',
    'Full-day test series / mock exam',
  ];

  @override
  void initState() {
    super.initState();
    // Default select all pending days in batch selection mode
    _selectedBatchDays.addAll(widget.pendingDays);
  }

  @override
  Widget build(BuildContext context) {
    final remainingCount = widget.pendingDays.length - _currentIndex;

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
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

          // Header with Mode Switch
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.goldSurface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_person_rounded, color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Accountability Block',
                      style: GoogleFonts.instrumentSerif(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _isBatchMode 
                          ? '${_selectedBatchDays.length} days selected together' 
                          : 'Unresolved study gaps: $remainingCount days pending',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              // Mode toggle button
              if (widget.pendingDays.length > 1)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isBatchMode = !_isBatchMode;
                      _selectedReason = null;
                    });
                  },
                  icon: Icon(
                    _isBatchMode ? Icons.calendar_view_day_rounded : Icons.date_range_rounded,
                    size: 16,
                    color: AppColors.gold,
                  ),
                  label: Text(
                    _isBatchMode ? 'Single Day' : 'Multiple Days',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                ),
            ],
          ),
          const Divider(height: 32, color: AppColors.border),

          // Render appropriate selection mode view
          if (_isBatchMode) ...[
            Text(
              'Select the dates you want to group together:',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 120),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                itemCount: widget.pendingDays.length,
                itemBuilder: (context, index) {
                  final day = widget.pendingDays[index];
                  final formatted = DateFormat('EEE, d MMM yyyy').format(day);
                  final isChecked = _selectedBatchDays.contains(day);
                  
                  return CheckboxListTile(
                    value: isChecked,
                    activeColor: AppColors.gold,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      formatted,
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
                    ),
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedBatchDays.add(day);
                        } else {
                          // Prevent deselecting all
                          if (_selectedBatchDays.length > 1) {
                            _selectedBatchDays.remove(day);
                          }
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ] else ...[
            // Single Day Display Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Text(
                    'GAP DAY ${_currentIndex + 1} OF ${widget.pendingDays.length}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    DateFormat('EEEE, d MMM yyyy').format(widget.pendingDays[_currentIndex]),
                    style: GoogleFonts.instrumentSerif(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Reasons Selection list
          Text(
            _isBatchMode 
                ? 'Why did you miss these study days?' 
                : 'Why did you miss this study day?',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _gapReasons.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final reason = _gapReasons[index];
                final isSelected = _selectedReason == reason;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedReason = reason;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.goldSurface : AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.gold : AppColors.border,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          size: 16,
                          color: isSelected ? AppColors.gold : AppColors.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            reason,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: isSelected ? AppColors.gold : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Submit / Advance Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selectedReason == null
                  ? null
                  : () async {
                      final journeyNotifier = ref.read(journeyProvider.notifier);
                      
                      if (_isBatchMode) {
                        // Apply selected reason to all checked dates at once
                        for (final day in _selectedBatchDays) {
                          await journeyNotifier.registerGapReason(day, _selectedReason!);
                        }
                        
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.green,
                            behavior: SnackBarBehavior.floating,
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.background),
                                const SizedBox(width: 10),
                                Text(
                                  'Selected gap days resolved together!',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600, color: AppColors.background),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        // Save current single gap reason
                        final day = widget.pendingDays[_currentIndex];
                        await journeyNotifier.registerGapReason(day, _selectedReason!);

                        if (_currentIndex < widget.pendingDays.length - 1) {
                          setState(() {
                            _currentIndex++;
                            _selectedReason = null;
                          });
                        } else {
                          // Finished resolving all gaps!
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.green,
                              behavior: SnackBarBehavior.floating,
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.background),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Gap days resolved! Today\'s logging unlocked.',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600, color: AppColors.background),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.background,
                disabledBackgroundColor: AppColors.border,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _isBatchMode || _currentIndex == widget.pendingDays.length - 1
                    ? 'Unlock Logging'
                    : 'Save & Continue',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
