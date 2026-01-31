import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class Subject {
  final String id;
  final String name;
  final String emoji;
  final int colorIndex;

  const Subject({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorIndex,
  });

  Color get color => AppColors.subjectColors[colorIndex % AppColors.subjectColors.length];

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'colorIndex': colorIndex,
      };

  factory Subject.fromMap(Map<String, dynamic> map) => Subject(
        id: map['id'] as String,
        name: map['name'] as String,
        emoji: map['emoji'] as String,
        colorIndex: map['colorIndex'] as int,
      );

  static const List<Subject> defaults = [
    Subject(id: 'korean', name: '국어', emoji: '📖', colorIndex: 0),
    Subject(id: 'math', name: '수학', emoji: '📐', colorIndex: 1),
    Subject(id: 'english', name: '영어', emoji: '🔤', colorIndex: 2),
    Subject(id: 'science', name: '과학', emoji: '🔬', colorIndex: 3),
    Subject(id: 'social', name: '사회', emoji: '🌏', colorIndex: 4),
    Subject(id: 'history', name: '한국사', emoji: '📜', colorIndex: 5),
    Subject(id: 'etc', name: '기타', emoji: '📝', colorIndex: 6),
  ];
}
