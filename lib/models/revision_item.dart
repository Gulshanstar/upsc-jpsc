class RevisionItem {
  final String id;
  final String topicId;
  final String topicTitle;
  final String subjectName;
  final String sectionName;
  final String subjectId;
  final String examType;
  DateTime nextDueDate;
  DateTime? lastReviewedDate;
  int revisionCount;
  double easeFactor; // SM-2 ease factor, default 2.5
  int intervalDays; // current interval in days
  bool lockedForEver; // locked indefinitely
  List<bool> reviewHistory; // true = remembered, false = forgot

  RevisionItem({
    required this.id,
    required this.topicId,
    required this.topicTitle,
    required this.subjectName,
    required this.sectionName,
    required this.subjectId,
    required this.examType,
    required this.nextDueDate,
    this.lastReviewedDate,
    this.revisionCount = 0,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.lockedForEver = false,
    List<bool>? reviewHistory,
  }) : reviewHistory = reviewHistory ?? [];

  bool get isDueToday {
    if (lockedForEver) return false;
    final now = DateTime.now();
    return nextDueDate.isBefore(DateTime(now.year, now.month, now.day + 1));
  }

  bool get isOverdue {
    if (lockedForEver) return false;
    final now = DateTime.now();
    return nextDueDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  int get daysSinceLastReview {
    if (lastReviewedDate == null) return 0;
    return DateTime.now().difference(lastReviewedDate!).inDays;
  }

  double get recallRate {
    if (reviewHistory.isEmpty) return 0;
    return reviewHistory.where((r) => r).length / reviewHistory.length;
  }

  /// SM-2 algorithm — update after review
  void updateAfterReview(bool remembered) {
    lastReviewedDate = DateTime.now();
    revisionCount++;
    reviewHistory.add(remembered);

    if (remembered) {
      if (revisionCount == 1) {
        intervalDays = 1;
      } else if (revisionCount == 2) {
        intervalDays = 3;
      } else {
        intervalDays = (intervalDays * easeFactor).round();
      }
      easeFactor = easeFactor + 0.1;
      if (easeFactor > 2.5) easeFactor = 2.5;
    } else {
      intervalDays = 1;
      easeFactor = easeFactor - 0.2;
      if (easeFactor < 1.3) easeFactor = 1.3;
    }

    nextDueDate = DateTime.now().add(Duration(days: intervalDays));
  }

  /// Undo the last review, reverting revisionCount, easeFactor, intervalDays, nextDueDate, and reviewHistory.
  void revertLastReview(DateTime? prevLastReviewedDate, int prevIntervalDays, double prevEaseFactor) {
    if (reviewHistory.isEmpty) return;
    reviewHistory.removeLast();
    revisionCount--;
    lastReviewedDate = prevLastReviewedDate;
    intervalDays = prevIntervalDays;
    easeFactor = prevEaseFactor;
    nextDueDate = DateTime.now(); // Put it back to be due immediately (today)
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'topicId': topicId,
        'topicTitle': topicTitle,
        'subjectName': subjectName,
        'sectionName': sectionName,
        'subjectId': subjectId,
        'examType': examType,
        'nextDueDate': nextDueDate.toIso8601String(),
        'lastReviewedDate': lastReviewedDate?.toIso8601String(),
        'revisionCount': revisionCount,
        'easeFactor': easeFactor,
        'intervalDays': intervalDays,
        'lockedForEver': lockedForEver,
        'reviewHistory': reviewHistory,
      };

  factory RevisionItem.fromJson(Map<String, dynamic> json) => RevisionItem(
        id: json['id'],
        topicId: json['topicId'],
        topicTitle: json['topicTitle'],
        subjectName: json['subjectName'],
        sectionName: json['sectionName'],
        subjectId: json['subjectId'],
        examType: json['examType'],
        nextDueDate: DateTime.parse(json['nextDueDate']),
        lastReviewedDate: json['lastReviewedDate'] != null
            ? DateTime.parse(json['lastReviewedDate'])
            : null,
        revisionCount: json['revisionCount'] ?? 0,
        easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
        intervalDays: json['intervalDays'] ?? 1,
        lockedForEver: json['lockedForEver'] ?? false,
        reviewHistory:
            List<bool>.from(json['reviewHistory'] ?? []),
      );
}
