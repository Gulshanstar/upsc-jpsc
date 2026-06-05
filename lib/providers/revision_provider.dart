import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/revision_item.dart';
import '../utils/supabase_service.dart';
import 'user_provider.dart';
import 'session_provider.dart';
import '../models/user_profile.dart';

final revisionProvider =
    StateNotifierProvider<RevisionNotifier, List<RevisionItem>>((ref) {
  return RevisionNotifier(ref);
});

class RevisionNotifier extends StateNotifier<List<RevisionItem>> {
  final Ref ref;
  RevisionNotifier(this.ref) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();

    if (SupabaseService.instance.isAuthenticated) {
      final cloudRevisions = await SupabaseService.instance.fetchRevisionItems();
      state = cloudRevisions;
      await _saveLocalOnly();
      return;
    }

    final json = prefs.getString('revision_items');
    if (json != null) {
      final list = jsonDecode(json) as List;
      state = list.map((e) => RevisionItem.fromJson(e)).toList();
    } else {
      // Import mock data to seed initial revisions
      final mockData = seedMockRevisionsIfNeeded();
      state = mockData;
      await _saveLocalOnly();
    }
  }

  List<RevisionItem> seedMockRevisionsIfNeeded() {
    final now = DateTime.now();
    return [
      RevisionItem(
        id: 'r1', topicId: 'gs1_indian_heritage_0',
        topicTitle: 'Indus Valley Civilisation',
        subjectName: 'Indian Heritage', sectionName: 'GS-1',
        subjectId: 'gs1_indian_heritage', examType: 'upsc',
        nextDueDate: now, lastReviewedDate: now.subtract(const Duration(days: 3)),
        revisionCount: 2, intervalDays: 3, reviewHistory: [true, true],
      ),
      RevisionItem(
        id: 'r2', topicId: 'gs2_polity_2',
        topicTitle: 'Parliamentary System',
        subjectName: 'Polity', sectionName: 'GS-2',
        subjectId: 'gs2_polity', examType: 'upsc',
        nextDueDate: now, lastReviewedDate: now.subtract(const Duration(days: 1)),
        revisionCount: 1, intervalDays: 1, reviewHistory: [false],
      ),
      RevisionItem(
        id: 'r3', topicId: 'gs3_economy_2',
        topicTitle: 'GDP, GNP, NNP — Concepts',
        subjectName: 'Indian Economy', sectionName: 'GS-3',
        subjectId: 'gs3_economy', examType: 'upsc',
        nextDueDate: now, lastReviewedDate: now.subtract(const Duration(days: 7)),
        revisionCount: 3, intervalDays: 7, reviewHistory: [true, true, false],
      ),
      RevisionItem(
        id: 'r4', topicId: 'gs1_geography_2',
        topicTitle: 'Plate Tectonics',
        subjectName: 'Geography', sectionName: 'GS-1',
        subjectId: 'gs1_geography', examType: 'upsc',
        nextDueDate: now.add(const Duration(days: 2)),
        lastReviewedDate: now.subtract(const Duration(days: 5)),
        revisionCount: 2, intervalDays: 7, reviewHistory: [true, true],
      ),
      RevisionItem(
        id: 'r5', topicId: 'jpsc_jh_history_2',
        topicTitle: 'Birsa Munda Movement',
        subjectName: 'Jharkhand History', sectionName: 'Pre GS-II',
        subjectId: 'jpsc_jh_history', examType: 'jpsc',
        nextDueDate: now.add(const Duration(days: 1)),
        lastReviewedDate: now.subtract(const Duration(days: 2)),
        revisionCount: 1, intervalDays: 3, reviewHistory: [true],
      ),
    ];
  }

  Future<void> _saveLocalOnly() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'revision_items', jsonEncode(state.map((r) => r.toJson()).toList()));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'revision_items', jsonEncode(state.map((r) => r.toJson()).toList()));
    // Sync with Supabase in the background
    await SupabaseService.instance.syncRevisionItems(state);
  }

  List<RevisionItem> get filteredState {
    final profile = ref.read(userProfileProvider);
    final sessions = ref.read(sessionProvider);
    
    // Keep all revision items (representing real data)
    var list = state;

    if (profile.preparationStartDate != null) {
      final startOfPrep = DateTime(
        profile.preparationStartDate!.year,
        profile.preparationStartDate!.month,
        profile.preparationStartDate!.day,
      );
      list = list.where((r) {
        final dateToCheck = r.lastReviewedDate ?? r.nextDueDate;
        final startOfDate = DateTime(dateToCheck.year, dateToCheck.month, dateToCheck.day);
        return startOfDate.isAfter(startOfPrep.subtract(const Duration(seconds: 1)));
      }).toList();
    }
    if (profile.examMode == ExamMode.upsc) {
      list = list.where((r) => r.examType == 'upsc').toList();
    } else if (profile.examMode == ExamMode.jpsc) {
      list = list.where((r) => r.examType == 'jpsc').toList();
    }
    return list;
  }

  List<RevisionItem> get dueToday =>
      filteredState.where((r) => r.isDueToday).toList();

  List<RevisionItem> get overdue =>
      filteredState.where((r) => r.isOverdue).toList();

  List<RevisionItem> upcomingDays(int days) {
    final cutoff = DateTime.now().add(Duration(days: days));
    return filteredState
        .where((r) => !r.isDueToday && r.nextDueDate.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.nextDueDate.compareTo(b.nextDueDate));
  }

  Future<void> addRevisionItem(RevisionItem item) async {
    state = [...state, item];
    await _save();
  }

  Future<void> reviewItem(String id, bool remembered) async {
    state = state.map((r) {
      if (r.id == id) {
        if (!r.isDueToday && !r.isOverdue) {
          return r;
        }
        r.updateAfterReview(remembered);
        return r;
      }
      return r;
    }).toList();
    await _save();
  }

  Future<void> revertReview(String id, DateTime? prevLastReviewedDate, int prevIntervalDays, double prevEaseFactor) async {
    state = state.map((r) {
      if (r.id == id) {
        r.revertLastReview(prevLastReviewedDate, prevIntervalDays, prevEaseFactor);
        return r;
      }
      return r;
    }).toList();
    await _save();
  }

  Future<void> toggleLockRevision(String id) async {
    state = state.map((r) {
      if (r.id == id) {
        r.lockedForEver = !r.lockedForEver;
        return r;
      }
      return r;
    }).toList();
    await _save();
  }

  Future<void> removeItem(String id) async {
    state = state.where((r) => r.id != id).toList();
    await _save();
    if (SupabaseService.instance.isAuthenticated) {
      try {
        await SupabaseService.instance.client
            .from('revision_items')
            .delete()
            .eq('id', id);
      } catch (e) {
        debugPrint('Error deleting revision item from Supabase: $e');
      }
    }
  }

  Future<void> clearRevisionsInRange(DateTime start, DateTime end) async {
    final startOfDay = DateTime(start.year, start.month, start.day);
    final endOfDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final toDelete = state.where((r) {
      if (r.lastReviewedDate != null) {
        return r.lastReviewedDate!.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
               r.lastReviewedDate!.isBefore(endOfDay.add(const Duration(seconds: 1)));
      } else {
        final created = r.nextDueDate.subtract(Duration(days: r.intervalDays));
        return created.isAfter(startOfDay.subtract(const Duration(seconds: 1))) &&
               created.isBefore(endOfDay.add(const Duration(seconds: 1)));
      }
    }).toList();

    state = state.where((r) {
      if (r.lastReviewedDate != null) {
        return r.lastReviewedDate!.isBefore(startOfDay) || r.lastReviewedDate!.isAfter(endOfDay);
      } else {
        final created = r.nextDueDate.subtract(Duration(days: r.intervalDays));
        return created.isBefore(startOfDay) || created.isAfter(endOfDay);
      }
    }).toList();

    await _save();

    if (SupabaseService.instance.isAuthenticated) {
      try {
        for (final item in toDelete) {
          await SupabaseService.instance.client
              .from('revision_items')
              .delete()
              .eq('id', item.id);
        }
        debugPrint('Deleted revision items in range from Supabase.');
      } catch (e) {
        debugPrint('Error deleting revision items in range from Supabase: $e');
      }
    }
  }

  double get weeklyRecallRate {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recent = filteredState.where((r) =>
        r.lastReviewedDate != null &&
        r.lastReviewedDate!.isAfter(weekAgo));
    if (recent.isEmpty) return 0;
    final total = recent.fold<int>(0, (s, r) => s + r.reviewHistory.length);
    final correct = recent.fold<int>(
        0, (s, r) => s + r.reviewHistory.where((x) => x).length);
    return total == 0 ? 0 : correct / total;
  }

  int get totalRevisedThisWeek {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return filteredState
        .where((r) =>
            r.lastReviewedDate != null &&
            r.lastReviewedDate!.isAfter(weekAgo))
        .length;
  }
}
