import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/wallpaper_provider.dart';
import '../data/quotes.dart';

class WallpaperCard extends StatelessWidget {
  final String? ddayText;

  const WallpaperCard({super.key, this.ddayText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<WallpaperProvider>(
      builder: (context, wallpaper, _) {
        final photo = wallpaper.currentPhoto;
        final quote = QuotesData.ofTheDay();

        if (photo == null) {
          // No wallpaper set -- show gradient placeholder with setup hint
          return _PlaceholderCard(
            quote: quote,
            ddayText: ddayText,
            hasApiKey: wallpaper.hasApiKey,
            onSetup: () => _showApiKeyDialog(context, wallpaper),
            onRefresh: wallpaper.hasApiKey ? wallpaper.refreshWallpaper : null,
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 200,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              CachedNetworkImage(
                imageUrl: photo.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primary.withOpacity(0.3),
                        colorScheme.tertiary.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white54,
                    ),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(child: Icon(Icons.image_not_supported)),
                ),
              ),

              // Dark overlay for text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.15),
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),

              // Quote + D-Day overlay
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      quote.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.6,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '— ${quote.author}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    if (ddayText != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        ddayText!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 8),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Attribution
              Positioned(
                bottom: 6,
                right: 10,
                child: Text(
                  photo.attribution,
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ),

              // Refresh button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: wallpaper.refreshWallpaper,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
        title: const Text('배경화면 API 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unsplash 또는 Pixabay API 키를 입력하면\n예쁜 배경화면이 매일 자동으로 바뀝니다.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: unsplashController,
              decoration: InputDecoration(
                labelText: 'Unsplash API Key',
                hintText: 'unsplash.com/developers',
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
                hintText: 'pixabay.com/api/docs',
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
            child: const Text('나중에'),
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

class _PlaceholderCard extends StatelessWidget {
  final Quote quote;
  final String? ddayText;
  final bool hasApiKey;
  final VoidCallback onSetup;
  final VoidCallback? onRefresh;

  const _PlaceholderCard({
    required this.quote,
    this.ddayText,
    required this.hasApiKey,
    required this.onSetup,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Quote content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    quote.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '— ${quote.author}',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  if (ddayText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      ddayText!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Setup / refresh button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: hasApiKey ? onRefresh : onSetup,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasApiKey ? Icons.refresh_rounded : Icons.add_photo_alternate_outlined,
                      size: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasApiKey ? '새로고침' : '배경화면 설정',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
