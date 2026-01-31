import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/study_session.dart';
import '../models/subject.dart';
import '../data/database_helper.dart';

enum TimerState { idle, running, paused }
enum TimerMode { stopwatch, pomodoro }

class TimerProvider extends ChangeNotifier {
  TimerState _state = TimerState.idle;
  TimerMode _mode = TimerMode.stopwatch;
  Subject? _selectedSubject;
  int _elapsedSeconds = 0;
  int _pomodoroMinutes = 25;
  Timer? _timer;
  DateTime? _sessionStart;

  TimerState get state => _state;
  TimerMode get mode => _mode;
  Subject? get selectedSubject => _selectedSubject;
  int get elapsedSeconds => _elapsedSeconds;
  int get pomodoroMinutes => _pomodoroMinutes;
  bool get isRunning => _state == TimerState.running;
  bool get isPaused => _state == TimerState.paused;
  bool get isIdle => _state == TimerState.idle;

  int get remainingSeconds {
    if (_mode == TimerMode.pomodoro) {
      return (_pomodoroMinutes * 60) - _elapsedSeconds;
    }
    return _elapsedSeconds;
  }

  double get progress {
    if (_mode == TimerMode.pomodoro) {
      return _elapsedSeconds / (_pomodoroMinutes * 60);
    }
    // Stopwatch: full circle every hour
    return (_elapsedSeconds % 3600) / 3600;
  }

  String get formattedTime {
    final seconds = _mode == TimerMode.pomodoro ? remainingSeconds : _elapsedSeconds;
    final h = seconds ~/ 3600;
    final m = (seconds.abs() % 3600) ~/ 60;
    final s = seconds.abs() % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get formattedElapsed {
    final h = _elapsedSeconds ~/ 3600;
    final m = (_elapsedSeconds % 3600) ~/ 60;
    if (h > 0) return '${h}시간 ${m}분';
    return '${m}분';
  }

  void selectSubject(Subject subject) {
    _selectedSubject = subject;
    notifyListeners();
  }

  void setMode(TimerMode mode) {
    if (_state != TimerState.idle) return;
    _mode = mode;
    notifyListeners();
  }

  void setPomodoroMinutes(int minutes) {
    if (_state != TimerState.idle) return;
    _pomodoroMinutes = minutes;
    notifyListeners();
  }

  void start() {
    if (_selectedSubject == null) return;
    _state = TimerState.running;
    _sessionStart ??= DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _elapsedSeconds++;
      if (_mode == TimerMode.pomodoro && remainingSeconds <= 0) {
        _finishSession();
        return;
      }
      notifyListeners();
    });
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _timer = null;
    _state = TimerState.paused;
    notifyListeners();
  }

  void resume() {
    start();
  }

  Future<StudySession?> stop() async {
    return await _finishSession();
  }

  Future<StudySession?> _finishSession() async {
    _timer?.cancel();
    _timer = null;

    StudySession? session;
    if (_sessionStart != null && _elapsedSeconds > 0 && _selectedSubject != null) {
      session = StudySession(
        id: const Uuid().v4(),
        subjectId: _selectedSubject!.id,
        startTime: _sessionStart!,
        endTime: DateTime.now(),
        durationSeconds: _elapsedSeconds,
      );
      await DatabaseHelper.instance.insertSession(session);
    }

    _state = TimerState.idle;
    _elapsedSeconds = 0;
    _sessionStart = null;
    notifyListeners();
    return session;
  }

  void reset() {
    _timer?.cancel();
    _timer = null;
    _state = TimerState.idle;
    _elapsedSeconds = 0;
    _sessionStart = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
