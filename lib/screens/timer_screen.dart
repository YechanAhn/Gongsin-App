import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/timer_provider.dart';
import '../providers/study_provider.dart';
import '../widgets/timer_display.dart';
import '../widgets/subject_chip.dart';

class TimerScreen extends StatelessWidget {
  const TimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      child: Consumer2<TimerProvider, StudyProvider>(
        builder: (context, timer, study, _) {
          return Column(
            children: [
              const SizedBox(height: 24),

              // Title
              Text(
                timer.isIdle ? '집중할 과목을 선택하세요' : '집중 중...',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),

              // Subject selector
              SubjectChipRow(
                subjects: study.subjects,
                selected: timer.selectedSubject,
                onSelected: (subject) {
                  if (timer.isIdle) timer.selectSubject(subject);
                },
              ),
              const SizedBox(height: 12),

              // Mode selector (only when idle)
              if (timer.isIdle)
                _ModeSelector(timer: timer, colorScheme: colorScheme),

              // Pomodoro time selector
              if (timer.isIdle && timer.mode == TimerMode.pomodoro)
                _PomodoroSelector(timer: timer, theme: theme),

              const Spacer(),

              // Timer display
              TimerDisplay(
                time: timer.formattedTime,
                progress: timer.progress,
                isRunning: timer.isRunning,
                progressColor: timer.selectedSubject?.color ?? colorScheme.primary,
              ),

              if (!timer.isIdle) ...[
                const SizedBox(height: 8),
                Text(
                  timer.formattedElapsed,
                  style: theme.textTheme.bodyMedium,
                ),
              ],

              const Spacer(),

              // Controls
              _TimerControls(timer: timer, study: study),

              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

class _ModeSelector extends StatelessWidget {
  final TimerProvider timer;
  final ColorScheme colorScheme;

  const _ModeSelector({required this.timer, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 60, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _ModeTab(
            label: '스톱워치',
            isSelected: timer.mode == TimerMode.stopwatch,
            onTap: () => timer.setMode(TimerMode.stopwatch),
            theme: theme,
            colorScheme: colorScheme,
          ),
          _ModeTab(
            label: '포모도로',
            isSelected: timer.mode == TimerMode.pomodoro,
            onTap: () => timer.setMode(TimerMode.pomodoro),
            theme: theme,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;
  final ColorScheme colorScheme;

  const _ModeTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withOpacity(0.4),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PomodoroSelector extends StatelessWidget {
  final TimerProvider timer;
  final ThemeData theme;

  const _PomodoroSelector({required this.timer, required this.theme});

  @override
  Widget build(BuildContext context) {
    final colorScheme = theme.colorScheme;
    const options = [15, 25, 30, 45, 60];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: options.map((min) {
          final isSelected = timer.pomodoroMinutes == min;
          return GestureDetector(
            onTap: () => timer.setPomodoroMinutes(min),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${min}분',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected ? colorScheme.primary : null,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _TimerControls extends StatelessWidget {
  final TimerProvider timer;
  final StudyProvider study;

  const _TimerControls({required this.timer, required this.study});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (timer.isIdle) {
      return SizedBox(
        width: 200,
        height: 56,
        child: ElevatedButton(
          onPressed: timer.selectedSubject != null ? timer.start : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: timer.selectedSubject?.color ?? colorScheme.primary,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow_rounded, size: 28),
              SizedBox(width: 6),
              Text('시작'),
            ],
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Stop button
        SizedBox(
          width: 64,
          height: 64,
          child: OutlinedButton(
            onPressed: () async {
              final session = await timer.stop();
              if (session != null) {
                await study.onSessionCompleted();
                if (context.mounted) {
                  _showCompletionDialog(context, session.formattedDuration);
                }
              }
            },
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
              side: BorderSide(
                color: colorScheme.error.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.stop_rounded,
              color: colorScheme.error,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 32),

        // Pause / Resume button
        SizedBox(
          width: 80,
          height: 80,
          child: ElevatedButton(
            onPressed: timer.isRunning ? timer.pause : timer.resume,
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: EdgeInsets.zero,
              backgroundColor: timer.selectedSubject?.color ?? colorScheme.primary,
            ),
            child: Icon(
              timer.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 36,
            ),
          ),
        ),
        const SizedBox(width: 32),

        // Reset button
        SizedBox(
          width: 64,
          height: 64,
          child: OutlinedButton(
            onPressed: timer.reset,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              shape: const CircleBorder(),
            ),
            child: Icon(
              Icons.refresh_rounded,
              color: colorScheme.onSurface.withOpacity(0.5),
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  void _showCompletionDialog(BuildContext context, String duration) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(28),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colorScheme.tertiary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: colorScheme.tertiary,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '수고했어요!',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '$duration 동안 집중했습니다',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
