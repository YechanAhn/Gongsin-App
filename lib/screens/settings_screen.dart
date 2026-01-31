import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../providers/theme_provider.dart';
import '../providers/study_provider.dart';
import '../providers/wallpaper_provider.dart';
import '../models/subject.dart';
import '../services/wallpaper_service.dart';
import 'whitelist_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('설정', style: theme.textTheme.headlineLarge),
            ),
            const SizedBox(height: 24),

            // Appearance
            _SectionHeader(title: '외관'),
            const _ThemeToggleTile(),
            const SizedBox(height: 16),

            // Wallpaper
            _SectionHeader(title: '배경화면'),
            const _WallpaperSettings(),
            const SizedBox(height: 16),

            // D-Day
            _SectionHeader(title: 'D-Day 설정'),
            const _DDaySettingTile(),
            const SizedBox(height: 16),

            // Subjects
            _SectionHeader(title: '과목 관리'),
            const _SubjectManagement(),
            const SizedBox(height: 16),

            // App whitelist
            _SectionHeader(title: '앱 관리'),
            _SettingsTile(
              icon: Icons.shield_outlined,
              title: '허용 앱 관리',
              subtitle: '집중 모드 중 사용할 앱을 설정합니다',
              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const WhitelistScreen()),
                );
              },
            ),
            const SizedBox(height: 16),

            // About
            _SectionHeader(title: '정보'),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: '공신 v1.0.0',
              subtitle: '스마트한 허용 + 예쁜 동기부여',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: colorScheme.onSurface.withOpacity(0.6)),
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: subtitle != null
            ? Text(subtitle!, style: theme.textTheme.bodySmall)
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

class _ThemeToggleTile extends StatelessWidget {
  const _ThemeToggleTile();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return _SettingsTile(
          icon: themeProvider.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
          title: '다크 모드',
          subtitle: themeProvider.isDark ? '다크 모드 사용 중' : '라이트 모드 사용 중',
          trailing: Switch(
            value: themeProvider.isDark,
            onChanged: (_) => themeProvider.toggleTheme(),
          ),
        );
      },
    );
  }
}

class _DDaySettingTile extends StatefulWidget {
  const _DDaySettingTile();

  @override
  State<_DDaySettingTile> createState() => _DDaySettingTileState();
}

class _DDaySettingTileState extends State<_DDaySettingTile> {
  DateTime _targetDate = DateTime(2026, 11, 19);
  String _label = '수능';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('dday_target');
    final label = prefs.getString('dday_label');
    if (mounted) {
      setState(() {
        if (timestamp != null) {
          _targetDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
        if (label != null) _label = label;
      });
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            datePickerTheme: DatePickerThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _targetDate = date);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dday_target', date.millisecondsSinceEpoch);
    }
  }

  Future<void> _editLabel() async {
    final controller = TextEditingController(text: _label);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('D-Day 이름'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '예: 수능, 중간고사',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _label = result);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dday_label', result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SettingsTile(
          icon: Icons.edit_calendar_rounded,
          title: _label,
          subtitle: DateFormat('yyyy년 M월 d일').format(_targetDate),
          trailing: const Icon(Icons.chevron_right_rounded, size: 20),
          onTap: _pickDate,
        ),
        _SettingsTile(
          icon: Icons.label_outline_rounded,
          title: 'D-Day 이름 변경',
          subtitle: '현재: $_label',
          onTap: _editLabel,
        ),
      ],
    );
  }
}

