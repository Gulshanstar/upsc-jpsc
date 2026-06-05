import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/journal_entry.dart';
import 'package:uuid/uuid.dart';
import '../utils/supabase_service.dart';
import 'user_provider.dart';
import 'session_provider.dart';

final journeyProvider =
    StateNotifierProvider<JourneyNotifier, List<JournalEntry>>((ref) {
  return JourneyNotifier(ref);
});

class JourneyNotifier extends StateNotifier<List<JournalEntry>> {
  final Ref ref;
  JourneyNotifier(this.ref) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    if (SupabaseService.instance.isAuthenticated) {
      final cloudEntries = await SupabaseService.instance.fetchJournalEntries();
      state = cloudEntries;
      await _saveLocalOnly();
      return;
    }

    final json = prefs.getString('journal_entries');
    if (json != null) {
      final list = jsonDecode(json) as List;
      state = list.map((e) => JournalEntry.fromJson(e)).toList();
    } else {
      state = [];
      await _saveLocalOnly();
    }
  }

  Future<void> _saveLocalOnly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'journal_entries', jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'journal_entries', jsonEncode(state.map((e) => e.toJson()).toList()));
    // Sync with Supabase in the background
    await SupabaseService.instance.syncJournalEntries(state);
  }

  List<JournalEntry> get filteredState {
    final profile = ref.read(userProfileProvider);
    if (profile.preparationStartDate == null) return state;
    final startOfPrep = DateTime(
      profile.preparationStartDate!.year,
      profile.preparationStartDate!.month,
      profile.preparationStartDate!.day,
    );
    return state.where((e) {
      final startOfEntry = DateTime(e.date.year, e.date.month, e.date.day);
      return startOfEntry.isAfter(startOfPrep.subtract(const Duration(seconds: 1)));
    }).toList();
  }

  JournalEntry? entryForDay(DateTime day) {
    try {
      return filteredState.firstWhere((e) =>
          e.date.year == day.year &&
          e.date.month == day.month &&
          e.date.day == day.day);
    } catch (_) {
      return null;
    }
  }

  Future<void> upsertEntry(JournalEntry entry) async {
    final existing = state.indexWhere((e) =>
        e.date.year == entry.date.year &&
        e.date.month == entry.date.month &&
        e.date.day == entry.date.day);
    if (existing >= 0) {
      final updated = List<JournalEntry>.from(state);
      updated[existing] = entry;
      state = updated;
    } else {
      state = [entry, ...state];
    }
    await _save();
  }

  Future<void> clearJournalEntriesInRange(DateTime start, DateTime end) async {
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final toDelete = state.where((e) {
      return e.date.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
             e.date.isBefore(endOfDay.add(const Duration(seconds: 1)));
    }).toList();

    state = state.where((e) {
      return e.date.isBefore(startOfDay) || e.date.isAfter(endOfDay);
    }).toList();

    await _save();

    if (SupabaseService.instance.isAuthenticated) {
      try {
        for (final entry in toDelete) {
          await SupabaseService.instance.client
              .from('journal_entries')
              .delete()
              .eq('id', entry.id);
        }
        debugPrint('Deleted journal entries in range from Supabase.');
      } catch (e) {
        debugPrint('Error deleting journal entries in range from Supabase: $e');
      }
    }
  }

  int get currentStreak {
    int streak = 0;
    var day = DateTime.now();
    while (true) {
      final entry = entryForDay(day);
      if (entry != null && entry.didStudy) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int get longestStreak {
    int longest = 0;
    int current = 0;
    final sorted = [...filteredState]..sort((a, b) => a.date.compareTo(b.date));
    for (final e in sorted) {
      if (e.didStudy) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }
    return longest;
  }

  int get totalStudyDays => filteredState.where((e) => e.didStudy).length;

  int get missedDaysThisMonth {
    final now = DateTime.now();
    return filteredState.where((e) =>
        e.date.year == now.year &&
        e.date.month == now.month &&
        !e.didStudy).length;
  }

  double get avgHoursPerStudyDay {
    final studyDays = filteredState.where((e) => e.didStudy);
    if (studyDays.isEmpty) return 0;
    return studyDays.fold(0.0, (s, e) => s + e.hoursStudied) / studyDays.length;
  }

  Map<DateTime, double> get heatmapData {
    final Map<DateTime, double> map = {};
    for (final e in filteredState) {
      if (e.didStudy) {
        map[DateTime(e.date.year, e.date.month, e.date.day)] = e.hoursStudied;
      }
    }
    return map;
  }

  List<DateTime> get pendingGapDays {
    final profile = ref.read(userProfileProvider);
    if (profile.preparationStartDate == null) return [];

    final List<DateTime> pending = [];
    final now = DateTime.now();
    // Start from prep start date up to yesterday
    final startOfPrep = DateTime(
      profile.preparationStartDate!.year,
      profile.preparationStartDate!.month,
      profile.preparationStartDate!.day,
    );
    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));

    if (startOfPrep.isAfter(yesterday)) return [];

    final sessions = ref.read(sessionProvider);
    final hasExerciseEnabled = profile.dailyExerciseType != null;

    // NO grace period block: include all days up to yesterday in pendingGapDays.
    // This allows the user to see and choose to either "Log Session" or fill in the "Accountability" reason.
    var checkDay = startOfPrep;
    while (checkDay.isBefore(yesterday) || checkDay.isAtSameMomentAs(yesterday)) {
      final hasSession = sessions.any((s) =>
          s.date.year == checkDay.year &&
          s.date.month == checkDay.month &&
          s.date.day == checkDay.day);

      final journal = entryForDay(checkDay);
      final hasJournal = journal != null; // Either wrote note or gave reason

      // If exercise is configured, they must study OR complete daily exercise.
      // If they skipped both, they MUST register a missed study or missed exercise reason.
      if (hasExerciseEnabled) {
        final didExercise = journal?.didExercise == true;
        if (!hasSession && !didExercise && !hasJournal) {
          pending.add(checkDay);
        }
      } else {
        if (!hasSession && !hasJournal) {
          pending.add(checkDay);
        }
      }

      checkDay = checkDay.add(const Duration(days: 1));
    }
    return pending;
  }

  Future<void> registerGapReason(DateTime day, String reason) async {
    final profile = ref.read(userProfileProvider);
    final isExerciseEnabled = profile.dailyExerciseType != null;
    final entry = JournalEntry(
      id: const Uuid().v4(),
      date: day,
      didStudy: false,
      missedReason: reason,
      note: 'Missed study day reason: $reason',
      hoursStudied: 0.0,
      topicsCount: 0,
      didExercise: isExerciseEnabled ? false : null,
      missedExerciseReason: isExerciseEnabled ? reason : null,
    );
    await upsertEntry(entry);
  }
}
