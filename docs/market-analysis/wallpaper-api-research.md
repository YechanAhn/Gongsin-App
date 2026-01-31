# Wallpaper/Photo API Research: Free Sources for Gongsin App

This document analyzes free stock photo APIs that can provide inspiring, motivational wallpaper content (nature scenery, world landmarks, cityscapes) for the Gongsin focus app targeting Korean students.

-----

## Critical Context: We Are NOT a Wallpaper App

The Gongsin App is a **focus/study app** with a custom Android launcher that displays motivational backgrounds. The wallpaper feature is **supplementary** to the core study functionality (app blocking, study timer, rankings, SNS sharing). This distinction is legally critical because multiple APIs explicitly prohibit standalone wallpaper apps but **do allow** images as part of a broader application that provides independent value.

-----

## API Comparison Summary

| Criteria | Unsplash | Pixabay | Pexels |
|----------|----------|---------|--------|
| **Commercial Use** | Yes (free) | Yes (free) | Yes (free) |
| **Wallpaper App OK?** | NO (standalone) / YES (as feature in broader app) | YES (if value is added) | NO (explicitly prohibited) |
| **Attribution Required** | Yes (photographer + Unsplash link) | Appreciated (mention Pixabay) | Yes (photographer + Pexels link) |
| **Rate Limit (Default)** | 50 req/hr (demo) | 100 req/min | 200 req/hr, 20K/month |
| **Rate Limit (Production)** | 5,000 req/hr (after approval) | Increase on request | Unlimited (on request, free) |
| **Image Library Size** | 3M+ photos | 1.9M+ photos/videos/illustrations | Large (millions) |
| **Max Resolution** | Original (raw), Full, 1080px (regular) | Full res (with approved access), 640px (default) | Original, up to 24MP+ |
| **Content Quality** | Excellent (curated, professional) | Good (community, mixed quality) | Excellent (curated, professional) |
| **Search/Categories** | Topics + free-text search | 20 categories + free-text search | Free-text search + curated feed |
| **Best For Our App** | PRIMARY choice | SECONDARY/supplementary | NOT RECOMMENDED |

-----

## 1. Unsplash API -- RECOMMENDED PRIMARY SOURCE

### License Terms
- All photos on Unsplash are free to use for **both commercial and non-commercial purposes**.
- No permission or credit is legally required, though attribution is appreciated and **required when using the API**.
- License: irrevocable, worldwide, royalty-free.

### Wallpaper Use in Our App: LIKELY PERMITTED
Unsplash's API guidelines state: "You cannot replicate the core user experience of Unsplash (unofficial clients, **wallpaper applications**, etc.)." However, they clarify:
- A standalone wallpaper app where the API is the sole source of content = **NOT ALLOWED**
- Integration inside an existing app that offers additional value = **ALLOWED**
- The test: "without the integration, does the app have content and value to users?" If yes, you can use the API.

**For Gongsin App**: The app provides study timers, app blocking, rankings, SNS sharing, and motivational quotes independently of any photo API. The wallpaper/background is supplementary to the core focus features. This should qualify as permitted use. **Recommendation: Email Unsplash before launch** (they encourage this for borderline cases).

### API Requirements (Mandatory)
1. **Hotlinking required**: Must use image URLs from `photo.urls` directly (their CDN). Cannot download and re-host images on your own server.
2. **Track download events**: When a user sets an image as wallpaper/background, you must call the download tracking endpoint (`GET /photos/:id/download`).
3. **Attribution**: Display photographer name + link to their Unsplash profile, and a link to Unsplash. Use UTM params: `?utm_source=gongsin&utm_medium=referral`.
4. **API key confidentiality**: Use a backend proxy for mobile apps; never embed the API key in client code.

### Rate Limits
| Tier | Limit | How to Get |
|------|-------|------------|
| Demo | 50 requests/hour | Register app on developers portal |
| Production | 5,000 requests/hour | Submit app for review (5 business days) |
| Custom | Higher limits | Contact Unsplash directly |

- Image file requests (images.unsplash.com CDN) do NOT count against rate limits.
- With caching, 5,000 req/hr is more than sufficient for a mobile app.

### Image Sizes Available
| Size | Width | Quality | Use Case |
|------|-------|---------|----------|
| `raw` | Original | Unprocessed | Not recommended (too large) |
| `full` | Original dimensions | q=75-85, JPG | High-res wallpapers (use sparingly) |
| `regular` | 1080px wide | q=75-80, JPG | **Best for mobile wallpapers** |
| `small` | 400px wide | q=75-80, JPG | Thumbnail previews |
| `thumb` | 200px wide | q=75-80, JPG | Grid view / loading placeholder |
| Custom | Any width | Varies | Pass custom width parameter |

**For mobile wallpapers**: `regular` (1080px) is ideal for most phone screens. Use `full` for high-DPI flagship devices. Custom sizes can be requested via URL params.

### Available Topics & Search
Unsplash has **curated Topics** that are directly relevant:
- **Nature** -- landscapes, mountains, oceans, forests, aurora
- **Travel** -- landmarks, tourist destinations, cultural sites
- **Architecture & Interiors** -- cityscapes, famous buildings
- **Wallpapers** -- specifically curated wallpaper-quality images

