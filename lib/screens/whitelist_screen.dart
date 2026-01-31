import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/whitelist_provider.dart';

class WhitelistScreen extends StatefulWidget {
  const WhitelistScreen({super.key});

  @override
  State<WhitelistScreen> createState() => _WhitelistScreenState();
}

class _WhitelistScreenState extends State<WhitelistScreen> {
  String _searchQuery = '';
  bool _showWhitelistedOnly = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<WhitelistProvider>().loadInstalledApps();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('허용 앱 관리'),
      ),
      body: Consumer<WhitelistProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('앱 목록 불러오는 중...', style: theme.textTheme.bodyMedium),
                ],
              ),
            );
          }

          final apps = _filteredApps(provider);

          return Column(
            children: [
              // Info banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.tertiary.withOpacity(0.08),
                      colorScheme.primary.withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: colorScheme.tertiary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: colorScheme.tertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '집중 모드 중 사용할 수 있는 앱을 선택하세요.\n전화, 문자, 시계는 기본으로 허용됩니다.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: '앱 검색...',
                    hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3)),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: colorScheme.onSurface.withOpacity(0.3),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Filter toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: '전체',
                      isSelected: !_showWhitelistedOnly,
                      onTap: () => setState(() => _showWhitelistedOnly = false),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: '허용된 앱만',
                      isSelected: _showWhitelistedOnly,
                      onTap: () => setState(() => _showWhitelistedOnly = true),
                    ),
                    const Spacer(),
                    Text(
                      '${provider.whitelistedApps.length}개 허용',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // App list
              Expanded(
                child: apps.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.apps_rounded,
                              size: 48,
                              color: colorScheme.onSurface.withOpacity(0.2),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? '검색 결과가 없습니다'
                                  : '설치된 앱이 없습니다',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: apps.length,
                        itemBuilder: (context, index) {
                          final app = apps[index];
                          return _AppTile(
                            app: app,
                            onToggle: () => provider.toggleWhitelist(app.packageName),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<AppInfo> _filteredApps(WhitelistProvider provider) {
    var apps = _showWhitelistedOnly
        ? provider.whitelistedApps
        : provider.installedApps;

    if (_searchQuery.isNotEmpty) {
      apps = apps
          .where((a) =>
              a.appName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              a.packageName.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    return apps;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withOpacity(0.15)
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colorScheme.primary.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final AppInfo app;
  final VoidCallback onToggle;

  const _AppTile({required this.app, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Icon(
              Icons.android_rounded,
              color: colorScheme.onSurface.withOpacity(0.4),
              size: 22,
            ),
          ),
        ),
        title: Text(
          app.appName,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Text(
          app.packageName,
          style: theme.textTheme.labelSmall,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Switch(
          value: app.isWhitelisted,
          onChanged: (_) => onToggle(),
        ),
      ),
    );
  }
}
