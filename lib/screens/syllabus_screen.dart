import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';
import '../providers/syllabus_provider.dart';
import '../models/topic.dart';
import '../providers/user_provider.dart';
import '../models/user_profile.dart';
import '../providers/revision_provider.dart';

class SyllabusScreen extends ConsumerStatefulWidget {
  const SyllabusScreen({super.key});

  @override
  ConsumerState<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends ConsumerState<SyllabusScreen> {
  String _filter = 'All';
  String _search = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syllabusState = ref.watch(syllabusProvider);
    final profile = ref.watch(userProfileProvider);
    final examMode = profile.examMode;
    final isBoth = examMode == ExamMode.both;

    Widget scaffoldContent = Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: Text('Syllabus', style: GoogleFonts.instrumentSerif(fontSize: 24)),
            backgroundColor: AppColors.background,
            floating: true,
            snap: true,
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(isBoth ? 100 : 60),
              child: Column(
                children: [
                  // Search
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: 'Search topics...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: _search.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _search = '');
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  if (isBoth)
                    TabBar(
                      indicatorColor: AppColors.gold,
                      labelColor: AppColors.gold,
                      unselectedLabelColor: AppColors.textMuted,
                      labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                      tabs: const [Tab(text: 'UPSC'), Tab(text: 'JPSC')],
                    ),
                ],
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            // Filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['All', 'Not Started', 'In Progress', 'Completed', 'Needs Revision']
                      .map((f) => GestureDetector(
                            onTap: () => setState(() => _filter = f),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _filter == f ? AppColors.goldSurface : AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _filter == f ? AppColors.gold : AppColors.border,
                                  width: _filter == f ? 1.2 : 1,
                                ),
                              ),
                              child: Text(f,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: _filter == f ? AppColors.gold : AppColors.textMuted,
                                  )),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ),
            Expanded(
              child: isBoth
                  ? TabBarView(
                      children: [
                        _SectionList(
                          sections: syllabusState.upscSections,
                          filter: _filter,
                          search: _search,
                          ref: ref,
                        ),
                        _SectionList(
                          sections: syllabusState.jpscSections,
                          filter: _filter,
                          search: _search,
                          ref: ref,
                        ),
                      ],
                    )
                  : _SectionList(
                      sections: examMode == ExamMode.upsc
                          ? syllabusState.upscSections
                          : syllabusState.jpscSections,
                      filter: _filter,
                      search: _search,
                      ref: ref,
                    ),
            ),
          ],
        ),
      ),
    );

    if (isBoth) {
      return DefaultTabController(
        length: 2,
        child: scaffoldContent,
      );
    }
    return scaffoldContent;
  }
}

class _SectionList extends StatelessWidget {
  final List<Section> sections;
  final String filter;
  final String search;
  final WidgetRef ref;

  const _SectionList({
    required this.sections,
    required this.filter,
    required this.search,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: sections.length,
      itemBuilder: (context, i) {
        return _SectionCard(section: sections[i], filter: filter, search: search, ref: ref)
            .animate().fadeIn(delay: Duration(milliseconds: i * 60), duration: 300.ms);
      },
    );
  }
}

class _SectionCard extends StatefulWidget {
  final Section section;
  final String filter;
  final String search;
  final WidgetRef ref;
  const _SectionCard({required this.section, required this.filter, required this.search, required this.ref});

  @override
  State<_SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<_SectionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final section = widget.section;
    final profile = widget.ref.watch(userProfileProvider);
    
    // Filter subjects
    List<Subject> subjectsToShow = section.subjects;
    if (section.id == 'upsc_optional') {
      if (profile.optionalSubject != null) {
        subjectsToShow = section.subjects.where((sub) => sub.title == profile.optionalSubject).toList();
      } else {
        subjectsToShow = [];
      }
    }
    
    final allTopicsToShow = subjectsToShow.expand((s) => s.topics).toList();
    
    final doneCount = allTopicsToShow.where((t) => t.status == TopicStatus.completed).length;
    final inProgressCount = allTopicsToShow.where((t) => t.status == TopicStatus.inProgress).length;
    final leftCount = allTopicsToShow.where((t) => t.status == TopicStatus.notStarted).length;
    
