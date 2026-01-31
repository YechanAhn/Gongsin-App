import 'package:flutter/material.dart';
import '../data/database_helper.dart';
import '../models/study_session.dart';
import '../models/subject.dart';

class StudyProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Subject> _subjects = [];
  Map<DateTime, double> _monthlyHours = {};
  List<StudySession> _todaySessions = [];
  double _todayTotalHours = 0;
  int _currentYear = DateTime.now().year;
  int _currentMonth = DateTime.now().month;

  List<Subject> get subjects => _subjects;
  Map<DateTime, double> get monthlyHours => _monthlyHours;
  List<StudySession> get todaySessions => _todaySessions;
  double get todayTotalHours => _todayTotalHours;
  int get currentYear => _currentYear;
  int get currentMonth => _currentMonth;

  String get todayFormatted {
    final h = _todayTotalHours.floor();
    final m = ((_todayTotalHours - h) * 60).round();
    if (h > 0) return '${h}시간 ${m}분';
    return '${m}분';
  }

  StudyProvider() {
    loadData();
  }

  Future<void> loadData() async {
    await Future.wait([
      loadSubjects(),
      loadTodaySessions(),
      loadMonthlyHours(_currentYear, _currentMonth),
    ]);
  }

  Future<void> loadSubjects() async {
    _subjects = await _db.getSubjects();
    notifyListeners();
  }

  Future<void> loadTodaySessions() async {
    final today = DateTime.now();
    _todaySessions = await _db.getSessionsForDate(today);
    _todayTotalHours = await _db.getTotalHoursForDate(today);
    notifyListeners();
  }

  Future<void> loadMonthlyHours(int year, int month) async {
    _currentYear = year;
    _currentMonth = month;
    _monthlyHours = await _db.getDailyHoursForMonth(year, month);
    notifyListeners();
  }

  Future<void> navigateMonth(int delta) async {
    var newMonth = _currentMonth + delta;
    var newYear = _currentYear;
    if (newMonth > 12) {
      newMonth = 1;
      newYear++;
    } else if (newMonth < 1) {
      newMonth = 12;
      newYear--;
    }
    await loadMonthlyHours(newYear, newMonth);
  }

  Future<void> addSubject(Subject subject) async {
    await _db.insertSubject(subject);
    await loadSubjects();
  }

  Future<void> removeSubject(String id) async {
    await _db.deleteSubject(id);
    await loadSubjects();
  }

  Future<void> onSessionCompleted() async {
    await loadTodaySessions();
    await loadMonthlyHours(_currentYear, _currentMonth);
  }

  Future<List<StudySession>> getSessionsForDate(DateTime date) async {
    return await _db.getSessionsForDate(date);
  }

  Map<String, double> getSubjectBreakdown(List<StudySession> sessions) {
    final Map<String, double> breakdown = {};
    for (final session in sessions) {
      final subject = _subjects.firstWhere(
        (s) => s.id == session.subjectId,
        orElse: () => Subject.defaults.last,
      );
      breakdown[subject.name] = (breakdown[subject.name] ?? 0) + session.durationHours;
    }
    return breakdown;
  }
}
