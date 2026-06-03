enum ExamMode { upsc, jpsc, both }

class UserProfile {
  final String name;
  final ExamMode examMode;
  final DateTime? examTargetDate;
  final DateTime? preparationStartDate;
  final double dailyGoalHours;
  final String? optionalSubject;
  final bool onboardingComplete;
  final String? dailyExerciseType; // e.g. 'Running', 'Yoga', 'Exercise', or null if they don't want it

  UserProfile({
    required this.name,
    required this.examMode,
    this.examTargetDate,
    this.preparationStartDate,
    this.dailyGoalHours = 8.0,
    this.optionalSubject,
    this.onboardingComplete = false,
    this.dailyExerciseType,
  });

  int get daysToExam {
    if (examTargetDate == null) return 0;
    return examTargetDate!.difference(DateTime.now()).inDays;
  }

  UserProfile copyWith({
    String? name,
    ExamMode? examMode,
    DateTime? examTargetDate,
    DateTime? preparationStartDate,
    double? dailyGoalHours,
    String? optionalSubject,
    bool? onboardingComplete,
    String? dailyExerciseType,
  }) {
    return UserProfile(
      name: name ?? this.name,
      examMode: examMode ?? this.examMode,
      examTargetDate: examTargetDate ?? this.examTargetDate,
      preparationStartDate: preparationStartDate ?? this.preparationStartDate,
      dailyGoalHours: dailyGoalHours ?? this.dailyGoalHours,
      optionalSubject: optionalSubject ?? this.optionalSubject,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      dailyExerciseType: dailyExerciseType ?? this.dailyExerciseType,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'examMode': examMode.index,
        'examTargetDate': examTargetDate?.toIso8601String(),
        'preparationStartDate': preparationStartDate?.toIso8601String(),
        'dailyGoalHours': dailyGoalHours,
        'optionalSubject': optionalSubject,
        'onboardingComplete': onboardingComplete,
        'dailyExerciseType': dailyExerciseType,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] ?? '',
        examMode: ExamMode.values[json['examMode'] ?? 0],
        examTargetDate: json['examTargetDate'] != null
            ? DateTime.parse(json['examTargetDate'])
            : null,
        preparationStartDate: json['preparationStartDate'] != null
            ? DateTime.parse(json['preparationStartDate'])
            : null,
        dailyGoalHours: (json['dailyGoalHours'] as num?)?.toDouble() ?? 8.0,
        optionalSubject: json['optionalSubject'],
        onboardingComplete: json['onboardingComplete'] ?? false,
        dailyExerciseType: json['dailyExerciseType'],
      );

  factory UserProfile.defaultProfile() => UserProfile(
        name: 'Aspirant',
        examMode: ExamMode.upsc,
        dailyGoalHours: 8.0,
        onboardingComplete: false,
        dailyExerciseType: null,
      );
}