API Endpoints:
```
GET /topics                          -- list all topics
GET /topics/:slug/photos             -- get photos from a topic
GET /search/photos?query=aurora      -- free-text search
GET /photos/random?query=mountain    -- random photo with filter
GET /photos/random?topics=nature     -- random from topic
```

Search supports English queries. Non-English (Korean) search is in beta -- contact api@unsplash.com for access.

### Implementation Strategy for Gongsin App
```
1. Backend proxy server handles all Unsplash API calls
2. Pre-curate collections of inspiring images by topic:
   - nature/scenery: "aurora", "mountain landscape", "ocean sunset", "forest"
   - landmarks: "eiffel tower", "machu picchu", "santorini", "great wall"
   - cityscapes: "tokyo night", "new york skyline", "seoul cityscape"
3. Cache responses for 24+ hours
4. Display images using hotlinked URLs (their CDN)
5. Show attribution overlay: "Photo by [Name] on Unsplash"
6. Track download events when user sets wallpaper
7. Rotate daily/weekly to keep content fresh
```

-----

## 2. Pixabay API -- RECOMMENDED SECONDARY SOURCE

### License Terms
- **Pixabay License**: irrevocable, worldwide, non-exclusive, royalty-free for commercial and non-commercial use.
- Attribution is **not required** but requested when using the API (mention Pixabay as source).
- No permission needed from photographer.

### Wallpaper Use in Our App: PERMITTED WITH CONDITIONS
Pixabay prohibits: "Sale or distribution of Content as digital content or as digital wallpapers" on a **standalone** basis where "no creative effort has been applied and it remains in substantially the same form."

**For Gongsin App**: Since we are:
- Adding motivational quotes/text overlays on images
- Combining images with D-Day counters, study stats, time widgets
- Using images as backgrounds within a study app (not as standalone wallpapers for download)

This constitutes "adding value" and creating a "new creative work," which is explicitly permitted. Adding Korean motivational text overlays to nature photos transforms the content.

### Rate Limits
| Limit | Value |
|-------|-------|
| Default | 100 requests per minute |
| Cache requirement | Must cache responses for 24 hours |
| Increase | Contact Pixabay with proper implementation |

### Image Sizes Available
| Size | Resolution | Access |
|------|-----------|--------|
| `previewURL` | 150px wide | Default API access |
| `webformatURL` | 640px wide | Default API access |
| `largeImageURL` | 1280px wide | Default API access |
| Full resolution | Original (e.g., 5472x3080) | **Requires approved full API access** |

**For mobile wallpapers**: `largeImageURL` (1280px) works for most devices. Full resolution requires approval.

### Categories (20 built-in)
Directly relevant to our needs:
- **nature** -- landscapes, mountains, oceans, forests
- **travel** -- tourist destinations, cultural experiences
- **buildings** -- architecture, cityscapes, landmarks
- **places** -- geographic locations, scenic spots
- **backgrounds** -- wallpaper-quality images

API Endpoint:
```
GET /api/?key=KEY&q=aurora+borealis&category=nature&image_type=photo
GET /api/?key=KEY&q=eiffel+tower&category=travel&image_type=photo
GET /api/?key=KEY&q=cityscape+night&category=buildings&image_type=photo
```

### Advantages Over Unsplash
- No hotlinking requirement (can download and cache on own server)
- Built-in category filtering (20 categories)
- Higher default rate limit (100/min vs 50/hr)
- Simpler attribution requirement

### Disadvantages vs Unsplash
- Lower overall image quality (community uploads vs curated)
- Default API only returns 640px images (need approval for full res)
- Smaller library for specific aesthetic/inspirational content
- Less "premium" feel to photography

-----

## 3. Pexels API -- NOT RECOMMENDED FOR THIS APP

### Why Not
Pexels **explicitly prohibits wallpaper apps**:
> "You may not copy or replicate core functionality of Pexels, including making Pexels content available as a wallpaper app."

Their help center FAQ titled "Can I use the API as a wallpaper app?" answers with a clear **NO**. Even though our app is primarily a focus app, the wallpaper feature would likely be considered as "making Pexels content available as wallpaper," which risks API key revocation.

### If We Wanted to Use It Anyway
- Would need to email api@pexels.com and obtain **explicit written permission**
- The open-source app "Prism" claimed to have gotten such permission, but this is rare
- Risk of API access being revoked at any time

### Image Quality (For Reference)
Despite the restriction, Pexels does offer excellent image quality:
- 8 size variants: original, large2x, large (940px), medium (350px), small (130px), portrait (800x1200), landscape (1200x627), tiny (280x200)
- High-quality curated library
- Rate limit: 200 req/hr, 20K/month (expandable for free)

**Verdict**: Too risky. Use Unsplash and Pixabay instead.

-----

## 4. Other APIs Considered

