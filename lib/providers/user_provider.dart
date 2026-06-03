import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../utils/supabase_service.dart';
import 'session_provider.dart';
import 'revision_provider.dart';
import 'journey_provider.dart';

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  return UserProfileNotifier(ref);
});

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final Ref ref;
  UserProfileNotifier(this.ref) : super(UserProfile.defaultProfile()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('user_profile');
    if (json != null) {
      state = UserProfile.fromJson(jsonDecode(json));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(state.toJson()));
    // Sync to cloud
    await SupabaseService.instance.syncProfile(state);
  }

  void invalidateAllData() {
    ref.invalidate(sessionProvider);
    ref.invalidate(revisionProvider);
    ref.invalidate(journeyProvider);
  }

  Future<void> update(UserProfile profile) async {
    state = profile;
    await _save();
    invalidateAllData();
  }

  Future<void> completeOnboarding({
    required String name,
    required ExamMode examMode,
    required DateTime examTargetDate,
    DateTime? preparationStartDate,
    required double dailyGoalHours,
    String? optionalSubject,
    String? dailyExerciseType,
  }) async {
    state = UserProfile(
      name: name,
      examMode: examMode,
      examTargetDate: examTargetDate,
      preparationStartDate: preparationStartDate,
      dailyGoalHours: dailyGoalHours,
      optionalSubject: optionalSubject,
      onboardingComplete: true,
      dailyExerciseType: dailyExerciseType,
    );
    await _save();
    invalidateAllData();
  }
}
