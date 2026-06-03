enum TopicStatus { notStarted, inProgress, completed, needsRevision }

enum ExamType { upsc, jpsc, both }

class Topic {
  final String id;
  final String title;
  final String subjectId;
  final String sectionId;
  final String examType; // 'upsc', 'jpsc'
  TopicStatus status;
  String? notes;
  DateTime? lastStudied;
  DateTime? nextRevisionDate;
  int revisionCount;
  double? confidenceLevel; // 0.0 - 1.0
  double progressPercent; // 0.0 - 1.0 (e.g. 0.30 for 30%)

  Topic({
    required this.id,
    required this.title,
    required this.subjectId,
    required this.sectionId,
    required this.examType,
    this.status = TopicStatus.notStarted,
    this.notes,
    this.lastStudied,
    this.nextRevisionDate,
    this.revisionCount = 0,
    this.confidenceLevel,
    this.progressPercent = 0.0,
  });

  Topic copyWith({
    TopicStatus? status,
    String? notes,
    DateTime? lastStudied,
    DateTime? nextRevisionDate,
    int? revisionCount,
    double? confidenceLevel,
    double? progressPercent,
  }) {
    return Topic(
      id: id,
      title: title,
      subjectId: subjectId,
      sectionId: sectionId,
      examType: examType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      lastStudied: lastStudied ?? this.lastStudied,
      nextRevisionDate: nextRevisionDate ?? this.nextRevisionDate,
      revisionCount: revisionCount ?? this.revisionCount,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subjectId': subjectId,
        'sectionId': sectionId,
        'examType': examType,
        'status': status.index,
        'notes': notes,
        'lastStudied': lastStudied?.toIso8601String(),
        'nextRevisionDate': nextRevisionDate?.toIso8601String(),
        'revisionCount': revisionCount,
        'confidenceLevel': confidenceLevel,
        'progressPercent': progressPercent,
      };

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json['id'],
        title: json['title'],
        subjectId: json['subjectId'],
        sectionId: json['sectionId'],
        examType: json['examType'],
        status: TopicStatus.values[json['status'] ?? 0],
        notes: json['notes'],
        lastStudied: json['lastStudied'] != null
            ? DateTime.parse(json['lastStudied'])
            : null,
        nextRevisionDate: json['nextRevisionDate'] != null
            ? DateTime.parse(json['nextRevisionDate'])
            : null,
        revisionCount: json['revisionCount'] ?? 0,
        confidenceLevel: json['confidenceLevel'],
        progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
      );
}

class Subject {
  final String id;
  final String title;
  final String sectionId;
  final String examType;
  final String emoji;
  final List<Topic> topics;

  Subject({
    required this.id,
    required this.title,
    required this.sectionId,
    required this.examType,
    required this.emoji,
    required this.topics,
  });

  double get completionPercent {
    if (topics.isEmpty) return 0;
    final sum = topics.fold<double>(0.0, (s, t) {
      if (t.status == TopicStatus.completed) return s + 1.0;
      return s + t.progressPercent;
    });
    return sum / topics.length;
  }

  int get completedCount =>
      topics.where((t) => t.status == TopicStatus.completed).length;
  int get inProgressCount =>
      topics.where((t) => t.status == TopicStatus.inProgress).length;
  int get needsRevisionCount =>
      topics.where((t) => t.status == TopicStatus.needsRevision).length;
  int get notStartedCount =>
      topics.where((t) => t.status == TopicStatus.notStarted).length;
}

class Section {
  final String id;
  final String title;
  final String examType;
  final String shortName;
  final List<Subject> subjects;

  Section({
    required this.id,
    required this.title,
    required this.examType,
    required this.shortName,
    required this.subjects,
  });

  List<Topic> get allTopics =>
      subjects.expand((s) => s.topics).toList();

  double get completionPercent {
    final all = allTopics;
    if (all.isEmpty) return 0;
    final sum = all.fold<double>(0.0, (s, t) {
      if (t.status == TopicStatus.completed) return s + 1.0;
      return s + t.progressPercent;
    });
    return sum / all.length;
  }
}