### Wallhaven API
- **Purpose**: Dedicated wallpaper platform
- **Rate limit**: 45 requests/minute
- **License**: Varies per image (no blanket commercial license)
- **Verdict**: NOT RECOMMENDED -- no guaranteed commercial use rights per image. Each wallpaper has its own license from the uploader. Too risky for a commercial app without per-image license verification.

### Lorem Picsum
- **Purpose**: Random placeholder images from Unsplash
- **Verdict**: NOT SUITABLE -- meant for development/placeholder use, not production wallpapers. No search or category filtering.

### Flickr API
- **Purpose**: Photo sharing platform
- **License**: Mixed (must filter by Creative Commons license)
- **Verdict**: POSSIBLE but complex -- must filter by CC-BY or CC0 license. Quality varies wildly. Not worth the complexity when Unsplash and Pixabay are available.

-----

## Recommended Implementation Architecture

### Dual-Source Strategy: Unsplash (Primary) + Pixabay (Fallback)

```
                    +------------------+
                    |   Gongsin App    |
                    |  (Android/iOS)   |
                    +--------+---------+
                             |
                    +--------+---------+
                    |  Backend Proxy   |
                    |  (API Key Mgmt)  |
                    +--------+---------+
                             |
              +--------------+--------------+
              |                             |
    +---------+----------+     +-----------+---------+
    |   Unsplash API     |     |   Pixabay API       |
    |   (Primary)        |     |   (Fallback)        |
    |                    |     |                     |
    | - Nature topics    |     | - Category filter   |
    | - Travel search    |     | - nature, travel,   |
    | - Architecture     |     |   buildings, places |
    | - Wallpapers topic |     | - backgrounds       |
    | - Hotlink images   |     | - Can cache locally |
    +--------------------+     +---------------------+
```

### Content Categories for Korean Students

| Category (Korean) | Category (English) | Unsplash Search | Pixabay Search |
|---|---|---|---|
| 자연 풍경 | Nature Scenery | `query=mountain landscape`, topic=nature | `category=nature&q=mountain` |
| 오로라 | Aurora | `query=aurora borealis` | `q=aurora+borealis&category=nature` |
| 바다/해변 | Ocean/Beach | `query=ocean sunset` | `q=ocean+sunset&category=nature` |
| 숲/나무 | Forest | `query=forest path` | `q=forest&category=nature` |
| 세계 랜드마크 | World Landmarks | `query=eiffel tower` | `q=eiffel+tower&category=travel` |
| 마추픽추 | Machu Picchu | `query=machu picchu` | `q=machu+picchu&category=travel` |
| 도시 야경 | City Night | `query=city skyline night` | `q=cityscape+night&category=buildings` |
| 드림 시티 | Dream City | `query=futuristic cityscape` | `q=modern+city&category=buildings` |
| 벚꽃/계절 | Cherry Blossom | `query=cherry blossom` | `q=cherry+blossom&category=nature` |
| 우주/별 | Space/Stars | `query=milky way stars` | `q=milky+way&category=nature` |

### Adding Value: Motivational Overlay System

To comply with both Unsplash and Pixabay terms (and to align with the app's educational mission), combine API photos with:

1. **Korean motivational quotes** overlaid on the image
   - "오늘 하루도 최선을 다하자" (Let's do our best today)
   - "꿈을 향해 한 걸음 더" (One more step toward your dream)
   - D-Day counter: "수능까지 D-127"
2. **Study progress widget** shown over the wallpaper
3. **Time/weather info** integrated into the background
4. **Custom color gradient overlay** to ensure text readability

This transforms the stock photo from "standalone content" into a "new creative work" integrated with the app's core study features.

-----

## Cost Analysis

| Item | Cost |
|------|------|
| Unsplash API | Free (demo: 50 req/hr, production: 5,000 req/hr) |
| Pixabay API | Free (100 req/min) |
| Backend proxy hosting | ~$5-20/month (for API key management + caching) |
| CDN for cached Pixabay images | ~$5-10/month (if caching locally) |
| **Total** | **~$10-30/month** |

For Unsplash, images are served from their CDN (hotlinking required), so no image hosting costs. For Pixabay, you may cache images on your own infrastructure.

-----

## Action Items Before Launch

1. **Register for Unsplash API**: Create developer account at https://unsplash.com/developers
2. **Register for Pixabay API**: Create account at https://pixabay.com/api/docs/
3. **Email Unsplash** (api@unsplash.com): Describe Gongsin App as a focus/study app with wallpaper as a supplementary feature. Ask for confirmation that this use case is permitted. Mention the app provides independent value (timers, blocking, rankings) without the photo integration.
4. **Apply for Unsplash Production status**: Upload screenshots showing proper attribution and photo usage once the app is built.
5. **Apply for Pixabay full API access**: Request access to full-resolution images.
6. **Build backend proxy**: Never expose API keys in mobile client code.
7. **Implement proper attribution UI**: Photographer credit + source link on every background image.
8. **Implement download event tracking**: Call Unsplash download endpoint when wallpaper is set.
9. **Implement 24-hour response caching**: Required by both APIs.
10. **Test Korean search queries**: Unsplash non-English search is in beta; test coverage for Korean landmarks and nature terms.
