import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_colors.dart';
import '../models/study_session.dart' as ss;
import '../models/topic.dart';
import '../providers/session_provider.dart';
import '../providers/syllabus_provider.dart';
import '../providers/user_provider.dart';
import '../models/user_profile.dart';
import '../providers/revision_provider.dart';
import '../models/revision_item.dart';

class SessionLogSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const SessionLogSheet({required this.ref, super.key});

  @override
  ConsumerState<SessionLogSheet> createState() => _SessionLogSheetState();
}

class _SessionLogSheetState extends ConsumerState<SessionLogSheet> {
  late String _examType;
  Subject? _selectedSubject;
  final List<Topic> _selectedTopics = [];
  final Map<String, TopicStatus> _topicStatuses = {};
  final Map<String, double> _topicProgresses = {};
  final Map<String, bool> _topicScheduleRevisions = {};
  late String _selectedShift;
  DateTime _selectedDate = DateTime.now();
  double _durationMinutes = 60.0;
  final _notesController = TextEditingController();
  final _searchController = TextEditingController();
  String _topicSearchQuery = '';

  @override
  void initState() {
    super.initState();
    final examMode = ref.read(userProfileProvider).examMode;
    if (examMode == ExamMode.jpsc) {
      _examType = 'jpsc';
    } else {
      _examType = 'upsc';
    }

    // Default shift based on current hour
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      _selectedShift = 'morning';
    } else if (hour >= 12 && hour < 17) {
      _selectedShift = 'afternoon';
    } else if (hour >= 17 && hour < 21) {
      _selectedShift = 'evening';
    } else {
      _selectedShift = 'night';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syllabusState = ref.watch(syllabusProvider);
    final profile = ref.watch(userProfileProvider);
    final examMode = profile.examMode;

    // Filtered subjects based on selected exam type
    final sections = syllabusState.sectionsFor(_examType);
    var allSubjects = sections.expand((s) => s.subjects).toList();

    // Filter optional subjects based on user profile optional selection
    if (profile.optionalSubject != null) {
      allSubjects = allSubjects.where((sub) {
        if (sub.sectionId == 'upsc_optional') {
          return sub.title == profile.optionalSubject;
        }
        return true;
      }).toList();
    } else {
      allSubjects = allSubjects.where((sub) => sub.sectionId != 'upsc_optional').toList();
    }

    // Default target exam from profile if not set
    if (_selectedSubject == null && allSubjects.isNotEmpty) {
      _selectedSubject = allSubjects.first;
    }

    final topics = _selectedSubject?.topics ?? [];
    final filteredTopics = topics.where((t) {
      if (_topicSearchQuery.isEmpty) return true;
      return t.title.toLowerCase().contains(_topicSearchQuery.toLowerCase());
    }).toList();

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
            // Handle bar
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
                  'Log Study Session',
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

            if (examMode == ExamMode.both) ...[
              // Exam Type Toggle
              Text(
                'Exam Target',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildExamButton('upsc', 'UPSC CSE'),
                  const SizedBox(width: 12),
                  _buildExamButton('jpsc', 'JPSC'),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Subject Selector Dropdown
            Text(
              'Subject',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
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
                child: DropdownButton<Subject>(
                  isExpanded: true,
                  value: _selectedSubject,
                  dropdownColor: AppColors.surface,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                  items: allSubjects.map((sub) {
                    return DropdownMenuItem<Subject>(
                      value: sub,
                      child: Text(
                        '${sub.emoji}  ${sub.title}',
                        style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedSubject = val;
                      _selectedTopics.clear();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Date Selector (Backdating entry) - Global!
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Session Date',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                if (profile.preparationStartDate != null)
                  Text(
                    'Prep Started: ${profile.preparationStartDate!.day}/${profile.preparationStartDate!.month}/${profile.preparationStartDate!.year}',
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      color: AppColors.gold,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
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
                    _selectedDate = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      _selectedDate.hour,
                      _selectedDate.minute,
                    );
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
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _selectedDate.day == DateTime.now().day &&
                              _selectedDate.month == DateTime.now().month &&
                              _selectedDate.year == DateTime.now().year
                          ? 'Today (Default)'
                          : 'Backdated',
                      style: GoogleFonts.inter(
                        color: AppColors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Duration Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Duration',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  _formatDuration(_durationMinutes),
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.gold,
                inactiveTrackColor: AppColors.surfaceElevated,
                thumbColor: AppColors.gold,
                overlayColor: AppColors.gold.withValues(alpha: 0.15),
                trackHeight: 4,
              ),
              child: Slider(
                min: 15,
                max: 480,
                divisions: 31,
                value: _durationMinutes,
                onChanged: (val) {
                  setState(() {
                    _durationMinutes = val;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),

            // Shift Selector
            Text(
              'Shift',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildShiftChip('morning', '🌅 Morning'),
                  const SizedBox(width: 8),
                  _buildShiftChip('afternoon', '☀️ Afternoon'),
                  const SizedBox(width: 8),
                  _buildShiftChip('evening', '🌇 Evening'),
                  const SizedBox(width: 8),
                  _buildShiftChip('night', '🌙 Night'),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _getShiftHint(_selectedShift),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 20),

            // Topics Covered Selector
            Text(
              'Topics Covered',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),

            // Topic Search inside Log Sheet
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _topicSearchQuery = val),
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search topics...',
                prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textMuted),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              height: 260,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: filteredTopics.isEmpty
                  ? Center(
                      child: Text(
                        'No topics found',
                        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: filteredTopics.length,
                      itemBuilder: (context, idx) {
                        final topic = filteredTopics[idx];
                        final isSelected = _selectedTopics.contains(topic);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedTopics.remove(topic);
                                    _topicStatuses.remove(topic.id);
                                    _topicProgresses.remove(topic.id);
                                    _topicScheduleRevisions.remove(topic.id);
                                  } else {
                                    _selectedTopics.add(topic);
                                    if (topic.status == TopicStatus.inProgress || topic.status == TopicStatus.needsRevision) {
                                      _topicStatuses[topic.id] = topic.status;
                                      _topicProgresses[topic.id] = topic.progressPercent > 0.0 ? topic.progressPercent : 0.30;
                                    } else {
                                      _topicStatuses[topic.id] = TopicStatus.completed;
                                      _topicProgresses[topic.id] = 1.0;
                                    }
                                    _topicScheduleRevisions[topic.id] = true; // Default to schedule
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank,
                                      color: isSelected ? AppColors.gold : AppColors.textMuted,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        topic.title,
                                        style: GoogleFonts.inter(
                                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      _buildTopicStatusToggleChip(topic),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            if (isSelected) ...[
                              Container(
                                margin: const EdgeInsets.only(left: 38, right: 8, top: 2, bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Progress slider
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Topic Progress',
                                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          '${((_topicProgresses[topic.id] ?? 1.0) * 100).toInt()}%',
                                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.blue, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: AppColors.blue,
                                        inactiveTrackColor: AppColors.surfaceElevated,
                                        thumbColor: AppColors.blue,
                                        overlayColor: AppColors.blue.withValues(alpha: 0.1),
                                        trackHeight: 2,
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                      ),
                                      child: Slider(
                                        value: _topicProgresses[topic.id] ?? 1.0,
                                        min: 0.10,
                                        max: 1.0,
                                        divisions: 9,
                                        onChanged: (val) {
                                          setState(() {
                                            _topicProgresses[topic.id] = val;
                                            if (val == 1.0) {
                                              _topicStatuses[topic.id] = TopicStatus.completed;
                                            } else {
                                              _topicStatuses[topic.id] = TopicStatus.inProgress;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const Divider(height: 12, color: AppColors.borderLight),
                                    // Revision scheduler switch
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              (_topicScheduleRevisions[topic.id] ?? true)
                                                  ? Icons.event_repeat_rounded
                                                  : Icons.event_busy_rounded,
                                              size: 14,
                                              color: (_topicScheduleRevisions[topic.id] ?? true)
                                                  ? AppColors.gold
                                                  : AppColors.textMuted,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Schedule Revision (Forgetting Curve)',
                                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                        Transform.scale(
                                          scale: 0.75,
                                          child: Switch(
                                            value: _topicScheduleRevisions[topic.id] ?? true,
                                            activeColor: AppColors.gold,
                                            onChanged: (val) {
                                              setState(() {
                                                _topicScheduleRevisions[topic.id] = val;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_topicScheduleRevisions[topic.id] ?? true) ...[
                                      const SizedBox(height: 4),
                                      _buildForgettingCurveTimeline(),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),

            // Notes
            Text(
              'Session Notes',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'What did you focus on? Write any key takeaways...',
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _logSession,
                child: Text(
                  'Log Study Session',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExamButton(String type, String label) {
    final isSelected = _examType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _examType = type;
            _selectedSubject = null; // resets subject
            _selectedTopics.clear();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.goldSurface : AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.gold : AppColors.border,
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.gold : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(double minutes) {
    final hours = minutes / 60;
    if (hours == hours.toInt()) {
      return '${hours.toInt()} hrs';
    }
    final hrsInt = hours.toInt();
    final minsInt = (minutes % 60).toInt();
    if (hrsInt == 0) return '$minsInt mins';
    return '$hrsInt hr $minsInt min';
  }

  Widget _buildTopicStatusToggleChip(Topic topic) {
    final status = _topicStatuses[topic.id] ?? TopicStatus.completed;
    final isCompleted = status == TopicStatus.completed;
    return GestureDetector(
      onTap: () {
        setState(() {
          _topicStatuses[topic.id] = isCompleted ? TopicStatus.inProgress : TopicStatus.completed;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.green.withOpacity(0.12) : AppColors.blue.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isCompleted ? AppColors.green : AppColors.blue,
            width: 1,
          ),
        ),
        child: Text(
          isCompleted ? 'Done' : 'Doing',
          style: GoogleFonts.inter(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isCompleted ? AppColors.green : AppColors.blue,
          ),
        ),
      ),
    );
  }

  void _logSession() async {
    if (_selectedSubject == null) return;

    final uuid = const Uuid();

    final studySession = ss.StudySession(
      id: uuid.v4(),
      date: _selectedDate,
      subjectId: _selectedSubject!.id,
      subjectName: _selectedSubject!.title,
      sectionId: _selectedSubject!.sectionId,
      sectionName: _selectedSubject!.sectionId.toUpperCase().replaceAll('_', ' '),
      durationMinutes: _durationMinutes,
      topicsCovered: _selectedTopics.map((t) => t.title).toList(),
      examType: _examType,
      startTime: ss.TimeOfDay(hour: _selectedDate.hour, minute: _selectedDate.minute),
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      shift: _selectedShift,
    );

    // Save study session
    await widget.ref.read(sessionProvider.notifier).addSession(studySession);

    // Mark selected topics as completed & schedule forgetting curve revisions
    final syllabusNotifier = widget.ref.read(syllabusProvider.notifier);
    final revisionNotifier = widget.ref.read(revisionProvider.notifier);
    final existingRevisions = widget.ref.read(revisionProvider);

    for (final topic in _selectedTopics) {
      final status = _topicStatuses[topic.id] ?? TopicStatus.completed;
      final progress = _topicProgresses[topic.id] ?? (status == TopicStatus.completed ? 1.0 : topic.progressPercent > 0.0 ? topic.progressPercent : 0.30);
      
      await syllabusNotifier.updateTopicStatus(topic.id, status, _examType, progressPercent: progress);
      
      // Auto-schedule revision item based on forgetting curve, IF user kept "Schedule Revision" enabled
      final shouldSchedule = _topicScheduleRevisions[topic.id] ?? true;
      if (shouldSchedule) {
        final alreadyExists = existingRevisions.any((r) => r.topicId == topic.id);
        if (!alreadyExists) {
          final revItem = RevisionItem(
            id: uuid.v4(),
            topicId: topic.id,
            topicTitle: topic.title,
            subjectName: _selectedSubject!.title,
            sectionName: _selectedSubject!.sectionId.toUpperCase().replaceAll('_', ' '),
            subjectId: _selectedSubject!.id,
            examType: _examType,
            nextDueDate: _selectedDate.add(const Duration(days: 1)), // Next review tomorrow (1 day)
            easeFactor: 2.5,
            intervalDays: 1,
          );
          await revisionNotifier.addRevisionItem(revItem);
        }
      }
    }

    Navigator.pop(context);
  }

  Widget _buildShiftChip(String shiftValue, String label) {
    final isSelected = _selectedShift == shiftValue;
    return GestureDetector(
      onTap: () => setState(() => _selectedShift = shiftValue),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldSurface : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? AppColors.gold : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  String _getShiftHint(String shift) {
    if (shift == 'morning') {
      return '🌅 Morning shift is considered from 5:00 AM to 12:00 PM';
    } else if (shift == 'afternoon') {
      return '☀️ Afternoon shift is considered from 12:00 PM to 5:00 PM';
    } else if (shift == 'evening') {
      return '🌇 Evening shift is considered from 5:00 PM to 9:00 PM';
    } else {
      return '🌙 Night shift is considered from 9:00 PM to 5:00 AM';
    }
  }

  Widget _buildForgettingCurveTimeline() {
    final baseDate = _selectedDate;
    final now = DateTime.now();
    final dates = [
      (1, '1st Review', baseDate.add(const Duration(days: 1))),
      (2, '2nd Review', baseDate.add(const Duration(days: 3))),
      (3, '3rd Review', baseDate.add(const Duration(days: 8))),
      (4, '4th Review', baseDate.add(const Duration(days: 20))),
      (5, '5th Review', baseDate.add(const Duration(days: 50))),
    ];

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.goldSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, size: 13, color: AppColors.gold),
              const SizedBox(width: 6),
              Text(
                'Projected Forgetting Curve Timeline',
                style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.gold, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...dates.map((d) {
            final dateStr = '${d.$3.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.$3.month - 1]}';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Row(
                children: [
                  Container(
                    width: 4, height: 4,
                    decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${d.$2}: ',
                    style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$dateStr (In ${d.$3.difference(now).inDays} days)',
                    style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
