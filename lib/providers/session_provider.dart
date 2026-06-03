import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/study_session.dart';
import '../utils/supabase_service.dart';
import 'user_provider.dart';
import 'syllabus_provider.dart';
import '../models/user_profile.dart';

final sessionProvider =
    StateNotifierProvider<SessionNotifier, List<StudySession>>((ref) {
  return SessionNotifier(ref);
});

class SessionNotifier extends StateNotifier<List<StudySession>> {
  final Ref ref;
  SessionNotifier(this.ref) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    if (SupabaseService.instance.isAuthenticated) {
      final cloudSessions = await SupabaseService.instance.fetchStudySessions();
      state = cloudSessions;
      await _saveLocalOnly();
      return;
    }

    final json = prefs.getString('study_sessions');
    if (json != null) {
      final list = jsonDecode(json) as List;
      state = list.map((e) => StudySession.fromJson(e)).toList();
    } else {
      state = [];
      await _saveLocalOnly();
    }
  }

  Future<void> _saveLocalOnly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'study_sessions', jsonEncode(state.map((s) => s.toJson()).toList()));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'study_sessions', jsonEncode(state.map((s) => s.toJson()).toList()));
    // Sync with Supabase in the background
    await SupabaseService.instance.syncStudySessions(state);
  }

  Future<void> addSession(StudySession session) async {
    state = [session, ...state];
    await _save();
  }

  Future<void> deleteSession(String id) async {
    StudySession? deletedSession;
    for (final s in state) {
      if (s.id == id) {
        deletedSession = s;
        break;
      }
    }

    state = state.where((s) => s.id != id).toList();
    await _save();

    if (deletedSession != null) {
      final Set<String> deletedTopicTitles = Set<String>.from(deletedSession.topicsCovered);
      final Set<String> remainingTopicTitles = {};
      for (final s in state) {
        remainingTopicTitles.addAll(s.topicsCovered);
      }
      final Set<String> topicsToReset = deletedTopicTitles.difference(remainingTopicTitles);
      if (topicsToReset.isNotEmpty) {
        await ref.read(syllabusProvider.notifier).resetTopicsByTitles(topicsToReset);
      }
    }

    if (SupabaseService.instance.isAuthenticated) {
      try {
        await SupabaseService.instance.client
            .from('study_sessions')
            .delete()
            .eq('id', id);
      } catch (e) {
        debugPrint('Error deleting study session from Supabase: $e');
      }
    }
  }

  Future<void> deleteSessionsInRange(DateTime start, DateTime end) async {
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final toDelete = state.where((s) {
      return s.date.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
             s.date.isBefore(endOfDay.add(const Duration(seconds: 1)));
    }).toList();

    state = state.where((s) {
      return s.date.isBefore(startOfDay) || s.date.isAfter(endOfDay);
    }).toList();

    await _save();

    // Reset syllabus topic progress for any topics whose only study sessions were deleted!
    final Set<String> deletedTopicTitles = {};
    for (final s in toDelete) {
      deletedTopicTitles.addAll(s.topicsCovered);
    }

    final Set<String> remainingTopicTitles = {};
    for (final s in state) {
      remainingTopicTitles.addAll(s.topicsCovered);
    }

    final Set<String> topicsToReset = deletedTopicTitles.difference(remainingTopicTitles);

    if (topicsToReset.isNotEmpty) {
      await ref.read(syllabusProvider.notifier).resetTopicsByTitles(topicsToReset);
    }

    if (SupabaseService.instance.isAuthenticated) {
      try {
        for (final s in toDelete) {
          await SupabaseService.instance.client
              .from('study_sessions')
              .delete()
              .eq('id', s.id);
        }
        debugPrint('Deleted sessions in range from Supabase.');
      } catch (e) {
        debugPrint('Error deleting sessions in range from Supabase: $e');
      }
    }
  }

  List<StudySession> get filteredState {
    final profile = ref.read(userProfileProvider);
    var list = state;
    if (profile.preparationStartDate != null) {
      final startOfPrep = DateTime(
        profile.preparationStartDate!.year,
        profile.preparationStartDate!.month,
        profile.preparationStartDate!.day,
      );
      list = list.where((s) {
        final startOfSession = DateTime(s.date.year, s.date.month, s.date.day);
        return startOfSession.isAfter(startOfPrep.subtract(const Duration(seconds: 1)));
      }).toList();
    }
    if (profile.examMode == ExamMode.upsc) {
      list = list.where((s) => s.examType == 'upsc').toList();
    } else if (profile.examMode == ExamMode.jpsc) {
      list = list.where((s) => s.examType == 'jpsc').toList();
    }
    return list;
  }

  // Analytics helpers
  List<StudySession> get todaySessions {
    final today = DateTime.now();
    return filteredState.where((s) =>
        s.date.year == today.year &&
        s.date.month == today.month &&
        s.date.day == today.day).toList();
  }

  double get todayHours =>
      todaySessions.fold(0.0, (sum, s) => sum + s.durationHours);

  Map<String, double> get hoursPerSubjectThisMonth {
    final now = DateTime.now();
    final monthSessions = filteredState.where(
        (s) => s.date.year == now.year && s.date.month == now.month);
    final Map<String, double> map = {};
    for (final s in monthSessions) {
      map[s.subjectName] = (map[s.subjectName] ?? 0) + s.durationHours;
    }
    return map;
  }

  List<double> get last14DaysHours {
    final now = DateTime.now();
    return List.generate(14, (i) {
      final day = now.subtract(Duration(days: 13 - i));
      return filteredState
          .where((s) =>
              s.date.year == day.year &&
              s.date.month == day.month &&
              s.date.day == day.day)
          .fold(0.0, (sum, s) => sum + s.durationHours);
    });
  }

  Map<int, double> get hoursByTimeOfDay {
    final Map<int, double> map = {};
    for (final s in filteredState) {
      final h = s.startTime.hour;
      map[h] = (map[h] ?? 0) + s.durationHours;
    }
    return map;
  }
}
