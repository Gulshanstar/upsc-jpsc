import '../models/study_session.dart';
import '../models/revision_item.dart';
import '../models/journal_entry.dart';

List<StudySession> buildMockSessions() {
  final now = DateTime.now();
  return [
    StudySession(
      id: 's1', date: now, subjectId: 'gs1_indian_heritage',
      subjectName: 'Indian Heritage & Culture', sectionId: 'upsc_gs1',
      sectionName: 'GS-1', durationMinutes: 120, examType: 'upsc',
      topicsCovered: ['Indus Valley Civilisation', 'Vedic Age & Literature'],
      startTime: const TimeOfDay(hour: 9, minute: 0),
    ),
    StudySession(
      id: 's2', date: now, subjectId: 'gs2_polity',
      subjectName: 'Indian Constitution & Polity', sectionId: 'upsc_gs2',
      sectionName: 'GS-2', durationMinutes: 90, examType: 'upsc',
      topicsCovered: ['Fundamental Rights (Art. 12–35)'],
      startTime: const TimeOfDay(hour: 14, minute: 0),
    ),
    StudySession(
      id: 's3', date: now.subtract(const Duration(days: 1)),
      subjectId: 'gs3_economy', subjectName: 'Indian Economy',
      sectionId: 'upsc_gs3', sectionName: 'GS-3', durationMinutes: 180,
      examType: 'upsc',
      topicsCovered: ['GDP, GNP, NNP — Concepts', 'Fiscal Policy'],
      startTime: const TimeOfDay(hour: 8, minute: 30),
    ),
    StudySession(
      id: 's4', date: now.subtract(const Duration(days: 2)),
      subjectId: 'gs1_geography', subjectName: 'Physical & Human Geography',
      sectionId: 'upsc_gs1', sectionName: 'GS-1', durationMinutes: 150,
      examType: 'upsc',
      topicsCovered: ['Plate Tectonics', 'Earthquakes & Volcanism'],
      startTime: const TimeOfDay(hour: 10, minute: 0),
    ),
    StudySession(
      id: 's5', date: now.subtract(const Duration(days: 3)),
      subjectId: 'gs4_ethics', subjectName: 'Ethics, Integrity & Aptitude',
      sectionId: 'upsc_gs4', sectionName: 'GS-4', durationMinutes: 60,
      examType: 'upsc',
      topicsCovered: ['Virtue Ethics (Aristotle)', 'Utilitarian Ethics'],
      startTime: const TimeOfDay(hour: 18, minute: 0),
    ),
    StudySession(
      id: 's6', date: now.subtract(const Duration(days: 4)),
      subjectId: 'jpsc_jh_history', subjectName: 'History of Jharkhand',
      sectionId: 'jpsc_prelim2', sectionName: 'Pre GS-II', durationMinutes: 120,
      examType: 'jpsc',
      topicsCovered: ['Birsa Munda Movement', 'Santhal Hul 1855'],
      startTime: const TimeOfDay(hour: 9, minute: 30),
    ),
    StudySession(
      id: 's7', date: now.subtract(const Duration(days: 5)),
      subjectId: 'gs1_modern_history', subjectName: 'Modern Indian History',
      sectionId: 'upsc_gs1', sectionName: 'GS-1', durationMinutes: 200,
      examType: 'upsc',
      topicsCovered: ['Non-Cooperation Movement', 'Civil Disobedience'],
      startTime: const TimeOfDay(hour: 7, minute: 0),
    ),
    StudySession(
      id: 's8', date: now.subtract(const Duration(days: 7)),
      subjectId: 'gs3_environment', subjectName: 'Environment & Ecology',
      sectionId: 'upsc_gs3', sectionName: 'GS-3', durationMinutes: 90,
      examType: 'upsc',
      topicsCovered: ['Biodiversity Conservation', 'International Conventions'],
      startTime: const TimeOfDay(hour: 15, minute: 0),
    ),
    StudySession(
      id: 's9', date: now.subtract(const Duration(days: 8)),
      subjectId: 'gs2_international', subjectName: 'International Relations',
      sectionId: 'upsc_gs2', sectionName: 'GS-2', durationMinutes: 120,
      examType: 'upsc',
      topicsCovered: ['India-China Relations', 'BRICS & SCO'],
      startTime: const TimeOfDay(hour: 11, minute: 0),
    ),
    StudySession(
      id: 's10', date: now.subtract(const Duration(days: 10)),
      subjectId: 'gs3_science', subjectName: 'Science & Technology',
      sectionId: 'upsc_gs3', sectionName: 'GS-3', durationMinutes: 90,
      examType: 'upsc',
      topicsCovered: ['Space Technology — ISRO', 'Nuclear Energy'],
      startTime: const TimeOfDay(hour: 20, minute: 0),
    ),
  ];
}

List<RevisionItem> buildMockRevisions() {
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

List<JournalEntry> buildMockJournalEntries() {
  final now = DateTime.now();
  return List.generate(60, (i) {
    final date = now.subtract(Duration(days: i));
    final didStudy = i != 6 && i != 13 && i != 20 && i != 27 && i != 34;
    return JournalEntry(
      id: 'j$i',
      date: DateTime(date.year, date.month, date.day),
      didStudy: didStudy,
      hoursStudied: didStudy ? (4 + (i % 5)).toDouble() : 0,
      topicsCount: didStudy ? (2 + (i % 4)) : 0,
      mood: didStudy ? (3 + (i % 3)) : 2,
      note: didStudy
          ? 'Studied well today. Covered important topics.'
          : null,
      missedReason: !didStudy
          ? ['Personal work', 'Not feeling well', 'Family event', 'Burnout'][i % 4]
          : null,
    );
  });
}
