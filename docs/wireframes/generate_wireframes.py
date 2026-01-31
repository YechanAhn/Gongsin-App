#!/usr/bin/env python3
"""Generate wireframe images for Gongsin App screens."""

from PIL import Image, ImageDraw, ImageFont
import os

# ─── Colors ───
BG_LIGHT = (248, 247, 252)
SURFACE = (255, 255, 255)
SURFACE_VAR = (242, 239, 248)
PRIMARY = (184, 169, 201)
PRIMARY_DARK = (145, 130, 168)
SECONDARY = (242, 196, 206)
ACCENT = (168, 216, 200)
TEXT_PRIMARY = (45, 45, 58)
TEXT_SECONDARY = (142, 142, 154)
TEXT_HINT = (184, 184, 196)
DIVIDER = (238, 236, 242)
WHITE = (255, 255, 255)
ERROR_RED = (229, 115, 115)

# Dark mode colors
BG_DARK = (26, 26, 46)
SURFACE_DARK = (37, 37, 58)
PRIMARY_D = (196, 181, 216)
TEXT_PRIMARY_D = (234, 234, 240)
TEXT_SECONDARY_D = (152, 152, 168)
DIVIDER_DARK = (58, 58, 80)

# Subject colors
LAVENDER = (184, 169, 201)
PINK = (242, 196, 206)
MINT = (168, 216, 200)
PEACH = (245, 213, 160)
SKY = (168, 200, 240)
CORAL = (240, 184, 184)
LIME = (200, 224, 168)

# Calendar intensity
CAL_LEVELS = [
    (0, 0, 0, 0),
    (184, 169, 201, 50),
    (184, 169, 201, 100),
    (184, 169, 201, 150),
    (184, 169, 201, 200),
    (184, 169, 201, 255),
]

PHONE_W, PHONE_H = 360, 720
RADIUS = 28
SCREEN_PAD = 60

def try_font(size, bold=False):
    """Try to load a suitable font."""
    paths = [
        "/usr/share/fonts/truetype/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
    ]
    if bold:
        paths = [
            "/usr/share/fonts/truetype/noto/NotoSansCJK-Bold.ttc",
            "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
            "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf",
        ] + paths
    for p in paths:
        if os.path.exists(p):
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()

# Fonts
F_TITLE = try_font(24, True)
F_HEADING = try_font(18, True)
F_BODY = try_font(14)
F_BODY_BOLD = try_font(14, True)
F_SMALL = try_font(11)
F_SMALL_BOLD = try_font(11, True)
F_TINY = try_font(9)
F_HUGE = try_font(40)
F_BIG = try_font(22, True)
F_DDAY = try_font(20, True)
F_TIMER = try_font(48)
F_LABEL = try_font(10)

def rounded_rect(draw, xy, fill, radius=16, outline=None):
    """Draw a rounded rectangle."""
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle(xy, radius=radius, fill=fill, outline=outline)

def draw_phone_frame(img, draw, x, y, dark=False):
    """Draw phone bezel."""
    bg = BG_DARK if dark else BG_LIGHT
    border = DIVIDER_DARK if dark else DIVIDER
    # Outer bezel
    rounded_rect(draw, (x, y, x+PHONE_W, y+PHONE_H), fill=bg, radius=RADIUS, outline=border)
    # Status bar
    sc = TEXT_PRIMARY_D if dark else TEXT_PRIMARY
    draw.text((x+20, y+10), "9:41", font=F_SMALL_BOLD, fill=sc)
    draw.text((x+PHONE_W-60, y+10), "LTE 100%", font=F_TINY, fill=TEXT_SECONDARY)