class _SubjectManagement extends StatelessWidget {
  const _SubjectManagement();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<StudyProvider>(
      builder: (context, study, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colorScheme.outline, width: 1),
          ),
          child: Column(
            children: [
              ...study.subjects.map((subject) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
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
                        const SizedBox(width: 12),
                        Text(subject.emoji),
                        const SizedBox(width: 8),
                        Text(subject.name, style: theme.textTheme.bodyLarge),
                        const Spacer(),
                        if (!Subject.defaults
                            .any((d) => d.id == subject.id))
                          IconButton(
                            onPressed: () => study.removeSubject(subject.id),
                            icon: Icon(
                              Icons.remove_circle_outline,
                              size: 18,
                              color: colorScheme.error.withOpacity(0.6),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                      ],
                    ),
                  )),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showAddSubjectDialog(context, study),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('과목 추가'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddSubjectDialog(BuildContext context, StudyProvider study) {
    final nameController = TextEditingController();
    final emojiController = TextEditingController(text: '📚');
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('과목 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: '과목명',
                hintText: '예: 물리학',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emojiController,
              decoration: InputDecoration(
                labelText: '이모지',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final id = nameController.text
                    .toLowerCase()
                    .replaceAll(' ', '_');
                study.addSubject(Subject(
                  id: id,
                  name: nameController.text,
                  emoji: emojiController.text.isNotEmpty
                      ? emojiController.text
                      : '📚',
                  colorIndex: study.subjects.length,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }
}

class _WallpaperSettings extends StatelessWidget {
  const _WallpaperSettings();

  @override
  Widget build(BuildContext context) {
    return Consumer<WallpaperProvider>(
      builder: (context, wallpaper, _) {
        return Column(
          children: [
            _SettingsTile(
              icon: Icons.image_outlined,
              title: '카테고리',
              subtitle: '${wallpaper.selectedCategory.emoji} ${wallpaper.selectedCategory.nameKo}',
              trailing: const Icon(Icons.chevron_right_rounded, size: 20),
              onTap: () => _showCategoryPicker(context, wallpaper),
            ),
            _SettingsTile(
              icon: Icons.autorenew_rounded,
              title: '매일 자동 변경',
              subtitle: wallpaper.autoChange ? '매일 새 배경화면' : '수동으로 변경',
              trailing: Switch(
                value: wallpaper.autoChange,
                onChanged: (v) => wallpaper.setAutoChange(v),
              ),
            ),
            _SettingsTile(
              icon: Icons.vpn_key_outlined,
              title: 'API 키 설정',
              subtitle: wallpaper.hasApiKey ? '설정 완료' : '배경화면을 사용하려면 API 키가 필요합니다',
              trailing: Icon(
                wallpaper.hasApiKey ? Icons.check_circle : Icons.chevron_right_rounded,
                size: 20,
                color: wallpaper.hasApiKey ? const Color(0xFFA8D8C8) : null,
              ),
              onTap: () => _showApiKeyDialog(context, wallpaper),
            ),
            if (wallpaper.hasApiKey)
              _SettingsTile(
                icon: Icons.refresh_rounded,
                title: '지금 배경화면 바꾸기',
                subtitle: '새로운 배경화면을 불러옵니다',
                onTap: wallpaper.refreshWallpaper,
              ),
          ],
        );
      },
    );
  }

  void _showCategoryPicker(BuildContext context, WallpaperProvider wallpaper) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('배경화면 카테고리', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: WallpaperCategory.all.map((category) {
                final isSelected = wallpaper.selectedCategory.id == category.id;
                return GestureDetector(
                  onTap: () {
                    wallpaper.selectCategory(category);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary.withOpacity(0.15)
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary.withOpacity(0.4)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(category.emoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          category.nameKo,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showApiKeyDialog(BuildContext context, WallpaperProvider wallpaper) {
    final unsplashController = TextEditingController();
    final pixabayController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('API 키 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '무료 API 키를 발급받아 입력하세요.\n매일 예쁜 배경화면이 자동으로 바뀝니다.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: unsplashController,
              decoration: InputDecoration(
                labelText: 'Unsplash API Key',
                hintText: 'unsplash.com/developers 에서 발급',
                hintStyle: const TextStyle(fontSize: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: pixabayController,
              decoration: InputDecoration(
                labelText: 'Pixabay API Key (선택)',
                hintText: 'pixabay.com/api/docs 에서 발급',
                hintStyle: const TextStyle(fontSize: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (unsplashController.text.isNotEmpty) {
                await wallpaper.setUnsplashKey(unsplashController.text.trim());
              }
              if (pixabayController.text.isNotEmpty) {
                await wallpaper.setPixabayKey(pixabayController.text.trim());
              }
              if (wallpaper.hasApiKey) {
                await wallpaper.fetchDailyWallpaper();
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
