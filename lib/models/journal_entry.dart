class JournalEntry {
  final String id;
  final DateTime date;
  final String? note;
  final bool didStudy;
  final String? missedReason;
  final double hoursStudied;
  final int topicsCount;
  final int mood; // 1-5
  final bool? didExercise; // Track if they completed exercise
  final String? exerciseNote; // Track exercise duration/notes
  final String? missedExerciseReason; // Track reason for skipping exercise
  final String? goal; // Track daily goal or thought

  JournalEntry({
    required this.id,
    required this.date,
    this.note,
    required this.didStudy,
    this.missedReason,
    this.hoursStudied = 0,
    this.topicsCount = 0,
    this.mood = 3,
    this.didExercise,
    this.exerciseNote,
    this.missedExerciseReason,
    this.goal,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'note': note,
        'didStudy': didStudy,
        'missedReason': missedReason,
        'hoursStudied': hoursStudied,
        'topicsCount': topicsCount,
        'mood': mood,
        'didExercise': didExercise,
        'exerciseNote': exerciseNote,
        'missedExerciseReason': missedExerciseReason,
        'goal': goal,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'],
        date: DateTime.parse(json['date']),
        note: json['note'],
        didStudy: json['didStudy'] ?? false,
        missedReason: json['missedReason'],
        hoursStudied: (json['hoursStudied'] as num?)?.toDouble() ?? 0,
        topicsCount: json['topicsCount'] ?? 0,
        mood: json['mood'] ?? 3,
        didExercise: json['didExercise'],
        exerciseNote: json['exerciseNote'],
        missedExerciseReason: json['missedExerciseReason'],
        goal: json['goal'],
      );
}
