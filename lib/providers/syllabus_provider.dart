import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/topic.dart';
import '../data/syllabus_data.dart';

final syllabusProvider =
    StateNotifierProvider<SyllabusNotifier, SyllabusState>((ref) {
  return SyllabusNotifier();
});

class SyllabusState {
  final List<Section> upscSections;
  final List<Section> jpscSections;
  final bool isLoaded;

  SyllabusState({
    required this.upscSections,
    required this.jpscSections,
    this.isLoaded = false,
  });

  List<Section> sectionsFor(String examType) {
    if (examType == 'upsc') return upscSections;
    if (examType == 'jpsc') return jpscSections;
    return [...upscSections, ...jpscSections];
  }

  int get totalUpscTopics =>
      upscSections.expand((s) => s.allTopics).length;
  int get totalJpscTopics =>
      jpscSections.expand((s) => s.allTopics).length;

  int completedUpscTopics() =>
      upscSections
          .expand((s) => s.allTopics)
          .where((t) => t.status == TopicStatus.completed)
          .length;
  int completedJpscTopics() =>
      jpscSections
          .expand((s) => s.allTopics)
          .where((t) => t.status == TopicStatus.completed)
          .length;

  double get upscProgress =>
      totalUpscTopics == 0 ? 0 : completedUpscTopics() / totalUpscTopics;
  double get jpscProgress =>
      totalJpscTopics == 0 ? 0 : completedJpscTopics() / totalJpscTopics;

  Topic? findTopic(String topicId) {
    for (final s in [...upscSections, ...jpscSections]) {
      for (final sub in s.subjects) {
        for (final t in sub.topics) {
          if (t.id == topicId) return t;
        }
      }
    }
    return null;
  }
}

class SyllabusNotifier extends StateNotifier<SyllabusState> {
  SyllabusNotifier()
      : super(SyllabusState(upscSections: [], jpscSections: [])) {
    _load();
  }

  Future<void> _load() async {
    final upsc = buildUPSCSyllabus();
    final jpsc = buildJPSCSyllabus();

    final prefs = await SharedPreferences.getInstance();
    
    // One-time database migration cleanup to wipe legacy stuck progress
    if (prefs.getBool('legacy_cleanup_done_v3') != true) {
      await prefs.remove('topic_statuses');
      await prefs.remove('revision_items');
      await prefs.remove('study_sessions');
      await prefs.setBool('legacy_cleanup_done_v3', true);
    }

    final savedJson = prefs.getString('topic_statuses');
    if (savedJson != null) {
      final Map<String, dynamic> saved = jsonDecode(savedJson);
      _applyStatuses([...upsc, ...jpsc], saved);
    }

    state = SyllabusState(
      upscSections: upsc,
      jpscSections: jpsc,
      isLoaded: true,
    );
  }

