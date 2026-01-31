class StudySession {
  final String id;
  final String subjectId;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;

  const StudySession({
    required this.id,
    required this.subjectId,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
  });

  double get durationHours => durationSeconds / 3600.0;
  int get durationMinutes => durationSeconds ~/ 60;

  String get formattedDuration {
    final h = durationSeconds ~/ 3600;
    final m = (durationSeconds % 3600) ~/ 60;
    final s = durationSeconds % 60;
    if (h > 0) return '${h}시간 ${m}분';
    if (m > 0) return '${m}분 ${s}초';
    return '${s}초';
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'subjectId': subjectId,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
        'durationSeconds': durationSeconds,
      };

  factory StudySession.fromMap(Map<String, dynamic> map) => StudySession(
        id: map['id'] as String,
        subjectId: map['subjectId'] as String,
        startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime'] as int),
        endTime: DateTime.fromMillisecondsSinceEpoch(map['endTime'] as int),
        durationSeconds: map['durationSeconds'] as int,
      );
}
