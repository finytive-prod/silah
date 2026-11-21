# UI/UX Design Specification — Masjid Management & Namaz Time

## 1. Core Design Philosophy: The 3-Tap Elderly Rule

The primary audience includes elderly users (60+ years old) in Tamil Nadu and global Muslim communities who may have limited tech literacy, tremors, or presbyopia (far-sightedness).

### Three Immutable Principles
1. **The 3-Tap Rule**: Any core task (view today's jamaah times, find Qibla direction, check Sandha status, or read an urgent announcement) must be reachable in 3 taps or fewer from cold launch with zero instructions.
2. **Visual Hierarchy & High Contrast**: Minimum 48×48 dp tap targets, 18sp+ for primary readable times, WCAG AAA contrast ratio (7:1) for all critical prayer times and buttons.
3. **Bilingual Simplicity (Tamil & English)**: Every key label has clear Tamil and English text. No technical jargon (e.g., instead of "Authentication Failed", use "OTP தவறானது / Incorrect OTP").

---

## 2. Design System Tokens

### 2.1 Color Palette (Material 3 Light Theme)

| Token | Hex | Role & Usage |
|-------|-----|--------------|
| `primary` | `#0D5C3A` | Deep Islamic Emerald Green (Header, Jamaah highlights, primary buttons) |
| `onPrimary` | `#FFFFFF` | Text/icons on primary green |
| `primaryContainer` | `#E8F5E9` | Light mint tint for next upcoming prayer highlight card |
| `onPrimaryContainer` | `#0A3D27` | High contrast text on mint container |
| `secondary` | `#D4AF37` | Warm Gold / Brass (Qibla compass needle, Sandha badge, accents) |
| `onSecondary` | `#000000` | Text/icons on gold accent |
| `surface` | `#FAFAFA` | Off-white clean background (reduces eye glare compared to #FFF) |
| `surfaceCard` | `#FFFFFF` | Elevated prayer card surface |
| `textPrimary` | `#1A1C1E` | High readability dark slate for times and headlines |
| `textSecondary` | `#596066` | Secondary labels (e.g., Adhan vs Jamaah) |
| `alertEmergency` | `#BA1A1A` | Emergency announcements / critical alerts |
| `successGreen` | `#2E7D32` | Sandha paid status |
| `warningAmber` | `#ED6C02` | Sandha pending reminder |

### 2.2 Typography Scale

- **Display Time**: `32sp`, Bold, tabular numbers (Monospace digits) — `01:15 PM`
- **Next Prayer Banner**: `22sp`, SemiBold — `அடுத்த தொழுகை / Next: Asr in 42 mins`
- **Prayer Name (Tamil / English)**: `18sp`, Bold — `அஸர் / Asr`
- **Body / Content**: `16sp`, Regular, line-height 1.5 — Easy reading for notices
- **Caption / Secondary**: `14sp`, Medium — Adhan time `12:45 PM`
- **Button Text**: `18sp`, SemiBold — 48dp touch height minimum

### 2.3 Spacing & Tap Targets (8pt Grid)
- Touch targets: **Minimum 48×48 dp** everywhere. Recommended 56dp for primary action buttons.
- Grid: 8dp, 16dp (standard screen padding), 24dp (section spacing), 32dp (header clearance).
- Elevation: Level 1 (2dp) for prayer cards, Level 2 (4dp) for current active prayer card.

---

## 3. User Flows & Screen Specifications

### 3.1 Flow A: 60-Year-Old Regular User (Prayer Times & Qibla)
1. **Cold Launch App** -> Immediate Home Screen (cached prayer times display instantly in < 200ms).
   - If not registered: defaults to nearest or pre-set community masjid. A clean non-intrusive prompt at top allows OTP login in 2 taps.
2. **Current & Next Prayer Highlight**:
   - The upcoming prayer (e.g., Asr) is highlighted with an emerald container, showing countdown: `"அஸர் தொழுகை இன்னும் 35 நிமிடங்களில் / Asr Jamaah in 35 mins"`.
3. **Switching Masjid**:
   - Single tap on the Masjid Name dropdown at the top header opens a bottom sheet with user's joined masjids + "Nearby Masjids".
4. **Qibla Tab**:
   - Single tap on bottom nav "Qibla (கிப்லா)". Shows full-screen gold compass with haptic feedback vibration when pointing directly at the Kaaba.

### 3.2 Flow B: Masjid Admin (Updating Prayer Times)
1. Log in via OTP -> Admin switch badge appears in top header.
2. Tap "நிர்வாகம் / Admin" -> Direct to Admin Dashboard.
3. Tap "தொழுகை நேரம் / Prayer Times" -> Pre-filled with today's times.
4. Tap time picker on any changed prayer -> Tap "சேமி / Save" (Single primary button).
5. Automatic prompt: "Send update notification to 850 members? [Yes / No]".

### 3.3 Flow C: Finance Volunteer (Recording Sandha Payment)
1. Tap "சந்தா / Sandha" tab in Admin portal.
2. Member Search: Enter phone or name (or scan member QR).
3. Tap "பணம் பெற்றது / Record Payment":
   - Pre-fills current month amount (e.g., ₹200).
   - Select Cash or UPI.
   - Tap "உறுதி செய் / Confirm".
4. Backend auto-links to user's registered phone, updates status to PAID, and sends notification to member.

### 3.4 Flow D: Super Admin (Creating Masjid & Admin)
1. Super Admin Dashboard: Overview of total masjids, followers, Sandha collections.
2. Tap "+ புதிய பள்ளிவாசல் / + Add Masjid".
3. Form: Name (EN + TA), City, Address, Admin Mobile Number.
4. On save: Generates unique 32-char QR token + invites Admin via SMS OTP.

---

## 4. Screen Wireframes (Layout Spec)

### Screen 1: OTP Login (`/login`)
- **Header**: Crescent & Minaret clean vector illustration.
- **Title**: "வணக்கம் / Welcome" (24sp Bold)
- **Subtitle**: "உங்கள் மொபைல் எண்ணை உள்ளிடவும் / Enter your mobile number"
- **Input**: Large `+91` pre-selected prefix with 10-digit number field (56dp height, 20sp text).
- **Primary CTA**: "OTP அனுப்புக / Get OTP" (Full-width 54dp button).
- **OTP Screen**: 6 distinct numeric boxes with auto-focus, numeric keypad, 60s countdown resend button.

### Screen 2: Home Screen (`/home`)
- **Top App Bar**:
  - Masjid Dropdown Selector: `ஜாமியா மஸ்ஜித் (Jamia Masjid) ▼` (Tap to switch)
  - Right Icon: Notification bell with unread badge count.
- **Top Notification Banner (if any pinned announcement)**:
  - Gold or Red highlight: `ஜனாஸா அறிவிப்பு: இன்று மாலை 4:30 மணிக்கு...`
- **Hero Card (Next Prayer)**:
  - High-contrast mint background `#E8F5E9` with deep green border.
  - Large Arabic Calligraphy + Tamil & English name: `العصر • அஸர் (Asr)`
  - Big Jamaah Time: `04:45 PM`
  - Countdown Chip: `⏳ இன்னும் 25 நிமிடங்கள் (in 25 mins)`
- **Full Prayer Schedule List (Cards)**:
  - 5 Prayers + Jummah (on Fridays) + Sunrise/Imsak/Iftar (during Ramadan).
  - Columns: Prayer Name | பாங்கு (Adhan) | ஜமாஅத் (Jamaah) | Alarm Icon.
  - Active prayer row is highlighted.
- **Bottom Navigation (48dp+ icons with persistent labels)**:
  - 1. தொழுகை (Namaz)
  - 2. கிப்லா (Qibla)
  - 3. குர்ஆன் (Quran)
  - 4. சந்தா (Sandha)
  - 5. தகவல் (Notices)

### Screen 3: Qibla Direction (`/qibla`)
- **Compass View**:
  - Large circular analog compass with Kaaba icon at the target bearing.
  - Visual accuracy indicator: "சுழற்றி அளவீடு செய்யவும் / Calibrate sensor" if accuracy is low.
  - Degree readout: `294° WNW (Mecca, 4,320 km)`.
  - Haptic feedback when the phone points within ±2° of Qibla.

### Screen 4: Sandha Status & History (`/sandha`)
- **Card**:
  - Plan: "மாதாந்திர சந்தா / Monthly Sandha (₹200 / Month)"
  - Status Badge: `செலுத்தப்பட்டது / PAID` (Green) or `நிலுவை / PENDING` (Amber).
  - Current year tracker: 12 pill indicators (Jan to Dec) with checkmarks.
  - Download / View digital receipt.

### Screen 5: Bilingual String Dictionary (Sample)

| Key | English | Tamil |
|-----|---------|-------|
| `app_title` | Masjid Namaz | பள்ளிவாசல் தொழுகை |
| `fajr` | Fajr | ஃபஜ்ர் |
| `dhuhr` | Dhuhr | ளுஹர் |
| `asr` | Asr | அஸர் |
| `maghrib` | Maghrib | மஃரிப் |
| `isha` | Isha | இஷா |
| `jummah` | Jummah | ஜும்ஆ |
| `adhan` | Adhan | பாங்கு |
| `jamaah` | Jamaah | ஜமாஅத் |
| `next_prayer` | Next Prayer | அடுத்த தொழுகை |
| `sandha_paid` | Paid | செலுத்தப்பட்டது |
| `sandha_pending` | Pending | நிலுவையில் உள்ளது |
| `join_masjid` | Join Masjid | பள்ளிவாசலில் இணைக |
| `scan_qr` | Scan QR Code | QR குறியீட்டை ஸ்கேன் செய்க |

---

## 5. UI States (Empty, Loading, Error)

1. **Loading State**:
   - Flutter Shimmer effect matching the exact layout of the 5 prayer cards. No jarring spinners.
2. **Offline State**:
   - Non-blocking top snackbar: `"ஆஃப்லைன் பயன்முறை (முந்தைய தகவல் காட்டப்படுகிறது) / Offline Mode (Showing cached times)"`.
3. **Empty State**:
   - Clean illustration of a minaret with encouraging text: `"இன்னும் பள்ளிவாசலில் இணையவில்லை. அருகிலுள்ள பள்ளிவாசலைத் தேர்ந்தெடுக்கவும் / Not joined any masjid yet. Select a nearby masjid."` + Big Button `[ பள்ளிவாசலைத் தேடுக / Find Masjid ]`.
4. **Error State**:
   - Soft banner with retry button: `"இணைக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும் / Connection error. Tap to Retry"`.