  void _applyStatuses(List<Section> sections, Map<String, dynamic> saved) {
    for (final section in sections) {
      for (final subject in section.subjects) {
        for (final topic in subject.topics) {
          if (saved.containsKey(topic.id)) {
            final data = saved[topic.id] as Map<String, dynamic>;
            topic.status = TopicStatus.values[data['status'] ?? 0];
            topic.notes = data['notes'];
            topic.revisionCount = data['revisionCount'] ?? 0;
            topic.progressPercent = (data['progressPercent'] as num?)?.toDouble() ?? 
                (topic.status == TopicStatus.completed ? 1.0 : 0.0);
            if (data['lastStudied'] != null) {
              topic.lastStudied = DateTime.parse(data['lastStudied']);
            }
            if (data['nextRevisionDate'] != null) {
              topic.nextRevisionDate = DateTime.parse(data['nextRevisionDate']);
            }
          }
        }
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> statuses = {};
    for (final s in [...state.upscSections, ...state.jpscSections]) {
      for (final sub in s.subjects) {
        for (final t in sub.topics) {
          statuses[t.id] = {
            'status': t.status.index,
            'notes': t.notes,
            'revisionCount': t.revisionCount,
            'lastStudied': t.lastStudied?.toIso8601String(),
            'nextRevisionDate': t.nextRevisionDate?.toIso8601String(),
            'progressPercent': t.progressPercent,
          };
        }
      }
    }
    await prefs.setString('topic_statuses', jsonEncode(statuses));
  }

  Future<void> updateTopicStatus(
      String topicId, TopicStatus status, String examType, {double? progressPercent}) async {
    final sections = examType == 'upsc' ? state.upscSections : state.jpscSections;
    for (final s in sections) {
      for (final sub in s.subjects) {
        for (final t in sub.topics) {
          if (t.id == topicId) {
            t.status = status;
            t.lastStudied = DateTime.now();
            if (progressPercent != null) {
              t.progressPercent = progressPercent;
            } else if (status == TopicStatus.completed) {
              t.progressPercent = 1.0;
            } else if (status == TopicStatus.notStarted) {
              t.progressPercent = 0.0;
            }
          }
        }
      }
    }
    state = SyllabusState(
      upscSections: state.upscSections,
      jpscSections: state.jpscSections,
      isLoaded: true,
    );
    await _save();
  }

  Future<void> updateTopicNotes(
      String topicId, String notes, String examType) async {
    final sections = examType == 'upsc' ? state.upscSections : state.jpscSections;
    for (final s in sections) {
      for (final sub in s.subjects) {
        for (final t in sub.topics) {
          if (t.id == topicId) t.notes = notes;
        }
      }
    }
    state = SyllabusState(
      upscSections: state.upscSections,
      jpscSections: state.jpscSections,
      isLoaded: true,
    );
    await _save();
  }

  Future<void> resetAllStatuses() async {
    for (final s in [...state.upscSections, ...state.jpscSections]) {
      for (final sub in s.subjects) {
        for (final t in sub.topics) {
          t.status = TopicStatus.notStarted;
          t.notes = null;
          t.lastStudied = null;
          t.nextRevisionDate = null;
          t.revisionCount = 0;
          t.progressPercent = 0.0;
        }
      }
    }
    state = SyllabusState(
      upscSections: state.upscSections,
      jpscSections: state.jpscSections,
      isLoaded: true,
    );
    await _save();
  }

  Future<void> resetStatusesInRange(DateTime start, DateTime end) async {
    // Start of day for start, end of day for end
    final startUtc = DateTime(start.year, start.month, start.day, 0, 0, 0);
    final endUtc = DateTime(end.year, end.month, end.day, 23, 59, 59);

    for (final s in [...state.upscSections, ...state.jpscSections]) {
      for (final sub in s.subjects) {
        for (final t in sub.topics) {
          if (t.lastStudied != null &&
              t.lastStudied!.isAfter(startUtc.subtract(const Duration(seconds: 1))) &&
              t.lastStudied!.isBefore(endUtc.add(const Duration(seconds: 1)))) {
            t.status = TopicStatus.notStarted;
            t.notes = null;
            t.lastStudied = null;
            t.nextRevisionDate = null;
            t.revisionCount = 0;
            t.progressPercent = 0.0;
          }
        }
      }
    }
    state = SyllabusState(
      upscSections: state.upscSections,
      jpscSections: state.jpscSections,
      isLoaded: true,
    );
    await _save();
  }

  Future<void> resetTopicsByTitles(Set<String> titles) async {
    for (final s in [...state.upscSections, ...state.jpscSections]) {
      for (final sub in s.subjects) {
        for (final t in sub.topics) {
          if (titles.contains(t.title)) {
            t.status = TopicStatus.notStarted;
            t.notes = null;
            t.lastStudied = null;
            t.nextRevisionDate = null;
            t.revisionCount = 0;
            t.progressPercent = 0.0;
          }
        }
      }
    }
    state = SyllabusState(
      upscSections: state.upscSections,
      jpscSections: state.jpscSections,
      isLoaded: true,
    );
    await _save();
  }
}
