# Architectural Decision Log — Masjid Management & Namaz Time

## ADR-001: OTP Provider Abstraction

| Field | Detail |
|-------|--------|
| **Decision** | Use an interface-based OTP provider abstraction with Twilio as default; provider selectable via `OTP_PROVIDER` environment variable. |
| **Rationale** | Indian masjid communities may prefer local providers (MSG91, Kaleyra) for cost (₹0.10–0.20 per SMS vs Twilio's ₹0.50+). Abstraction allows swap without code changes. Dev/test mode uses `ConsoleOtpProvider` that logs OTPs to stdout. |
| **Alternatives considered** | **(a)** Hardcode Twilio — rejected: vendor lock-in, expensive for Indian market. **(b)** Firebase Phone Auth — rejected: adds Firebase dependency for auth, less control over OTP flow, rate limit behavior opaque. **(c)** AWS SNS — rejected: overkill, requires AWS account. |

## ADR-002: Local Caching Library

| Field | Detail |
|-------|--------|
| **Decision** | Use **Drift** (formerly Moor) for structured offline caching in Flutter, with **flutter_secure_storage** for auth tokens. |
| **Rationale** | Drift provides type-safe SQLite access with reactive streams that integrate cleanly with Riverpod. Prayer times, masjid data, and announcements have relational structure that benefits from SQL queries (e.g., "get prayer times for masjid X on date Y"). Hive was considered but lacks relational query support. |
| **Alternatives considered** | **(a)** Hive — rejected: key-value store, no relational queries, migration story is weak. **(b)** sqflite directly — rejected: no type safety, boilerplate. **(c)** Isar — rejected: less mature, uncertain maintenance. **(d)** SharedPreferences — rejected: only for simple key-value, not structured data. |

## ADR-003: State Management

| Field | Detail |
|-------|--------|
| **Decision** | Use **Riverpod 2.x** with code generation (`riverpod_generator`). |
| **Rationale** | Riverpod is compile-safe (errors at build time, not runtime), supports `AsyncNotifier` for API-driven state, and has first-class dependency injection. Auth state → membership state → prayer times dependency chain is naturally modeled. Code-gen reduces boilerplate. |
| **Alternatives considered** | **(a)** Provider — rejected: Riverpod is its spiritual successor by the same author; Provider has ChangeNotifier anti-patterns and no compile-time safety. **(b)** Bloc/Cubit — rejected: more boilerplate (events, states, blocs), steeper learning curve for the team, overkill for screens that are mostly read-only. **(c)** GetX — rejected: magic, untestable, anti-pattern-prone. |

## ADR-004: QR Code Format & Token Strategy

| Field | Detail |
|-------|--------|
| **Decision** | QR code encodes a URL: `https://masjidapp.com/join/{qr_token}`. Token is a 32-character random string stored on `masjids.qr_token`. Tokens are **permanent by default** (NULL `qr_token_expires_at`), with optional rotation by admin. |
| **Rationale** | Permanent tokens suit community masjids where the QR is printed on a poster and rarely changed. The URL format enables deep-linking: if the app is installed, it opens directly; if not, it opens a web page with app store links. The token is not a JWT or encoded data — it's an opaque lookup key, so no cryptographic overhead and no sensitive data embedded. |
| **Alternatives considered** | **(a)** Short-lived JWT in QR — rejected: QR printed on posters would expire, forcing constant reprinting. **(b)** Masjid ID directly in QR — rejected: exposes internal IDs, no revocation mechanism. **(c)** Invite codes (6-digit) — rejected: easy to guess/brute-force; QR scan is simpler for 60-year-old users than typing codes. |

## ADR-005: Prayer Time Source — Admin-Entered vs Calculated

| Field | Detail |
|-------|--------|
| **Decision** | Prayer times are **admin-entered**, not calculated from astronomical algorithms. |
| **Rationale** | Each masjid sets its own jamaah (congregation) times, which differ from calculated adhan times. Masjid Al-Huda may have Fajr jamaah at 5:30 while Masjid An-Noor across the street has it at 5:45. No calculation library can know this. The admin simply enters the times their masjid follows. Super Admin can set region-wide defaults that masjids can adopt or override. |
| **Alternatives considered** | **(a)** Calculate via Adhan library (like Muslim Pro) — rejected: gives standard adhan times, not jamaah times specific to each masjid. **(b)** Hybrid (calculate + admin override) — rejected: adds complexity for no benefit; admins always want to enter their exact times. If we show calculated times as a "suggestion," admins will ignore them. |

## ADR-006: Sandha Auto-Link Mechanism

| Field | Detail |
|-------|--------|
| **Decision** | Auto-link by phone number. When admin adds a member to a sandha plan by phone, the system checks for a matching registered user. On new user registration, the system scans for unlinked sandha records matching the phone. Implemented as an application-level hook (NestJS event), not a database trigger. |
| **Rationale** | Phone number is the natural unique identifier in this community (everyone has one, same number used for registration). Application-level logic is more testable and debuggable than a Postgres trigger, and can emit events (e.g., notify the user "You've been added to a sandha plan"). |
| **Alternatives considered** | **(a)** DB trigger — rejected: harder to test, can't emit application events, Prisma doesn't natively support triggers. **(b)** Manual link by admin — rejected: extra step, error-prone, bad UX for a 60-year-old admin. **(c)** Link by name matching — rejected: names are ambiguous, unreliable. **(d)** QR-based link — rejected: requires the person to be present; sandha admin often enrolls people from a register book. |

## ADR-007: Notification Grouping Strategy

| Field | Detail |
|-------|--------|
| **Decision** | Use FCM **topics** for broadcast notifications (one topic per masjid per category). Individual/targeted notifications use device tokens directly. |
| **Rationale** | Topics are ideal for masjid broadcasts — subscribe on join, unsubscribe on leave. No need to maintain and fan-out to individual tokens. FCM handles the fan-out server-side. For targeted notifications (sandha reminders to specific users), we use device tokens via BullMQ worker jobs. This separates broadcast (simple) from targeted (requires business logic). |
| **Alternatives considered** | **(a)** Device token only (no topics) — rejected: requires maintaining token lists per masjid, manual fan-out to potentially thousands of tokens. **(b)** FCM device groups — rejected: deprecated/limited, topics are the recommended approach. **(c)** OneSignal — rejected: adds another vendor dependency; FCM is free and sufficient. |

## ADR-008: Backend Job Queue

| Field | Detail |
|-------|--------|
| **Decision** | Use **BullMQ** with Redis for background jobs (notification dispatch, sandha reminders, OTP cleanup). |
| **Rationale** | BullMQ is Redis-backed, battle-tested in Node.js, supports delayed jobs (prayer reminders), repeatable jobs (sandha due dates), and has a dashboard (Bull Board) for monitoring. Runs as a separate worker process for reliability — API server crashes don't lose queued jobs. |
| **Alternatives considered** | **(a)** Agenda (MongoDB-based) — rejected: adds MongoDB dependency. **(b)** pg-boss (Postgres-based) — rejected: viable but Postgres is already the main DB; adding queue load to it risks contention. Redis is purpose-built for this. **(c)** AWS SQS / GCP Cloud Tasks — rejected: vendor lock-in, overkill for v1. **(d)** In-process `setTimeout`/`setInterval` — rejected: lost on restart, no persistence, no retry. |

## ADR-009: API Versioning

| Field | Detail |
|-------|--------|
| **Decision** | URI prefix versioning: `/api/v1/...`. |
| **Rationale** | Simplest approach. URIs are visible in logs, Postman collections, documentation, and debugging. No special headers needed. NestJS supports this natively with `@Controller('v1/resource')`. |
| **Alternatives considered** | **(a)** Header versioning (`Accept: application/vnd.masjid.v1+json`) — rejected: harder to debug, invisible in browser/curl. **(b)** Query param (`?version=1`) — rejected: messy, caching issues. **(c)** No versioning — rejected: irresponsible for a production API. |

## ADR-010: Database ORM

| Field | Detail |
|-------|--------|
| **Decision** | Use **Prisma 5.x** as the ORM for PostgreSQL. |
| **Rationale** | Prisma's declarative schema (`schema.prisma`) generates type-safe TypeScript client, handles migrations declaratively, and provides excellent DX. Introspection tooling helps onboard new developers. Prisma Migrate produces reviewable SQL migration files. |
| **Alternatives considered** | **(a)** TypeORM — rejected: decorator-heavy, inconsistent migration behavior, many open issues. **(b)** Knex.js — rejected: query builder only, no type safety from schema. **(c)** Drizzle — rejected: newer, less ecosystem support, Prisma is more battle-tested. **(d)** Raw SQL — rejected: no type safety, error-prone. |

## ADR-011: Localization Strategy

| Field | Detail |
|-------|--------|
| **Decision** | Flutter ARB files for app UI (Tamil + English). Database stores bilingual fields (`name` / `name_ta`, `title` / `title_ta`). API returns both; client displays based on `language` preference. |
| **Rationale** | ARB is Flutter's built-in i18n format with tooling support. Bilingual DB columns avoid a full i18n table (EAV anti-pattern) for just 2 languages. If a third language is needed later, we can migrate to a translations table, but for Tamil + English, paired columns are simpler and faster to query. |
| **Alternatives considered** | **(a)** Separate translations table — rejected: overkill for 2 languages, adds JOINs to every query. **(b)** JSON column for translations — rejected: loses type safety, can't index. **(c)** Client-side translation of server content — rejected: impossible for user-generated content like announcement text. |

## ADR-012: Authentication Token Strategy

| Field | Detail |
|-------|--------|
| **Decision** | JWT access token (15-minute expiry) + opaque refresh token (30-day expiry, stored in DB). Access token in `Authorization: Bearer` header. Refresh token in HTTP-only response body (mobile app stores in secure storage). |
| **Rationale** | Short-lived access tokens limit damage if leaked. Refresh tokens stored server-side allow revocation (logout, suspicious activity). Mobile apps don't have HTTP-only cookies, so refresh token is returned in response body and stored in `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences on Android). |
| **Alternatives considered** | **(a)** Session-based auth — rejected: doesn't scale well for stateless APIs, requires sticky sessions. **(b)** Long-lived access token only — rejected: can't revoke without DB lookup on every request, defeating JWT benefits. **(c)** Firebase Auth tokens — rejected: couples auth to Firebase, less control. |

## ADR-013: Image/File Storage

| Field | Detail |
|-------|--------|
| **Decision** | Use S3-compatible object storage (AWS S3 in production, MinIO for local dev). Backend generates pre-signed upload URLs; client uploads directly to storage. |
| **Rationale** | Direct-to-storage upload avoids sending large files through the API server. Pre-signed URLs are time-limited and scoped. MinIO provides local dev parity without an AWS account. |
| **Alternatives considered** | **(a)** Upload through API server — rejected: wastes API bandwidth, adds latency. **(b)** Firebase Storage — rejected: adds Firebase dependency beyond just FCM. **(c)** Cloudinary — rejected: overkill for simple image storage, adds cost. |

## ADR-014: Time Storage & Display

| Field | Detail |
|-------|--------|
| **Decision** | Prayer times stored as TIME (local masjid time). System timestamps (created_at, etc.) stored as TIMESTAMPTZ (UTC). Client displays prayer times as-is; system timestamps converted to local timezone on display. |
| **Rationale** | Prayer times are inherently local — "Fajr at 5:30" means 5:30 at the masjid. Converting to/from UTC adds complexity and daylight-saving bugs with no benefit (India doesn't have DST, but the architecture should be sound). System timestamps use UTC for consistency across server/client. |
| **Alternatives considered** | **(a)** All times as TIMESTAMPTZ — rejected: requires knowing the masjid's timezone to store prayer times, unnecessary roundtrip conversion. **(b)** All times as strings — rejected: no DB-level validation or comparison. |

## ADR-015: Folder Architecture

| Field | Detail |
|-------|--------|
| **Decision** | Feature-first folder structure for Flutter app; module-based (domain-driven) structure for NestJS backend. |
| **Rationale** | Feature-first groups all related files (UI, state, models) by feature, reducing navigation. Aligns with how developers think ("I'm working on prayer times"). NestJS modules naturally enforce domain boundaries and dependency injection scoping. |
| **Alternatives considered** | **(a)** Layer-first (views/, controllers/, models/) — rejected: scatters related files across deep trees; a change to "prayer times" touches 5 different directories. **(b)** Monorepo with shared models — rejected: premature; Flutter and NestJS have different model serialization needs (freezed vs class-validator). |
