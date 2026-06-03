import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../models/study_session.dart';
import '../models/revision_item.dart';
import '../models/journal_entry.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  SupabaseClient get client => Supabase.instance.client;

  /// Gracefully initialize Supabase. If URL/Key are empty or invalid,
  /// the app remains fully functional in local-only offline mode.
  Future<void> initialize() async {
    try {
      // NOTE: Replace these placeholders with your actual Supabase credentials for production
      const String supabaseUrl = 'https://tgvmlkkgcqovqmfkysik.supabase.co';
      const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRndm1sa2tnY3FvdnFtZmt5c2lrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAwMjM2NDgsImV4cCI6MjA5NTU5OTY0OH0.Ym6XqKt7k7_RfTalTv9TKMxCjLHkHSR-hxW-DVU-SUc';

      if (supabaseUrl == 'https://your-supabase-project.supabase.co' ||
          supabaseAnonKey == 'your-anon-key' ||
          supabaseUrl.isEmpty ||
          supabaseAnonKey.isEmpty) {
        debugPrint('Supabase: Using local offline-only mode. Please set credentials in supabase_service.dart for cloud sync.');
        _isInitialized = false;
        return;
      }

      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _isInitialized = true;
      debugPrint('Supabase successfully initialized.');
    } catch (e) {
      debugPrint('Supabase initialization failed: $e. Falling back to offline-only mode.');
      _isInitialized = false;
    }
  }

  /// Sign In with Google and link with Supabase Authentication.
  /// Handles iOS and Android native flows.
  Future<User?> signInWithGoogle() async {
    if (!_isInitialized) {
      debugPrint('Supabase not initialized. Cannot sign in.');
      return null;
    }

    try {
      // For Android, ensure you configure the webClientID in GoogleSignIn.
      // webClientId is the Client ID for the Web Application in Google Cloud Console.
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: '940843365796-smr008egj8kekvt6olrflkbh23b0h3fm.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('Google Sign-In canceled by user.');
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw 'No ID Token found.';
      }

      final AuthResponse response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      debugPrint('Supabase Google Auth Successful: ${response.user?.email}');
      return response.user;
    } catch (e) {
      debugPrint('Google Sign-In / Supabase Auth Error: $e');
      rethrow;
    }
  }

  /// Sign out from Supabase and Google.
  Future<void> signOut() async {
    if (!_isInitialized) return;
    try {
      await client.auth.signOut();
      await GoogleSignIn().signOut();
      debugPrint('Logged out successfully.');
    } catch (e) {
      debugPrint('Logout error: $e');
    }
  }

  /// Check if user is currently authenticated
  bool get isAuthenticated => _isInitialized && client.auth.currentSession != null;

  /// Current user ID
  String? get currentUserId => _isInitialized ? client.auth.currentUser?.id : null;

  // ==========================================
  // SYNC OPERATIONS (OFFLINE-SAFE CRUD)
  // ==========================================

  /// Save or update user profile to Supabase
  Future<void> syncProfile(UserProfile profile) async {
    if (!isAuthenticated) return;
    try {
      final userId = currentUserId!;
      await client.from('profiles').upsert({
        'id': userId,
        'name': profile.name,
        'exam_mode': profile.examMode.name,
        'exam_target_date': profile.examTargetDate?.toIso8601String(),
        'preparation_start_date': profile.preparationStartDate?.toIso8601String(),
        'daily_goal_hours': profile.dailyGoalHours,
        'optional_subject': profile.optionalSubject,
        'onboarding_complete': profile.onboardingComplete,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('Profile synced to Supabase.');
    } catch (e) {
      debugPrint('Error syncing profile: $e');
    }
  }

  /// Sync study sessions
  Future<void> syncStudySessions(List<StudySession> sessions) async {
    if (!isAuthenticated) return;
    try {
      final userId = currentUserId!;
      final list = sessions.map((s) => {
        'id': s.id,
        'user_id': userId,
        'subject_name': s.subjectName,
        'section_name': s.sectionName,
        'duration_hours': s.durationHours,
        'date': s.date.toIso8601String(),
        'topics_covered': s.topicsCovered,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).toList();

      if (list.isNotEmpty) {
        await client.from('study_sessions').upsert(list);
        debugPrint('Study sessions synced to Supabase.');
      }
    } catch (e) {
      debugPrint('Error syncing study sessions: $e');
    }
  }

  /// Sync single study session (incremental)
  Future<void> saveStudySession(StudySession session) async {
    if (!isAuthenticated) return;
    try {
      final userId = currentUserId!;
      await client.from('study_sessions').upsert({
        'id': session.id,
        'user_id': userId,
        'subject_name': session.subjectName,
        'section_name': session.sectionName,
        'duration_hours': session.durationHours,
        'date': session.date.toIso8601String(),
        'topics_covered': session.topicsCovered,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('Single session synced.');
    } catch (e) {
      debugPrint('Error syncing single session: $e');
    }
  }

  /// Sync revision items
  Future<void> syncRevisionItems(List<RevisionItem> items) async {
    if (!isAuthenticated) return;
    try {
      final userId = currentUserId!;
      final list = items.map((i) => {
        'id': i.id,
        'user_id': userId,
        'topic_id': i.topicId,
        'subject_name': i.subjectName,
        'topic_title': i.topicTitle,
        'section_name': i.sectionName,
        'subject_id': i.subjectId,
        'exam_type': i.examType,
        'next_due_date': i.nextDueDate.toIso8601String(),
        'last_reviewed_date': i.lastReviewedDate?.toIso8601String(),
        'revision_count': i.revisionCount,
        'ease_factor': i.easeFactor,
        'interval_days': i.intervalDays,
        'review_history': i.reviewHistory,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).toList();

      if (list.isNotEmpty) {
        await client.from('revision_items').upsert(list);
        debugPrint('Revision items synced.');
      }
    } catch (e) {
      debugPrint('Error syncing revision items: $e');
    }
  }

  /// Sync single revision item
  Future<void> saveRevisionItem(RevisionItem item) async {
    if (!isAuthenticated) return;
    try {
      final userId = currentUserId!;
      await client.from('revision_items').upsert({
        'id': item.id,
        'user_id': userId,
        'topic_id': item.topicId,
        'subject_name': item.subjectName,
        'topic_title': item.topicTitle,
        'section_name': item.sectionName,
        'subject_id': item.subjectId,
        'exam_type': item.examType,
        'next_due_date': item.nextDueDate.toIso8601String(),
        'last_reviewed_date': item.lastReviewedDate?.toIso8601String(),
        'revision_count': item.revisionCount,
        'ease_factor': item.easeFactor,
        'interval_days': item.intervalDays,
        'review_history': item.reviewHistory,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving revision item: $e');
    }
  }

  /// Sync journal entries
  Future<void> syncJournalEntries(List<JournalEntry> entries) async {
    if (!isAuthenticated) return;
    try {
      final userId = currentUserId!;
      final list = entries.map((e) => {
        'id': e.id,
        'user_id': userId,
        'date': e.date.toIso8601String(),
        'did_study': e.didStudy,
        'note': e.note,
        'hours_studied': e.hoursStudied,
        'topics_count': e.topicsCount,
        'mood': e.mood,
        'missed_reason': e.missedReason,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).toList();

      if (list.isNotEmpty) {
        await client.from('journal_entries').upsert(list);
        debugPrint('Journal entries synced.');
      }
    } catch (e) {
      debugPrint('Error syncing journal entries: $e');
    }
  }

  /// Sync single journal entry
  Future<void> saveJournalEntry(JournalEntry entry) async {
    if (!isAuthenticated) return;
    try {
      final userId = currentUserId!;
      await client.from('journal_entries').upsert({
        'id': entry.id,
        'user_id': userId,
        'date': entry.date.toIso8601String(),
        'did_study': entry.didStudy,
        'note': entry.note,
        'hours_studied': entry.hoursStudied,
        'topics_count': entry.topicsCount,
        'mood': entry.mood,
        'missed_reason': entry.missedReason,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error saving journal entry: $e');
    }
  }

  /// Fetch user profile from Supabase
  Future<UserProfile?> fetchProfile() async {
    if (!isAuthenticated) return null;
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', currentUserId!)
          .maybeSingle();
      if (response != null) {
        final examModeStr = response['exam_mode'] ?? 'upsc';
        ExamMode examMode = ExamMode.upsc;
        if (examModeStr == 'jpsc') examMode = ExamMode.jpsc;
        if (examModeStr == 'both') examMode = ExamMode.both;

        return UserProfile(
          name: response['name'] ?? '',
          examMode: examMode,
          examTargetDate: response['exam_target_date'] != null
              ? DateTime.parse(response['exam_target_date'])
              : null,
          preparationStartDate: response['preparation_start_date'] != null
              ? DateTime.parse(response['preparation_start_date'])
              : null,
          dailyGoalHours: (response['daily_goal_hours'] as num?)?.toDouble() ?? 8.0,
          optionalSubject: response['optional_subject'],
          onboardingComplete: response['onboarding_complete'] ?? false,
        );
      }
    } catch (e) {
      debugPrint('Error fetching profile from Supabase: $e');
    }
    return null;
  }

  /// Fetch study sessions from Supabase
  Future<List<StudySession>> fetchStudySessions() async {
    if (!isAuthenticated) return [];
    try {
      final response = await client
          .from('study_sessions')
          .select()
          .eq('user_id', currentUserId!)
          .order('date', ascending: false);
      
      return (response as List).map((row) {
        final parsedDate = DateTime.parse(row['date']);
        final String sName = row['subject_name'] ?? 'Subject';
        final String secName = row['section_name'] ?? 'Section';
        return StudySession(
          id: row['id'],
          date: parsedDate,
          subjectId: sName.toLowerCase().replaceAll(' ', '_'),
          subjectName: sName,
          sectionId: secName.toLowerCase().replaceAll(' ', '_'),
          sectionName: secName,
          durationMinutes: ((row['duration_hours'] as num?)?.toDouble() ?? 0) * 60,
          topicsCovered: _parseTopics(row['topics_covered']),
          notes: row['notes'] ?? row['topics_covered']?.toString(),
          examType: secName.toLowerCase().contains('jpsc') ? 'jpsc' : 'upsc',
          startTime: TimeOfDay(
            hour: parsedDate.hour,
            minute: parsedDate.minute,
          ),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching study sessions from Supabase: $e');
      return [];
    }
  }

  /// Fetch revision items from Supabase
  Future<List<RevisionItem>> fetchRevisionItems() async {
    if (!isAuthenticated) return [];
    try {
      final response = await client
          .from('revision_items')
          .select()
          .eq('user_id', currentUserId!);
      
      return (response as List).map((row) {
        return RevisionItem(
          id: row['id'],
          topicId: row['topic_id'] ?? '',
          topicTitle: row['topic_title'] ?? '',
          subjectName: row['subject_name'] ?? '',
          sectionName: row['section_name'] ?? '',
          subjectId: row['subject_id'] ?? '',
          examType: row['exam_type'] ?? 'upsc',
          nextDueDate: DateTime.parse(row['next_due_date']),
          lastReviewedDate: row['last_reviewed_date'] != null
              ? DateTime.parse(row['last_reviewed_date'])
              : null,
          revisionCount: row['revision_count'] ?? 0,
          easeFactor: (row['ease_factor'] as num?)?.toDouble() ?? 2.5,
          intervalDays: row['interval_days'] ?? 1,
          reviewHistory: List<bool>.from(row['review_history'] ?? []),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching revision items from Supabase: $e');
      return [];
    }
  }

  /// Fetch journal entries from Supabase
  Future<List<JournalEntry>> fetchJournalEntries() async {
    if (!isAuthenticated) return [];
    try {
      final response = await client
          .from('journal_entries')
          .select()
          .eq('user_id', currentUserId!)
          .order('date', ascending: false);
      
      return (response as List).map((row) {
        return JournalEntry(
          id: row['id'],
          date: DateTime.parse(row['date']),
          note: row['note'],
          didStudy: row['did_study'] ?? false,
          missedReason: row['missed_reason'],
          hoursStudied: (row['hours_studied'] as num?)?.toDouble() ?? 0,
          topicsCount: row['topics_count'] ?? 0,
          mood: row['mood'] ?? 3,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching journal entries from Supabase: $e');
      return [];
    }
  }

  List<String> _parseTopics(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    if (value is String) {
      final str = value.trim();
      if (str.isEmpty) return [];
      if (str.startsWith('[') && str.endsWith(']')) {
        try {
          final decoded = jsonDecode(str);
          if (decoded is List) return List<String>.from(decoded);
        } catch (_) {}
      }
      if (str.startsWith('{') && str.endsWith('}')) {
        final content = str.substring(1, str.length - 1).trim();
        if (content.isEmpty) return [];
        return content.split(',').map((e) => e.trim().replaceAll('"', '')).toList();
      }
      return str.split(',').map((e) => e.trim()).toList();
    }
    return [value.toString()];
  }
}