def draw_nav_bar(draw, x, y, active_idx=0, dark=False):
    """Draw bottom navigation bar."""
    nav_y = y + PHONE_H - 54
    bg = SURFACE_DARK if dark else SURFACE
    border = DIVIDER_DARK if dark else DIVIDER
    rounded_rect(draw, (x+1, nav_y, x+PHONE_W-1, y+PHONE_H-1), fill=bg, radius=0)
    draw.line((x+1, nav_y, x+PHONE_W-1, nav_y), fill=border)

    labels = ["홈", "집중", "통계", "설정"]
    icons = ["◉", "◷", "▤", "⚙"]
    w = PHONE_W // 4
    for i, (icon, label) in enumerate(zip(icons, labels)):
        cx = x + w * i + w // 2
        c = PRIMARY_D if (dark and i == active_idx) else PRIMARY_DARK if i == active_idx else TEXT_HINT
        draw.text((cx-6, nav_y+8), icon, font=F_BODY, fill=c)
        tw = draw.textlength(label, font=F_TINY)
        draw.text((cx - tw//2, nav_y+26), label, font=F_TINY, fill=c)

def draw_card(draw, x, y, w, h, dark=False, radius=14):
    bg = SURFACE_DARK if dark else SURFACE
    border = DIVIDER_DARK if dark else DIVIDER
    rounded_rect(draw, (x, y, x+w, y+h), fill=bg, radius=radius, outline=border)

# ═══════════════════════════════════════════════
# SCREEN 1: HOME
# ═══════════════════════════════════════════════
def draw_home_screen(img, draw, x, y, dark=False):
    draw_phone_frame(img, draw, x, y, dark)
    bg = BG_DARK if dark else BG_LIGHT
    tc = TEXT_PRIMARY_D if dark else TEXT_PRIMARY
    ts = TEXT_SECONDARY_D if dark else TEXT_SECONDARY
    pc = PRIMARY_D if dark else PRIMARY
    ac = ACCENT

    cy = y + 36

    # Title
    draw.text((x+20, cy), "공신", font=F_TITLE, fill=tc)
    rounded_rect(draw, (x+80, cy+4, x+140, cy+22), fill=(*ac, 30), radius=6)
    draw.text((x+86, cy+5), "FOCUS", font=F_TINY, fill=ac)
    cy += 40

    # D-Day card
    draw_card(draw, x+16, cy, PHONE_W-32, 56, dark)
    rounded_rect(draw, (x+26, cy+10, x+62, cy+46), fill=(*ac, 25), radius=10)
    draw.text((x+38, cy+16), "D", font=F_HEADING, fill=ac)
    draw.text((x+72, cy+12), "수능", font=F_SMALL, fill=ts)
    draw.text((x+72, cy+30), "2026.11.19", font=F_TINY, fill=TEXT_HINT)
    draw.text((x+PHONE_W-100, cy+14), "D-292", font=F_DDAY, fill=pc)
    cy += 66

    # Today's study card
    draw_card(draw, x+16, cy, PHONE_W-32, 86, dark)
    draw.text((x+30, cy+12), "🔥 오늘의 공부", font=F_SMALL_BOLD, fill=tc)
    mid = x + PHONE_W // 2
    draw.text((x+50, cy+38), "3시간 24분", font=F_BODY_BOLD, fill=pc)
    draw.text((x+60, cy+58), "공부 시간", font=F_TINY, fill=ts)
    draw.line((mid, cy+36, mid, cy+72), fill=DIVIDER_DARK if dark else DIVIDER)
    draw.text((mid+40, cy+38), "5회", font=F_BODY_BOLD, fill=ac)
    draw.text((mid+30, cy+58), "세션 수", font=F_TINY, fill=ts)
    cy += 96

    # Wallpaper card (gradient)
    cw = PHONE_W - 32
    ch = 130
    # Gradient rectangle
    for row in range(ch):
        ratio = row / ch
        r = int(102 + (118 - 102) * ratio)
        g = int(126 + (75 - 126) * ratio)
        b = int(234 + (162 - 234) * ratio)
        draw.line((x+16, cy+row, x+16+cw, cy+row), fill=(r, g, b))
    # Round corners (approximate)
    rounded_rect(draw, (x+16, cy, x+16+cw, cy+ch), fill=None, radius=16,
                 outline=None)
    # Overlay text
    draw.text((x+60, cy+20), "꿈을 크게 가져라", font=F_BODY_BOLD, fill=WHITE)
    draw.text((x+40, cy+42), "그 꿈이 너를 이끌 것이다", font=F_BODY_BOLD, fill=WHITE)
    draw.text((x+130, cy+65), "— 괴테", font=F_TINY, fill=(*WHITE, 160))
    draw.text((x+110, cy+85), "수능 D-292", font=F_DDAY, fill=WHITE)
    draw.text((x+60, cy+ch-16), "Photo by J. Doe on Unsplash", font=F_LABEL, fill=(*WHITE, 100))
    cy += ch + 10

    # Quote card
    qh = 90
    for row in range(qh):
        r1, g1, b1 = pc
        r2, g2, b2 = SECONDARY
        ratio = row / qh
        r = int(r1 + (r2 - r1) * ratio)
        g = int(g1 + (g2 - g1) * ratio)
        b = int(b1 + (b2 - b1) * ratio)
        draw.line((x+16, cy+row, x+16+cw, cy+row), fill=(r, g, b, 18))
    draw_card(draw, x+16, cy, cw, qh, dark)
    draw.text((x+PHONE_W//2-6, cy+4), "\u201C", font=F_BIG, fill=(*pc, 80))
    draw.text((x+60, cy+30), "천리길도 한 걸음부터", font=F_BODY_BOLD, fill=tc)
    draw.text((x+110, cy+52), "— 한국 속담", font=F_TINY, fill=pc)
    draw.text((x+115, cy+70), "탭하여 다음 명언", font=F_LABEL, fill=TEXT_HINT)
    cy += qh + 10

    # Focus mode card
    draw_card(draw, x+16, cy, cw, 56, dark)
    rounded_rect(draw, (x+26, cy+10, x+62, cy+46), fill=(*pc, 25), radius=10)
    draw.text((x+36, cy+16), "🛡", font=F_BODY, fill=pc)
    draw.text((x+72, cy+12), "집중 모드", font=F_SMALL_BOLD, fill=tc)
    draw.text((x+72, cy+30), "비허용 앱을 차단합니다", font=F_TINY, fill=ts)
    # Toggle off
    rounded_rect(draw, (x+cw-20, cy+18, x+cw+14, cy+38), fill=DIVIDER_DARK if dark else DIVIDER, radius=10)
    draw.ellipse((x+cw-18, cy+20, x+cw-2, cy+36), fill=TEXT_HINT)
    cy += 66

    # Start button
    rounded_rect(draw, (x+16, cy, x+16+cw, cy+48), fill=pc, radius=14)
    draw.text((x+110, cy+12), "▶ 공부 시작하기", font=F_BODY_BOLD, fill=WHITE)

    draw_nav_bar(draw, x, y, 0, dark)


# ═══════════════════════════════════════════════
# SCREEN 2: TIMER
# ═══════════════════════════════════════════════
def draw_timer_screen(img, draw, x, y, running=False, dark=False):
    draw_phone_frame(img, draw, x, y, dark)
    tc = TEXT_PRIMARY_D if dark else TEXT_PRIMARY
    ts = TEXT_SECONDARY_D if dark else TEXT_SECONDARY
    pc = PRIMARY_D if dark else PRIMARY

    cy = y + 36
    title = "집중 중..." if running else "집중할 과목을 선택하세요"
    tw = draw.textlength(title, font=F_HEADING)
    draw.text((x + (PHONE_W - tw) // 2, cy), title, font=F_HEADING, fill=tc)
    cy += 30

    # Subject chips
    chips = [("📖 국어", False), ("📐 수학", True), ("🔤 영어", False), ("🔬 과학", False)]
    cx = x + 16
    for label, selected in chips:
        cw = int(draw.textlength(label, font=F_SMALL)) + 24
        bg = (*PINK, 40) if selected else (SURFACE_VAR if not dark else SURFACE_DARK)
        border = PINK if selected else None
        rounded_rect(draw, (cx, cy, cx+cw, cy+30), fill=bg, radius=15, outline=border)
        draw.text((cx+12, cy+7), label, font=F_SMALL, fill=PINK if selected else tc)
        cx += cw + 8
    cy += 42

    if not running:
        # Mode toggle
        tw_total = 200
        tx = x + (PHONE_W - tw_total) // 2
        rounded_rect(draw, (tx, cy, tx+tw_total, cy+34), fill=SURFACE_VAR if not dark else SURFACE_DARK, radius=12)
        rounded_rect(draw, (tx+3, cy+3, tx+tw_total//2-2, cy+31), fill=SURFACE if not dark else (*SURFACE_DARK, 200), radius=9)
        draw.text((tx+20, cy+9), "스톱워치", font=F_SMALL_BOLD, fill=tc)
        draw.text((tx+tw_total//2+15, cy+9), "포모도로", font=F_SMALL, fill=TEXT_HINT)
        cy += 50

    # Timer ring
    ring_size = 200
    ring_x = x + (PHONE_W - ring_size) // 2
    ring_y = cy + 30 if not running else cy + 10
    # Background ring
    draw.ellipse((ring_x, ring_y, ring_x+ring_size, ring_y+ring_size),
                 outline=DIVIDER_DARK if dark else DIVIDER, width=5)

    if running:
        # Progress arc (approximate with thick arc)
        import math
        cx_r = ring_x + ring_size // 2
        cy_r = ring_y + ring_size // 2
        r = ring_size // 2
        # Draw ~120 degree arc
        for angle in range(0, 120):
            a = math.radians(-90 + angle)
            x1 = cx_r + int((r-3) * math.cos(a))
            y1 = cy_r + int((r-3) * math.sin(a))
            x2 = cx_r + int((r+3) * math.cos(a))
            y2 = cy_r + int((r+3) * math.sin(a))
            draw.line((x1, y1, x2, y2), fill=PINK, width=2)

    # Time text
    time_str = "36:24" if running else "00:00"
    ttw = draw.textlength(time_str, font=F_TIMER)
    draw.text((ring_x + (ring_size - ttw) // 2, ring_y + ring_size//2 - 26),
              time_str, font=F_TIMER, fill=tc)

    if running:
        # Pulsing dot
        dot_x = ring_x + ring_size // 2
        draw.ellipse((dot_x-3, ring_y+ring_size//2+28, dot_x+3, ring_y+ring_size//2+34), fill=PINK)
        # Elapsed
        draw.text((dot_x-12, ring_y+ring_size//2+38), "36분", font=F_TINY, fill=ts)

    btn_y = ring_y + ring_size + 40

    if running:
        # Stop, Pause, Reset
        bcx = x + PHONE_W // 2
        # Stop
        draw.ellipse((bcx-80, btn_y, bcx-30, btn_y+50), outline=(*ERROR_RED, 120), width=2)
        draw.text((bcx-62, btn_y+14), "■", font=F_BODY, fill=ERROR_RED)
        # Pause (main)
        draw.ellipse((bcx-30, btn_y-8, bcx+30, btn_y+58), fill=PINK)
        draw.text((bcx-8, btn_y+12), "⏸", font=F_HEADING, fill=WHITE)
        # Reset
        draw.ellipse((bcx+30, btn_y, bcx+80, btn_y+50), outline=DIVIDER, width=2)
        draw.text((bcx+48, btn_y+14), "↻", font=F_BODY, fill=TEXT_HINT)
    else:
        # Start button
        bw = 160
        bx = x + (PHONE_W - bw) // 2
        rounded_rect(draw, (bx, btn_y, bx+bw, btn_y+48), fill=PINK, radius=14)
        stw = draw.textlength("▶ 시작", font=F_BODY_BOLD)
        draw.text((bx + (bw - stw)//2, btn_y+14), "▶ 시작", font=F_BODY_BOLD, fill=WHITE)

    draw_nav_bar(draw, x, y, 1, dark)


# ═══════════════════════════════════════════════
# SCREEN 3: STATISTICS
# ═══════════════════════════════════════════════
def draw_stats_screen(img, draw, x, y, dark=False):
    draw_phone_frame(img, draw, x, y, dark)
    tc = TEXT_PRIMARY_D if dark else TEXT_PRIMARY
    ts = TEXT_SECONDARY_D if dark else TEXT_SECONDARY
    pc = PRIMARY_D if dark else PRIMARY

    cy = y + 36
    draw.text((x+20, cy), "공부 통계", font=F_TITLE, fill=tc)
    cy += 28
    draw.text((x+20, cy), "매일의 노력이 모여 큰 변화가 됩니다", font=F_TINY, fill=ts)
    cy += 22

    # Calendar card
    cw = PHONE_W - 32
    ch = 290
    draw_card(draw, x+16, cy, cw, ch, dark)

    # Month nav
    draw.text((x+30, cy+10), "◀", font=F_SMALL, fill=TEXT_HINT)
    mtw = draw.textlength("2026년 1월", font=F_BODY_BOLD)
    draw.text((x + (PHONE_W - mtw) // 2, cy+10), "2026년 1월", font=F_BODY_BOLD, fill=tc)
    draw.text((x+PHONE_W-50, cy+10), "▶", font=F_SMALL, fill=TEXT_HINT)

    # Weekdays
    weekdays = ["일", "월", "화", "수", "목", "금", "토"]
    cell_w = (cw - 20) // 7
    wy = cy + 36
    for i, wd in enumerate(weekdays):
        wdw = draw.textlength(wd, font=F_TINY)
        wx = x + 26 + i * cell_w + (cell_w - wdw) // 2
        c = ERROR_RED if i == 0 else (168, 200, 240) if i == 6 else TEXT_HINT
        draw.text((wx, wy), wd, font=F_TINY, fill=c)

    # Calendar grid (Jan 2026 starts on Thursday, idx=4)
    import random
    random.seed(42)
    study_data = {}
    for d in range(1, 32):
        if random.random() > 0.15:
            study_data[d] = round(random.uniform(0.5, 10.5), 1)

    start_offset = 4  # Thursday
    day_y = wy + 18
    for d in range(1, 32):
        idx = (d - 1 + start_offset)
        row = idx // 7
        col = idx % 7
        dx = x + 26 + col * cell_w
        dy = day_y + row * 38

        hours = study_data.get(d, 0)
        # Color intensity
        if hours > 0:
            if hours <= 2: alpha = 50
            elif hours <= 4: alpha = 100
            elif hours <= 6: alpha = 150
            elif hours <= 8: alpha = 200
            else: alpha = 240
            fill = (*PRIMARY[:3], alpha) if not dark else (*PRIMARY_D[:3], alpha)
            rounded_rect(draw, (dx, dy, dx+cell_w-4, dy+34), fill=fill, radius=8)

        # Today highlight (31st)
        if d == 31:
            rounded_rect(draw, (dx, dy, dx+cell_w-4, dy+34), fill=None, radius=8, outline=pc)

        # Day number
        dtw = draw.textlength(str(d), font=F_SMALL)
        text_c = WHITE if hours > 8 else tc
        draw.text((dx + (cell_w-4-dtw)//2, dy+4), str(d), font=F_SMALL, fill=text_c)

        # Hours label
        if hours > 0:
            htxt = f"{hours:.1f}h"
            htw = draw.textlength(htxt, font=F_LABEL)
            hc = (*WHITE, 180) if hours > 8 else (*ts, 180)
            draw.text((dx + (cell_w-4-htw)//2, dy+20), htxt, font=F_LABEL, fill=hc)

    # Legend
    ly = cy + ch - 24
    draw.text((x+70, ly), "적음", font=F_LABEL, fill=TEXT_HINT)
    for i in range(6):
        lx = x + 100 + i * 18
        alpha = [20, 50, 100, 150, 200, 240][i]
        rounded_rect(draw, (lx, ly, lx+12, ly+12), fill=(*PRIMARY[:3], alpha), radius=2)
    draw.text((x+210, ly), "많음", font=F_LABEL, fill=TEXT_HINT)

    cy += ch + 10

    # Monthly summary card
    draw_card(draw, x+16, cy, cw, 80, dark)
    draw.text((x+30, cy+10), "이번 달 요약", font=F_SMALL_BOLD, fill=tc)

    # Stats
    stats = [
        ("⏰", "115.2시간", "총 공부시간", pc),
        ("📅", "26일", "공부한 날", SECONDARY),
        ("📈", "4.4시간", "일 평균", ACCENT),
    ]
    sw = cw // 3
    for i, (icon, val, label, color) in enumerate(stats):
        sx = x + 26 + i * sw
        draw.text((sx + sw//2 - 6, cy+30), icon, font=F_SMALL, fill=color)
        vtw = draw.textlength(val, font=F_SMALL_BOLD)
        draw.text((sx + (sw-vtw)//2, cy+48), val, font=F_SMALL_BOLD, fill=color)
        ltw = draw.textlength(label, font=F_LABEL)
        draw.text((sx + (sw-ltw)//2, cy+64), label, font=F_LABEL, fill=ts)

    draw_nav_bar(draw, x, y, 2, dark)


# ═══════════════════════════════════════════════
# SCREEN 4: SETTINGS
# ═══════════════════════════════════════════════
def draw_settings_screen(img, draw, x, y, dark=False):
    draw_phone_frame(img, draw, x, y, dark)
    tc = TEXT_PRIMARY_D if dark else TEXT_PRIMARY
    ts = TEXT_SECONDARY_D if dark else TEXT_SECONDARY
    pc = PRIMARY_D if dark else PRIMARY

    cy = y + 36
    draw.text((x+20, cy), "설정", font=F_TITLE, fill=tc)
    cy += 36

    sections = [
        ("외관", [
            ("☀️", "다크 모드", "라이트 모드 사용 중", "toggle"),
        ]),
        ("배경화면", [
            ("🖼", "카테고리", "🏔 자연 풍경", "arrow"),
            ("🔄", "매일 자동 변경", "매일 새 배경화면", "toggle_on"),
            ("🔑", "API 키 설정", "설정 완료 ✓", "arrow"),
        ]),
        ("D-Day 설정", [
            ("📅", "수능", "2026년 11월 19일", "arrow"),
        ]),
        ("과목 관리", [
            ("📚", "7개 과목", "국어, 수학, 영어, 과학...", "arrow"),
        ]),
        ("앱 관리", [
            ("🛡", "허용 앱 관리", "12개 앱 허용 중", "arrow"),
        ]),
        ("정보", [
            ("ℹ", "공신 v1.0.0", "스마트한 허용 + 예쁜 동기부여", None),
        ]),
    ]

    for section_name, items in sections:
        draw.text((x+20, cy), section_name, font=F_SMALL_BOLD, fill=pc)
        cy += 20
        for icon, title, subtitle, trailing in items:
            # Icon box
            rounded_rect(draw, (x+20, cy, x+50, cy+30), fill=SURFACE_VAR if not dark else SURFACE_DARK, radius=8)
            draw.text((x+28, cy+6), icon, font=F_SMALL, fill=ts)
            # Text
            draw.text((x+60, cy+2), title, font=F_SMALL_BOLD, fill=tc)
            draw.text((x+60, cy+18), subtitle, font=F_LABEL, fill=ts)
            # Trailing
            if trailing == "toggle":
                rounded_rect(draw, (x+PHONE_W-60, cy+6, x+PHONE_W-24, cy+24), fill=DIVIDER, radius=9)
                draw.ellipse((x+PHONE_W-58, cy+8, x+PHONE_W-42, cy+22), fill=TEXT_HINT)
            elif trailing == "toggle_on":
                rounded_rect(draw, (x+PHONE_W-60, cy+6, x+PHONE_W-24, cy+24), fill=(*pc, 60), radius=9)
                draw.ellipse((x+PHONE_W-42, cy+8, x+PHONE_W-26, cy+22), fill=pc)
            elif trailing == "arrow":
                draw.text((x+PHONE_W-30, cy+6), "›", font=F_BODY, fill=TEXT_HINT)
            cy += 38
        cy += 6

    draw_nav_bar(draw, x, y, 3, dark)


# ═══════════════════════════════════════════════
# SCREEN 5: WHITELIST
# ═══════════════════════════════════════════════
def draw_whitelist_screen(img, draw, x, y, dark=False):
    draw_phone_frame(img, draw, x, y, dark)
    tc = TEXT_PRIMARY_D if dark else TEXT_PRIMARY
    ts = TEXT_SECONDARY_D if dark else TEXT_SECONDARY
    pc = PRIMARY_D if dark else PRIMARY

    cy = y + 36
    draw.text((x+20, cy), "← 허용 앱 관리", font=F_HEADING, fill=tc)
    cy += 32

    # Info banner
    bh = 46
    for row in range(bh):
        ratio = row / bh
        r = int(ACCENT[0] + (pc[0] - ACCENT[0]) * ratio)
        g = int(ACCENT[1] + (pc[1] - ACCENT[1]) * ratio)
        b = int(ACCENT[2] + (pc[2] - ACCENT[2]) * ratio)
        draw.line((x+16, cy+row, x+PHONE_W-16, cy+row), fill=(r, g, b, 15))
    rounded_rect(draw, (x+16, cy, x+PHONE_W-16, cy+bh), fill=None, radius=12, outline=(*ACCENT, 40))
    draw.text((x+26, cy+6), "ℹ", font=F_SMALL, fill=ACCENT)
    draw.text((x+44, cy+6), "집중 모드 중 사용할 수 있는", font=F_TINY, fill=tc)
    draw.text((x+44, cy+22), "앱을 선택하세요.", font=F_TINY, fill=tc)
    cy += bh + 10

    # Search bar
    rounded_rect(draw, (x+16, cy, x+PHONE_W-16, cy+36), fill=SURFACE_VAR if not dark else SURFACE_DARK, radius=12)
    draw.text((x+30, cy+9), "🔍 앱 검색...", font=F_SMALL, fill=TEXT_HINT)
    cy += 46

    # Filter chips
    rounded_rect(draw, (x+16, cy, x+66, cy+26), fill=(*pc, 30), radius=8, outline=(*pc, 60))
    draw.text((x+26, cy+6), "전체", font=F_TINY, fill=pc)
    rounded_rect(draw, (x+74, cy, x+150, cy+26), fill=SURFACE_VAR if not dark else SURFACE_DARK, radius=8)
    draw.text((x+82, cy+6), "허용된 앱만", font=F_TINY, fill=TEXT_HINT)
    draw.text((x+PHONE_W-80, cy+6), "12개 허용", font=F_TINY, fill=pc)
    cy += 38

    # App items
    apps = [
        ("💬", "카카오톡", "com.kakao.talk", True),
        ("📺", "EBS 온라인클래스", "kr.co.ebs.xenia", True),
        ("📖", "네이버 사전", "com.nhn.android.naverdic", True),
        ("🍽", "급식 알리미", "com.school.lunch", True),
        ("📷", "Instagram", "com.instagram.android", False),
        ("🎬", "YouTube", "com.google.android.youtube", False),
        ("🎵", "TikTok", "com.zhiliaoapp.musically", False),
        ("🎮", "브롤스타즈", "com.supercell.brawlstars", False),
    ]

    for icon, name, pkg, allowed in apps:
        # Icon
        icon_bg = SURFACE_VAR if not dark else SURFACE_DARK
        if not allowed:
            icon_bg = (*ERROR_RED, 20)
        rounded_rect(draw, (x+20, cy, x+52, cy+34), fill=icon_bg, radius=8)
        draw.text((x+28, cy+7), icon, font=F_SMALL, fill=tc)
        # Name
        nc = tc if allowed else ERROR_RED
        draw.text((x+60, cy+2), name, font=F_SMALL_BOLD, fill=nc)
        draw.text((x+60, cy+19), pkg, font=F_LABEL, fill=TEXT_HINT)
        # Toggle
        if allowed:
            rounded_rect(draw, (x+PHONE_W-56, cy+8, x+PHONE_W-20, cy+26), fill=(*pc, 60), radius=9)
            draw.ellipse((x+PHONE_W-38, cy+10, x+PHONE_W-22, cy+24), fill=pc)
        else:
            rounded_rect(draw, (x+PHONE_W-56, cy+8, x+PHONE_W-20, cy+26), fill=DIVIDER, radius=9)
            draw.ellipse((x+PHONE_W-54, cy+10, x+PHONE_W-40, cy+24), fill=TEXT_HINT)
        cy += 42


# ═══════════════════════════════════════════════
# SCREEN 6: WALLPAPER PREVIEW
# ═══════════════════════════════════════════════
def draw_wallpaper_screen(img, draw, x, y, style="aurora"):
    """Full-screen wallpaper preview."""
    # Dark background
    rounded_rect(draw, (x, y, x+PHONE_W, y+PHONE_H), fill=(10, 10, 26), radius=RADIUS)

    if style == "aurora":
        # Aurora gradient
        for row in range(PHONE_H):
            ratio = row / PHONE_H
            if ratio < 0.3:
                r, g, b = 11, 22, 40
            elif ratio < 0.5:
                t = (ratio - 0.3) / 0.2
                r = int(11 + (50 - 11) * t)
                g = int(22 + (120 - 22) * t)
                b = int(40 + (100 - 40) * t)
            elif ratio < 0.7:
                t = (ratio - 0.5) / 0.2
                r = int(50 + (20 - 50) * t)
                g = int(120 + (80 - 120) * t)
                b = int(100 + (60 - 100) * t)
            else:
                r, g, b = 20, 40, 30
            draw.line((x+2, y+row, x+PHONE_W-2, y+row), fill=(r, g, b))
        # Aurora glow
        for i in range(40):
            alpha = max(0, 60 - i * 2)
            draw.ellipse((x+40, y+120-i, x+PHONE_W-40, y+240-i), fill=(100, 220, 160, alpha))
    elif style == "city":
        for row in range(PHONE_H):
            ratio = row / PHONE_H
            r = int(10 + 30 * ratio)
            g = int(10 + 20 * ratio)
            b = int(26 + 30 * ratio)
            draw.line((x+2, y+row, x+PHONE_W-2, y+row), fill=(r, g, b))
        # City silhouette
        import random
        random.seed(99)
        for bx in range(x+20, x+PHONE_W-20, 12):
            bh = random.randint(40, 120)
            draw.rectangle((bx, y+PHONE_H-200-bh, bx+8, y+PHONE_H-200), fill=(80, 80, 100, 100))
    elif style == "mountain":
        for row in range(PHONE_H):
            ratio = row / PHONE_H
            if ratio < 0.35:
                r, g, b = int(135 - 40*ratio), int(206 - 60*ratio), int(235 - 40*ratio)
            elif ratio < 0.55:
                r, g, b = 160, 150, 130
            else:
                r, g, b = int(60 + 20*ratio), int(90 + 10*ratio), int(60 + 20*ratio)
            draw.line((x+2, y+row, x+PHONE_W-2, y+row), fill=(r, g, b))
        # Mountain
        draw.polygon([(x+40, y+450), (x+PHONE_W//2, y+220), (x+PHONE_W-40, y+450)],
                     fill=(100, 90, 80, 120))
        # Snow cap
        draw.polygon([(x+PHONE_W//2-30, y+260), (x+PHONE_W//2, y+220), (x+PHONE_W//2+30, y+260)],
                     fill=(255, 255, 255, 150))

    # Status bar
    draw.text((x+20, y+10), "9:41", font=F_SMALL_BOLD, fill=WHITE)

    # Text overlay
    quotes = {
        "aurora": ("꿈을 크게 가져라\n그 꿈이 너를 이끌 것이다", "— 괴테"),
        "city": ("미래는 현재 우리가\n무엇을 하느냐에 달려 있다", "— 마하트마 간디"),
        "mountain": ("천리길도\n한 걸음부터", "— 한국 속담"),
    }
    quote_text, author = quotes.get(style, quotes["aurora"])

    draw.text((x+PHONE_W//2 - 10, y+260), "오늘의 명언", font=F_LABEL, fill=(*WHITE, 160), anchor="mt")

    lines = quote_text.split("\n")
    qy = y + 290
    for line in lines:
        ltw = draw.textlength(line, font=F_HEADING)
        draw.text((x + (PHONE_W - ltw) // 2, qy), line, font=F_HEADING, fill=WHITE)
        qy += 28

    atw = draw.textlength(author, font=F_TINY)
    draw.text((x + (PHONE_W - atw) // 2, qy + 4), author, font=F_TINY, fill=(*WHITE, 140))

    # D-Day
    dday = "수능 D-292"
    dtw = draw.textlength(dday, font=F_BIG)
    draw.text((x + (PHONE_W - dtw) // 2, qy + 36), dday, font=F_BIG, fill=WHITE)

    draw.text((x + (PHONE_W - dtw) // 2 + 20, qy + 64), "2026.11.19", font=F_TINY, fill=(*WHITE, 120))

    # Credit
    credits = {
        "aurora": "Photo by Jonatan Pie on Unsplash",
        "city": "Photo by Pawel Nolbert on Unsplash",
        "mountain": "Photo by Samuel Ferrara on Unsplash",
    }
    draw.text((x+PHONE_W-200, y+PHONE_H-20), credits.get(style, ""), font=F_LABEL, fill=(*WHITE, 80))


# ═══════════════════════════════════════════════
# MAIN: Generate all wireframe images
# ═══════════════════════════════════════════════
def main():
    out_dir = "/home/user/Gongsin-App/docs/wireframes"
    os.makedirs(out_dir, exist_ok=True)

    # Image 1: Home (Light + Dark)
    gap = 40
    w = PHONE_W * 2 + gap * 3
    h = PHONE_H + 100
    img = Image.new("RGBA", (w, h), (240, 238, 245, 255))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.text((w//2, 20), "1. 홈 화면 (Home Screen)", font=F_HEADING, fill=PRIMARY_DARK, anchor="mt")
    draw.text((PHONE_W//2 + gap, 50), "Light Mode", font=F_SMALL_BOLD, fill=TEXT_SECONDARY, anchor="mt")
    draw.text((PHONE_W + PHONE_W//2 + gap*2, 50), "Dark Mode", font=F_SMALL_BOLD, fill=TEXT_SECONDARY, anchor="mt")
    draw_home_screen(img, draw, gap, 70, dark=False)
    draw_home_screen(img, draw, PHONE_W + gap*2, 70, dark=True)
    img.save(f"{out_dir}/01_home.png")
    print("✓ 01_home.png")

    # Image 2: Timer (Idle + Running)
    img = Image.new("RGBA", (w, h), (240, 238, 245, 255))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.text((w//2, 20), "2. 집중 타이머 (Timer Screen)", font=F_HEADING, fill=PRIMARY_DARK, anchor="mt")
    draw.text((PHONE_W//2 + gap, 50), "대기 (Idle)", font=F_SMALL_BOLD, fill=TEXT_SECONDARY, anchor="mt")
    draw.text((PHONE_W + PHONE_W//2 + gap*2, 50), "집중 중 (Running)", font=F_SMALL_BOLD, fill=TEXT_SECONDARY, anchor="mt")
    draw_timer_screen(img, draw, gap, 70, running=False)
    draw_timer_screen(img, draw, PHONE_W + gap*2, 70, running=True)
    img.save(f"{out_dir}/02_timer.png")
    print("✓ 02_timer.png")

    # Image 3: Statistics
    img = Image.new("RGBA", (PHONE_W + gap*2, h), (240, 238, 245, 255))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.text(((PHONE_W + gap*2)//2, 20), "3. 통계 대시보드 (Statistics)", font=F_HEADING, fill=PRIMARY_DARK, anchor="mt")
    draw_stats_screen(img, draw, gap, 70)
    img.save(f"{out_dir}/03_statistics.png")
    print("✓ 03_statistics.png")

    # Image 4: Settings
    img = Image.new("RGBA", (PHONE_W + gap*2, h), (240, 238, 245, 255))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.text(((PHONE_W + gap*2)//2, 20), "4. 설정 (Settings)", font=F_HEADING, fill=PRIMARY_DARK, anchor="mt")
    draw_settings_screen(img, draw, gap, 70)
    img.save(f"{out_dir}/04_settings.png")
    print("✓ 04_settings.png")

    # Image 5: Whitelist
    img = Image.new("RGBA", (PHONE_W + gap*2, h), (240, 238, 245, 255))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.text(((PHONE_W + gap*2)//2, 20), "5. 허용 앱 관리 (Whitelist)", font=F_HEADING, fill=PRIMARY_DARK, anchor="mt")
    draw_whitelist_screen(img, draw, gap, 70)
    img.save(f"{out_dir}/05_whitelist.png")
    print("✓ 05_whitelist.png")

    # Image 6: Wallpaper Previews (3 styles)
    w3 = PHONE_W * 3 + gap * 4
    img = Image.new("RGBA", (w3, h), (240, 238, 245, 255))
    draw = ImageDraw.Draw(img, "RGBA")
    draw.text((w3//2, 20), "6. 배경화면 프리뷰 (Wallpaper - Unsplash/Pixabay)", font=F_HEADING, fill=PRIMARY_DARK, anchor="mt")
    labels = ["오로라 / Aurora", "도시 야경 / City", "산 / Mountain"]
    styles = ["aurora", "city", "mountain"]
    for i, (label, style) in enumerate(zip(labels, styles)):
        sx = gap + i * (PHONE_W + gap)
        ltw = draw.textlength(label, font=F_SMALL_BOLD)
        draw.text((sx + (PHONE_W - ltw)//2, 50), label, font=F_SMALL_BOLD, fill=TEXT_SECONDARY)
        draw_wallpaper_screen(img, draw, sx, 70, style=style)
    img.save(f"{out_dir}/06_wallpaper.png")
    print("✓ 06_wallpaper.png")

    print(f"\nAll wireframes saved to {out_dir}/")


if __name__ == "__main__":
    main()
