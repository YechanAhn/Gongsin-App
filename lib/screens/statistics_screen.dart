import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/study_provider.dart';
import '../models/study_session.dart';
import '../models/subject.dart';
import '../widgets/study_calendar.dart';
import '../theme/app_colors.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  DateTime? _selectedDate;
  List<StudySession> _selectedDaySessions = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Consumer<StudyProvider>(
        builder: (context, study, _) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '공부 통계',
                    style: theme.textTheme.headlineLarge,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    '매일의 노력이 모여 큰 변화가 됩니다',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 24),

                // Calendar heatmap
                StudyCalendar(
                  year: study.currentYear,
                  month: study.currentMonth,
                  dailyHours: study.monthlyHours,
                  onDayTapped: (date) async {
                    final sessions = await study.getSessionsForDate(date);
                    setState(() {
                      _selectedDate = date;
                      _selectedDaySessions = sessions;
                    });
                  },
                  onPreviousMonth: () => study.navigateMonth(-1),
                  onNextMonth: () => study.navigateMonth(1),
                ),
                const SizedBox(height: 20),

                // Monthly summary
                _MonthlySummary(study: study),
                const SizedBox(height: 20),

                // Selected day detail
                if (_selectedDate != null)
                  _DayDetail(
                    date: _selectedDate!,
                    sessions: _selectedDaySessions,
                    subjects: study.subjects,
                    breakdown: study.getSubjectBreakdown(_selectedDaySessions),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MonthlySummary extends StatelessWidget {
  final StudyProvider study;

  const _MonthlySummary({required this.study});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hours = study.monthlyHours;
    final totalHours = hours.values.fold(0.0, (a, b) => a + b);
    final studyDays = hours.values.where((h) => h > 0).length;
    final avgHours = studyDays > 0 ? totalHours / studyDays : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('이번 달 요약', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  icon: Icons.schedule_rounded,
                  label: '총 공부시간',
                  value: '${totalHours.toStringAsFixed(1)}시간',
                  color: colorScheme.primary,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.calendar_today_rounded,
                  label: '공부한 날',
                  value: '$studyDays일',
                  color: colorScheme.secondary,
                ),
              ),
              Expanded(
                child: _SummaryItem(
                  icon: Icons.trending_up_rounded,
                  label: '일 평균',
                  value: '${avgHours.toStringAsFixed(1)}시간',
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.labelSmall),
      ],
    );
  }
}

class _DayDetail extends StatelessWidget {
  final DateTime date;
  final List<StudySession> sessions;
  final List<Subject> subjects;
  final Map<String, double> breakdown;

  const _DayDetail({
    required this.date,
    required this.sessions,
    required this.subjects,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final totalHours = sessions.fold(0.0, (sum, s) => sum + s.durationHours);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${date.month}월 ${date.day}일',
                style: theme.textTheme.titleLarge,
              ),
              const Spacer(),
              Text(
                '${totalHours.toStringAsFixed(1)}시간',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (sessions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  '공부 기록이 없습니다',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else ...[
            // Subject breakdown pie chart
            if (breakdown.isNotEmpty) ...[
              SizedBox(
                height: 160,
                child: Row(
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: PieChart(
                        PieChartData(
                          sections: _buildPieSections(),
                          centerSpaceRadius: 30,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: breakdown.entries.map((entry) {
                          final subject = subjects.firstWhere(
                            (s) => s.name == entry.key,
                            orElse: () => Subject.defaults.last,
                          );
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: subject.color,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${subject.emoji} ${entry.key}',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const Spacer(),
                                Text(
                                  '${entry.value.toStringAsFixed(1)}h',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Session list
            ...sessions.map((session) {
              final subject = subjects.firstWhere(
                (s) => s.id == session.subjectId,
                orElse: () => Subject.defaults.last,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 32,
                      decoration: BoxDecoration(
                        color: subject.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(subject.emoji),
                    const SizedBox(width: 8),
                    Text(
                      subject.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      session.formattedDuration,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final total = breakdown.values.fold(0.0, (a, b) => a + b);
    return breakdown.entries.map((entry) {
      final subject = subjects.firstWhere(
        (s) => s.name == entry.key,
        orElse: () => Subject.defaults.last,
      );
      return PieChartSectionData(
        value: entry.value,
        color: subject.color,
        radius: 28,
        title: '${(entry.value / total * 100).round()}%',
        titleStyle: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      );
    }).toList();
  }
}
