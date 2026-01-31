import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class DDayWidget extends StatefulWidget {
  const DDayWidget({super.key});

  @override
  State<DDayWidget> createState() => _DDayWidgetState();
}

class _DDayWidgetState extends State<DDayWidget> {
  DateTime? _targetDate;
  String _targetLabel = '수능';

  @override
  void initState() {
    super.initState();
    _loadTarget();
  }

  Future<void> _loadTarget() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('dday_target');
    final label = prefs.getString('dday_label');
    setState(() {
      _targetDate = timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : DateTime(2026, 11, 19); // 2026 수능 예상일
      _targetLabel = label ?? '수능';
    });
  }

  int get _daysRemaining {
    if (_targetDate == null) return 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(_targetDate!.year, _targetDate!.month, _targetDate!.day);
    return target.difference(today).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final days = _daysRemaining;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.tertiary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'D',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.tertiary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _targetLabel,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 2),
                if (_targetDate != null)
                  Text(
                    DateFormat('yyyy.MM.dd').format(_targetDate!),
                    style: theme.textTheme.labelSmall,
                  ),
              ],
            ),
          ),
          Text(
            days > 0 ? 'D-$days' : days == 0 ? 'D-Day' : 'D+${days.abs()}',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
            ),
          ),
        ],
      ),
    );
  }
}
