class StudySession {
  final String id;
  final DateTime date;
  final String subjectId;
  final String subjectName;
  final String sectionId;
  final String sectionName;
  final double durationMinutes;
  final List<String> topicsCovered;
  final String? notes;
  final String examType; // 'upsc', 'jpsc'
  final TimeOfDay startTime;
  final String? shift; // 'morning', 'afternoon', 'evening', 'night'

  StudySession({
    required this.id,
    required this.date,
    required this.subjectId,
    required this.subjectName,
    required this.sectionId,
    required this.sectionName,
    required this.durationMinutes,
    required this.topicsCovered,
    required this.examType,
    required this.startTime,
    this.notes,
    this.shift,
  });

  double get durationHours => durationMinutes / 60;

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'subjectId': subjectId,
        'subjectName': subjectName,
        'sectionId': sectionId,
        'sectionName': sectionName,
        'durationMinutes': durationMinutes,
        'topicsCovered': topicsCovered,
        'notes': notes,
        'examType': examType,
        'startHour': startTime.hour,
        'startMinute': startTime.minute,
        'shift': shift,
      };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'],
        date: DateTime.parse(json['date']),
        subjectId: json['subjectId'],
        subjectName: json['subjectName'],
        sectionId: json['sectionId'],
        sectionName: json['sectionName'],
        durationMinutes: (json['durationMinutes'] as num).toDouble(),
        topicsCovered: List<String>.from(json['topicsCovered'] ?? []),
        notes: json['notes'],
        examType: json['examType'],
        startTime: TimeOfDay(
          hour: json['startHour'] ?? 9,
          minute: json['startMinute'] ?? 0,
        ),
        shift: json['shift'],
      );
}

class TimeOfDay {
  final int hour;
  final int minute;
  const TimeOfDay({required this.hour, required this.minute});

  String format() {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}