    final progress = allTopicsToShow.isEmpty ? 0.0 : doneCount / allTopicsToShow.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(section.shortName,
                                style: GoogleFonts.inter(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
                            const SizedBox(height: 2),
                            Text(section.title,
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                      Text('${(progress * 100).toInt()}%',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: _progressColor(progress))),
                      const SizedBox(width: 8),
                      Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textMuted, size: 20),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      backgroundColor: AppColors.surfaceElevated,
                      valueColor: AlwaysStoppedAnimation<Color>(_progressColor(progress)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _StatusDot(AppColors.green, '$doneCount done'),
                      const SizedBox(width: 12),
                      _StatusDot(AppColors.blue, '$inProgressCount in progress'),
                      const SizedBox(width: 12),
                      _StatusDot(AppColors.textMuted, '$leftCount left'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.border),
            if (subjectsToShow.isEmpty && section.id == 'upsc_optional')
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'No optional subject selected in Settings.',
                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                  ),
                ),
              )
            else
              ...subjectsToShow.map((sub) => _SubjectTile(subject: sub, filter: widget.filter, search: widget.search, ref: widget.ref)),
          ],
        ],
      ),
    );
  }

  Color _progressColor(double p) {
    if (p >= 0.8) return AppColors.green;
    if (p >= 0.4) return AppColors.gold;
    return AppColors.blue;
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;
  final String label;
  const _StatusDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

class _SubjectTile extends StatefulWidget {
  final Subject subject;
  final String filter;
  final String search;
  final WidgetRef ref;
  const _SubjectTile({required this.subject, required this.filter, required this.search, required this.ref});

  @override
  State<_SubjectTile> createState() => _SubjectTileState();
}

class _SubjectTileState extends State<_SubjectTile> {
  bool _expanded = false;

  List<Topic> get _filteredTopics {
    var topics = widget.subject.topics;
    if (widget.search.isNotEmpty) {
      topics = topics.where((t) => t.title.toLowerCase().contains(widget.search.toLowerCase())).toList();
    }
    if (widget.filter != 'All') {
      final statusMap = {
        'Not Started': TopicStatus.notStarted,
        'In Progress': TopicStatus.inProgress,
        'Completed': TopicStatus.completed,
        'Needs Revision': TopicStatus.needsRevision,
      };
      final status = statusMap[widget.filter];
      if (status != null) topics = topics.where((t) => t.status == status).toList();
    }
    return topics;
  }

  @override
  Widget build(BuildContext context) {
    final sub = widget.subject;
    final filtered = _filteredTopics;
    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Text(sub.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(sub.title,
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text('${sub.completedCount}/${sub.topics.length} topics',
                          style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 40, height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: sub.completionPercent,
                        strokeWidth: 3,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          sub.completionPercent >= 0.8 ? AppColors.green : AppColors.gold,
                        ),
                      ),
                      Text('${(sub.completionPercent * 100).toInt()}',
                          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(_expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppColors.textMuted, size: 18),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...filtered.map((t) => _TopicRow(topic: t, ref: widget.ref)),
        const Divider(height: 1, color: AppColors.borderLight, indent: 16, endIndent: 16),
      ],
    );
  }
}

class _TopicRow extends ConsumerWidget {
  final Topic topic;
  final WidgetRef ref;
  const _TopicRow({required this.topic, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revisions = ref.watch(revisionProvider);
    final hasOverdueRevision = revisions.any((r) =>
        r.topicTitle.toLowerCase() == topic.title.toLowerCase() && r.isOverdue);

    return GestureDetector(
      onTap: () => _showTopicSheet(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(48, 8, 16, 8),
        child: Row(
          children: [
            _StatusIcon(hasOverdueRevision ? TopicStatus.needsRevision : topic.status, isOverdue: hasOverdueRevision),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(topic.title,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: topic.status == TopicStatus.completed
                                  ? AppColors.textMuted
                                  : AppColors.textPrimary,
                              decoration: topic.status == TopicStatus.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            )),
                      ),
                      if (hasOverdueRevision) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.red.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            'OVERDUE',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (topic.status == TopicStatus.inProgress && topic.progressPercent > 0.0 && topic.progressPercent < 1.0) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          height: 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(1.5),
                            child: LinearProgressIndicator(
                              value: topic.progressPercent,
                              backgroundColor: AppColors.borderLight,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(topic.progressPercent * 100).toInt()}% covered',
                          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (topic.notes != null && topic.notes!.isNotEmpty)
              const Icon(Icons.note_outlined, size: 14, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showTopicSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TopicDetailSheet(topic: topic, ref: ref),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final TopicStatus status;
  final bool isOverdue;
  const _StatusIcon(this.status, {this.isOverdue = false});

  @override
  Widget build(BuildContext context) {
    if (isOverdue) {
      return const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.red);
    }
    switch (status) {
      case TopicStatus.completed:
        return const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.green);
      case TopicStatus.inProgress:
        return const Icon(Icons.radio_button_checked_rounded, size: 18, color: AppColors.blue);
      case TopicStatus.needsRevision:
        return const Icon(Icons.refresh_rounded, size: 18, color: AppColors.gold);
      case TopicStatus.notStarted:
        return const Icon(Icons.radio_button_unchecked_rounded, size: 18, color: AppColors.textMuted);
    }
  }
}

class _TopicDetailSheet extends StatefulWidget {
  final Topic topic;
  final WidgetRef ref;
  const _TopicDetailSheet({required this.topic, required this.ref});

  @override
  State<_TopicDetailSheet> createState() => _TopicDetailSheetState();
}

class _TopicDetailSheetState extends State<_TopicDetailSheet> {
  late TopicStatus _status;
  late double _progressPercent;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _status = widget.topic.status;
    _progressPercent = widget.topic.progressPercent > 0.0 && widget.topic.progressPercent < 1.0
        ? widget.topic.progressPercent
        : 0.30; // Default to 30% if In Progress
    _notesController = TextEditingController(text: widget.topic.notes ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(widget.topic.title,
                          style: GoogleFonts.instrumentSerif(fontSize: 20, color: AppColors.textPrimary)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Text(widget.topic.subjectId,
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 20),
                Text('Status', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: TopicStatus.values.map((s) {
                    final isSelected = _status == s;
                    final info = _statusInfo(s);
                    return GestureDetector(
                      onTap: () => setState(() => _status = s),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? info.$2.withOpacity(0.15) : AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isSelected ? info.$2 : AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(info.$1, size: 14, color: isSelected ? info.$2 : AppColors.textMuted),
                            const SizedBox(width: 6),
                            Text(info.$3,
                                style: GoogleFonts.inter(fontSize: 12, color: isSelected ? info.$2 : AppColors.textMuted, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_status == TopicStatus.inProgress) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Completion Progress', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                      Text('${(_progressPercent * 100).toInt()}%', style: GoogleFonts.inter(fontSize: 13, color: AppColors.blue, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Slider(
                    value: _progressPercent,
                    min: 0.10,
                    max: 0.90,
                    divisions: 8,
                    activeColor: AppColors.blue,
                    inactiveColor: AppColors.surfaceElevated,
                    onChanged: (v) => setState(() => _progressPercent = v),
                  ),
                ],
                if (_status == TopicStatus.inProgress || _status == TopicStatus.needsRevision) ...[
                  const SizedBox(height: 12),
                  _buildForgettingCurveTimeline(),
                ],
                const SizedBox(height: 20),
                Text('Notes', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(hintText: 'Add notes, key points...'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color, String) _statusInfo(TopicStatus s) {
    switch (s) {
      case TopicStatus.notStarted:
        return (Icons.radio_button_unchecked_rounded, AppColors.textMuted, 'Not Started');
      case TopicStatus.inProgress:
        return (Icons.radio_button_checked_rounded, AppColors.blue, 'In Progress');
      case TopicStatus.completed:
        return (Icons.check_circle_rounded, AppColors.green, 'Completed');
      case TopicStatus.needsRevision:
        return (Icons.refresh_rounded, AppColors.gold, 'Needs Revision');
    }
  }

  void _save() {
    widget.ref.read(syllabusProvider.notifier).updateTopicStatus(
          widget.topic.id,
          _status,
          widget.topic.examType,
          progressPercent: _status == TopicStatus.inProgress
              ? _progressPercent
              : (_status == TopicStatus.completed ? 1.0 : 0.0),
        );
    if (_notesController.text.trim().isNotEmpty) {
      widget.ref.read(syllabusProvider.notifier)
          .updateTopicNotes(widget.topic.id, _notesController.text.trim(), widget.topic.examType);
    }
    Navigator.pop(context);
  }

  Widget _buildForgettingCurveTimeline() {
    final now = DateTime.now();
    final dates = [
      (1, '1st Review', now.add(const Duration(days: 1))),
      (2, '2nd Review', now.add(const Duration(days: 3))),
      (3, '3rd Review', now.add(const Duration(days: 8))),
      (4, '4th Review', now.add(const Duration(days: 20))),
      (5, '5th Review', now.add(const Duration(days: 50))),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.goldSurface.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded, size: 14, color: AppColors.gold),
              const SizedBox(width: 6),
              Text(
                'Projected Forgetting Curve Timeline',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...dates.map((d) {
            final dateStr = '${d.$3.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.$3.month - 1]}';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Row(
                children: [
                  Container(
                    width: 5, height: 5,
                    decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${d.$2}: ',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$dateStr (In ${d.$3.difference(now).inDays} days)',
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
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
