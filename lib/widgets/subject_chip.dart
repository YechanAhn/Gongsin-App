import 'package:flutter/material.dart';
import '../models/subject.dart';

class SubjectChipRow extends StatelessWidget {
  final List<Subject> subjects;
  final Subject? selected;
  final ValueChanged<Subject> onSelected;

  const SubjectChipRow({
    super.key,
    required this.subjects,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: subjects.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final subject = subjects[index];
          final isSelected = selected?.id == subject.id;
          return SubjectChip(
            subject: subject,
            isSelected: isSelected,
            onTap: () => onSelected(subject),
          );
        },
      ),
    );
  }
}

class SubjectChip extends StatelessWidget {
  final Subject subject;
  final bool isSelected;
  final VoidCallback onTap;

  const SubjectChip({
    super.key,
    required this.subject,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? subject.color.withOpacity(0.2)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? subject.color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(subject.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              subject.name,
              style: theme.textTheme.labelLarge?.copyWith(
                color: isSelected
                    ? subject.color
                    : theme.textTheme.labelLarge?.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
