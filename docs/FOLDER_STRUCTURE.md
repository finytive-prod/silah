# Folder Structure — Masjid Management & Namaz Time

## 1. Flutter App (`/app`)

```
app/
├── android/                          # Android platform files
├── ios/                              # iOS platform files
├── lib/
│   ├── main.dart                     # Entry point, ProviderScope, app bootstrap
│   ├── app.dart                      # MaterialApp.router setup, theme, localization
│   │
│   ├── core/                         # Shared infrastructure (not feature-specific)
│   │   ├── auth/
│   │   │   ├── auth_provider.dart          # Riverpod provider for auth state
│   │   │   ├── auth_interceptor.dart       # Dio interceptor for JWT injection
│   │   │   └── secure_storage.dart         # flutter_secure_storage wrapper
│   │   ├── network/
│   │   │   ├── api_client.dart             # Dio instance, base URL, interceptors
│   │   │   ├── api_response.dart           # Generic response envelope model
│   │   │   └── api_exception.dart          # Typed exceptions from error envelope
│   │   ├── cache/
│   │   │   ├── database.dart               # Drift database definition
│   │   │   ├── database.g.dart             # Generated Drift code
│   │   │   └── cache_manager.dart          # TTL logic, stale checks, eviction
│   │   ├── constants/
│   │   │   ├── app_colors.dart             # Material 3 color scheme
│   │   │   ├── app_typography.dart         # Text styles
│   │   │   ├── app_spacing.dart            # 8pt grid spacing constants
│   │   │   └── api_endpoints.dart          # Endpoint path constants
│   │   ├── theme/
│   │   │   └── app_theme.dart              # ThemeData with Material 3
│   │   ├── utils/
│   │   │   ├── date_utils.dart             # Date/time formatting helpers
│   │   │   ├── validators.dart             # Phone, text validation
│   │   │   └── extensions.dart             # Dart extension methods
│   │   └── l10n/
│   │       ├── app_en.arb                  # English translations
│   │       ├── app_ta.arb                  # Tamil translations
│   │       └── l10n.dart                   # Generated localization delegate
│   │
│   ├── routes/
│   │   ├── app_router.dart                 # GoRouter configuration
│   │   ├── route_names.dart                # Named route constants
│   │   └── guards/
│   │       ├── auth_guard.dart             # Redirect unauthenticated users
│   │       └── role_guard.dart             # Admin-only route guard
│   │
│   ├── shared/                       # Reusable UI components
│   │   ├── widgets/
│   │   │   ├── loading_skeleton.dart       # Shimmer loading placeholder
│   │   │   ├── error_widget.dart           # Error state with retry
│   │   │   ├── empty_state.dart            # Empty list placeholder
│   │   │   ├── app_bar.dart                # Custom app bar
│   │   │   ├── bottom_nav.dart             # Bottom navigation bar
│   │   │   ├── prayer_time_card.dart       # Reusable prayer time display
│   │   │   ├── masjid_card.dart            # Masjid list item card
│   │   │   └── confirmation_dialog.dart    # Reusable confirmation modal
│   │   └── layouts/
│   │       ├── scaffold_with_nav.dart      # Main scaffold with bottom nav
│   │       └── auth_layout.dart            # Layout for auth screens
│   │
│   └── features/                     # Feature modules (feature-first)
│       ├── auth/
│       │   ├── data/
│       │   │   ├── auth_repository.dart        # API calls for OTP, login
│       │   │   └── models/
│       │   │       ├── otp_request.dart
│       │   │       ├── otp_response.dart
│       │   │       ├── login_response.dart
│       │   │       └── user_token.dart
│       │   ├── providers/
│       │   │   ├── auth_notifier.dart          # AuthNotifier (AsyncNotifier)
│       │   │   └── otp_timer_provider.dart     # Countdown timer for OTP resend
│       │   └── ui/
│       │       ├── phone_input_screen.dart     # Phone number entry
│       │       ├── otp_verify_screen.dart      # OTP input + verify
│       │       └── widgets/
│       │           ├── phone_field.dart
│       │           └── otp_field.dart
│       │
│       ├── home/
│       │   ├── providers/
│       │   │   └── home_provider.dart          # Home screen data aggregation
│       │   └── ui/
│       │       ├── home_screen.dart            # Main home with prayer times
│       │       └── widgets/
│       │           ├── next_prayer_banner.dart  # Countdown to next prayer
│       │           └── quick_actions.dart       # Quick action cards
│       │
│       ├── prayer_times/
│       │   ├── data/
│       │   │   ├── prayer_times_repository.dart
│       │   │   └── models/
│       │   │       └── prayer_time.dart         # freezed model
│       │   ├── providers/
│       │   │   ├── prayer_times_provider.dart
│       │   │   └── prayer_times_cache.dart      # Drift DAO for caching
│       │   └── ui/
│       │       ├── prayer_times_screen.dart
│       │       ├── prayer_times_edit_screen.dart  # Admin: set times
│       │       └── widgets/
│       │           ├── prayer_row.dart
│       │           └── time_picker_field.dart
│       │
│       ├── masjids/
│       │   ├── data/
│       │   │   ├── masjid_repository.dart
│       │   │   └── models/
│       │   │       └── masjid.dart
│       │   ├── providers/
│       │   │   ├── masjid_list_provider.dart
│       │   │   ├── masjid_detail_provider.dart
│       │   │   └── masjid_search_provider.dart
│       │   └── ui/
│       │       ├── masjid_list_screen.dart
│       │       ├── masjid_detail_screen.dart
│       │       ├── masjid_create_screen.dart     # Admin: register masjid
│       │       ├── masjid_edit_screen.dart        # Admin: edit masjid
│       │       └── widgets/
│       │           ├── masjid_info_card.dart
│       │           └── masjid_map_view.dart
│       │
│       ├── memberships/
│       │   ├── data/
│       │   │   ├── membership_repository.dart
│       │   │   └── models/
│       │   │       └── membership.dart
│       │   ├── providers/
│       │   │   └── membership_provider.dart
│       │   └── ui/
│       │       ├── qr_scan_screen.dart           # QR scanner to join
│       │       ├── qr_display_screen.dart        # Admin: show QR
│       │       └── member_list_screen.dart       # Admin: list members
│       │
│       ├── announcements/
│       │   ├── data/
│       │   │   ├── announcement_repository.dart
│       │   │   └── models/
│       │   │       └── announcement.dart
│       │   ├── providers/
│       │   │   └── announcement_provider.dart
│       │   └── ui/
│       │       ├── announcement_list_screen.dart
│       │       ├── announcement_detail_screen.dart
│       │       ├── announcement_create_screen.dart  # Admin/Announcement role
│       │       └── widgets/
│       │           ├── announcement_card.dart
│       │           └── category_badge.dart
│       │
│       ├── special_schedules/
│       │   ├── data/
│       │   │   ├── schedule_repository.dart
│       │   │   └── models/
│       │   │       └── special_schedule.dart
│       │   ├── providers/
│       │   │   └── schedule_provider.dart
│       │   └── ui/
│       │       ├── schedule_list_screen.dart
│       │       ├── schedule_create_screen.dart
│       │       └── widgets/
│       │           └── schedule_card.dart
│       │
│       ├── sandha/
│       │   ├── data/
│       │   │   ├── sandha_repository.dart
│       │   │   └── models/
│       │   │       ├── sandha_plan.dart
│       │   │       ├── sandha_member.dart
│       │   │       └── sandha_payment.dart
│       │   ├── providers/
│       │   │   ├── sandha_plan_provider.dart
│       │   │   └── sandha_payment_provider.dart
│       │   └── ui/
│       │       ├── sandha_plans_screen.dart        # Admin: list plans
│       │       ├── sandha_plan_detail_screen.dart   # Admin: members + payments
│       │       ├── sandha_record_payment_screen.dart
│       │       ├── sandha_my_dues_screen.dart       # User: view own status
│       │       └── widgets/
│       │           ├── payment_status_chip.dart
│       │           └── member_payment_row.dart
│       │
│       ├── qibla/
│       │   └── ui/
│       │       ├── qibla_screen.dart               # Compass UI
│       │       └── widgets/
│       │           └── compass_widget.dart
│       │
│       ├── notifications/
│       │   ├── data/
│       │   │   ├── notification_repository.dart
│       │   │   └── models/
│       │   │       └── notification_pref.dart
│       │   ├── providers/
│       │   │   └── notification_provider.dart
│       │   └── ui/
│       │       └── notification_prefs_screen.dart
│       │
│       ├── profile/
│       │   ├── data/
│       │   │   └── profile_repository.dart
│       │   ├── providers/
│       │   │   └── profile_provider.dart
│       │   └── ui/
│       │       ├── profile_screen.dart
│       │       └── edit_profile_screen.dart
│       │
│       ├── admin_dashboard/
│       │   ├── providers/
│       │   │   └── dashboard_provider.dart
│       │   └── ui/
│       │       ├── admin_dashboard_screen.dart
│       │       ├── role_management_screen.dart
│       │       └── widgets/
│       │           ├── stat_card.dart
│       │           └── member_chart.dart
│       │
│       └── super_admin/
│           ├── data/
│           │   └── super_admin_repository.dart
│           ├── providers/
│           │   └── super_admin_provider.dart
│           └── ui/
│               ├── super_admin_dashboard.dart
│               ├── all_masjids_screen.dart
│               ├── all_users_screen.dart
│               └── widgets/
│                   ├── analytics_card.dart
│                   └── masjid_overview_row.dart
│
├── test/                             # Unit + widget tests (mirror lib/ structure)
│   ├── core/
│   ├── features/
│   └── shared/
│
├── integration_test/                 # Integration tests
│
├── assets/
│   ├── images/                       # Static images, icons
│   ├── fonts/                        # Custom fonts (Tamil support)
│   └── l10n/                         # Localization assets
│
├── pubspec.yaml
├── analysis_options.yaml
└── l10n.yaml                         # Localization configuration
```

### Reasoning — Flutter Feature-First Structure

1. **Locality**: All files for "prayer times" live in `features/prayer_times/`. A developer working on prayer times never needs to navigate to a distant `models/` or `repositories/` folder.
2. **data / providers / ui split**: Within each feature, we separate API/storage concerns (`data/`), Riverpod state management (`providers/`), and presentation (`ui/`). This keeps each layer testable in isolation.
3. **Shared widgets**: Cross-feature UI components (cards, skeletons, dialogs) live in `shared/widgets/` to avoid duplication.
4. **Core**: Infrastructure code (networking, auth, caching, constants) used by all features lives in `core/`. It has no feature-specific logic.
5. **Routes**: Centralized routing in `routes/` with guards. GoRouter integrates with Riverpod for auth-aware redirects.

---

## 2. NestJS Backend (`/backend`)

```
backend/
├── src/
│   ├── main.ts                       # Bootstrap, global pipes, filters, CORS
│   ├── app.module.ts                 # Root module importing all feature modules
│   │
│   ├── common/                       # Shared utilities, decorators, guards
│   │   ├── guards/
│   │   │   ├── jwt-auth.guard.ts           # JWT validation guard
│   │   │   ├── roles.guard.ts              # RBAC role check guard
│   │   │   └── masjid-scope.guard.ts       # Verify user's role for target masjid
│   │   ├── decorators/
│   │   │   ├── roles.decorator.ts          # @Roles('ADMIN', 'FINANCE')
│   │   │   ├── masjid-scoped.decorator.ts  # @MasjidScoped()
│   │   │   ├── current-user.decorator.ts   # @CurrentUser() param decorator
│   │   │   └── public.decorator.ts         # @Public() skip auth
│   │   ├── filters/
│   │   │   └── global-exception.filter.ts  # Standard error envelope formatter
│   │   ├── interceptors/
│   │   │   ├── response.interceptor.ts     # Wraps responses in success envelope
│   │   │   ├── logging.interceptor.ts      # Request/response logging
│   │   │   └── timeout.interceptor.ts      # Request timeout (30s)
│   │   ├── pipes/
│   │   │   └── validation.pipe.ts          # class-validator integration
│   │   ├── dto/
│   │   │   ├── pagination.dto.ts           # Shared pagination query params
│   │   │   └── paginated-response.dto.ts   # Paginated response shape
│   │   ├── interfaces/
│   │   │   └── request-with-user.ts        # Express Request + user payload
│   │   └── utils/
│   │       ├── bcrypt.util.ts              # (future: if password ever needed)
│   │       └── uuid.util.ts               # UUID generation helpers
│   │
│   ├── config/                       # Configuration
│   │   ├── app.config.ts                   # Env-based app config (port, cors)
│   │   ├── database.config.ts              # Prisma connection config
│   │   ├── jwt.config.ts                   # JWT secret, expiry
│   │   ├── redis.config.ts                 # Redis connection
│   │   ├── otp.config.ts                   # OTP provider, TTL, rate limit
│   │   ├── fcm.config.ts                   # Firebase service account
│   │   └── storage.config.ts              # S3/MinIO config
│   │
│   ├── prisma/                       # Prisma ORM
│   │   ├── prisma.module.ts                # Prisma module for DI
│   │   └── prisma.service.ts               # PrismaClient wrapper (onModuleInit)
│   │
│   ├── modules/                      # Feature modules (domain-driven)
│   │   ├── auth/
│   │   │   ├── auth.module.ts
│   │   │   ├── auth.controller.ts          # POST /auth/request-otp, /auth/verify, etc.
│   │   │   ├── auth.service.ts             # OTP generation, verification, JWT issue
│   │   │   ├── strategies/
│   │   │   │   └── jwt.strategy.ts         # Passport JWT strategy
│   │   │   ├── dto/
│   │   │   │   ├── request-otp.dto.ts
│   │   │   │   ├── verify-otp.dto.ts
│   │   │   │   └── refresh-token.dto.ts
│   │   │   └── auth.service.spec.ts
│   │   │
│   │   ├── otp/
│   │   │   ├── otp.module.ts
│   │   │   ├── otp.service.ts              # OTP store (Redis), rate limiting
│   │   │   ├── providers/
│   │   │   │   ├── otp-provider.interface.ts
│   │   │   │   ├── twilio.provider.ts
│   │   │   │   ├── msg91.provider.ts
│   │   │   │   └── console.provider.ts     # Dev: logs OTP to console
│   │   │   └── otp-provider.factory.ts
│   │   │
│   │   ├── users/
│   │   │   ├── users.module.ts
│   │   │   ├── users.controller.ts
│   │   │   ├── users.service.ts
│   │   │   ├── dto/
│   │   │   │   ├── create-user.dto.ts
│   │   │   │   └── update-user.dto.ts
│   │   │   └── users.service.spec.ts
│   │   │
│   │   ├── masjids/
│   │   │   ├── masjids.module.ts
│   │   │   ├── masjids.controller.ts
│   │   │   ├── masjids.service.ts
│   │   │   ├── dto/
│   │   │   │   ├── create-masjid.dto.ts
│   │   │   │   ├── update-masjid.dto.ts
│   │   │   │   └── search-masjid.dto.ts
│   │   │   └── masjids.service.spec.ts
│   │   │
│   │   ├── memberships/
│   │   │   ├── memberships.module.ts
│   │   │   ├── memberships.controller.ts
│   │   │   ├── memberships.service.ts
│   │   │   ├── dto/
│   │   │   │   ├── join-masjid.dto.ts
│   │   │   │   └── set-primary.dto.ts
│   │   │   └── memberships.service.spec.ts
│   │   │
│   │   ├── prayer-times/
│   │   │   ├── prayer-times.module.ts
│   │   │   ├── prayer-times.controller.ts
│   │   │   ├── prayer-times.service.ts
│   │   │   ├── dto/
│   │   │   │   ├── set-prayer-times.dto.ts
│   │   │   │   └── bulk-set-times.dto.ts
│   │   │   └── prayer-times.service.spec.ts
│   │   │
│   │   ├── special-schedules/
│   │   │   ├── special-schedules.module.ts
│   │   │   ├── special-schedules.controller.ts
│   │   │   ├── special-schedules.service.ts
│   │   │   ├── dto/
│   │   │   │   ├── create-schedule.dto.ts
│   │   │   │   └── update-schedule.dto.ts
│   │   │   └── special-schedules.service.spec.ts
│   │   │
│   │   ├── announcements/
│   │   │   ├── announcements.module.ts
│   │   │   ├── announcements.controller.ts
│   │   │   ├── announcements.service.ts
│   │   │   ├── dto/
│   │   │   │   ├── create-announcement.dto.ts
│   │   │   │   └── update-announcement.dto.ts
│   │   │   └── announcements.service.spec.ts
│   │   │
│   │   ├── sandha/
│   │   │   ├── sandha.module.ts
│   │   │   ├── sandha.controller.ts          # Plans + payments endpoints
│   │   │   ├── sandha.service.ts
│   │   │   ├── sandha-autolink.service.ts    # Auto-link logic
│   │   │   ├── dto/
│   │   │   │   ├── create-plan.dto.ts
│   │   │   │   ├── add-member.dto.ts
│   │   │   │   ├── record-payment.dto.ts
│   │   │   │   └── payment-filter.dto.ts
│   │   │   └── sandha.service.spec.ts
│   │   │
│   │   ├── devices/
│   │   │   ├── devices.module.ts
│   │   │   ├── devices.controller.ts
│   │   │   ├── devices.service.ts
│   │   │   └── dto/
│   │   │       └── register-device.dto.ts
│   │   │
│   │   ├── notifications/
│   │   │   ├── notifications.module.ts
│   │   │   ├── notifications.service.ts       # FCM topic management, send
│   │   │   ├── notification-prefs.controller.ts
│   │   │   ├── notification-prefs.service.ts
│   │   │   └── dto/
│   │   │       └── update-prefs.dto.ts
│   │   │
│   │   ├── admin-dashboard/
│   │   │   ├── admin-dashboard.module.ts
│   │   │   ├── admin-dashboard.controller.ts
│   │   │   └── admin-dashboard.service.ts
│   │   │
│   │   └── super-admin/
│   │       ├── super-admin.module.ts
│   │       ├── super-admin.controller.ts
│   │       └── super-admin.service.ts
│   │
│   └── jobs/                         # Background job processors
│       ├── jobs.module.ts
│       ├── notification.processor.ts       # BullMQ: dispatch FCM messages
│       ├── sandha-reminder.processor.ts    # BullMQ: sandha due reminders
│       └── otp-cleanup.processor.ts        # BullMQ: expired OTP cleanup
│
├── prisma/
│   ├── schema.prisma                 # Prisma schema (single source of truth)
│   ├── migrations/                   # Auto-generated migration SQL files
│   │   └── 20240101000000_init/
│   │       └── migration.sql
│   └── seed.ts                       # Seed script (uses data from DATABASE_SCHEMA.md)
│
├── test/
│   ├── app.e2e-spec.ts               # End-to-end tests
│   ├── auth.e2e-spec.ts
│   └── jest-e2e.json
│
├── .env.example                      # Environment variable template
├── .env                              # Local env (gitignored)
├── nest-cli.json
├── tsconfig.json
├── tsconfig.build.json
├── package.json
└── Dockerfile
```

### Reasoning — NestJS Module-Based Structure

1. **NestJS modules = domain boundaries**: Each `*.module.ts` declares its controllers, services, and imports. This enforces explicit dependency declarations — the `sandha` module must import `users` module to use `UsersService`.
2. **Guards and decorators in `common/`**: RBAC logic (`RolesGuard`, `MasjidScopeGuard`) is shared across all modules. Keeping them in `common/` avoids circular dependencies.
3. **DTOs per module**: Each module defines its own request/response DTOs with `class-validator` decorators. This keeps validation rules close to the endpoints that use them.
4. **Prisma as a shared module**: `PrismaService` is a singleton injected via NestJS DI. All modules import `PrismaModule` to access the database.
5. **Jobs as separate module**: Background processors (BullMQ) are isolated from HTTP controllers. They share services but run in a worker process.
6. **Config separated**: Environment-specific configuration is centralized in `config/`, making it easy to see all external dependencies.
7. **OTP providers isolated**: The `otp/` module contains the provider interface, concrete implementations, and factory. Swapping providers means adding a new file and updating the factory — zero changes to `auth.service.ts`.

---

## 3. Root Project Structure

```
masjid/
├── app/                              # Flutter mobile app
├── backend/                          # NestJS REST API
├── docs/                             # Architecture documents (this folder)
│   ├── ARCHITECTURE.md
│   ├── DATABASE_SCHEMA.md
│   ├── API_CONTRACT.md
│   ├── RBAC_MATRIX.md
│   ├── FOLDER_STRUCTURE.md
│   └── DECISIONS.md
├── .github/
│   └── workflows/
│       ├── backend-ci.yml            # Lint, test, build backend
│       └── app-ci.yml                # Lint, test, build Flutter
├── docker-compose.yml                # PostgreSQL + Redis + MinIO for local dev
├── .gitignore
└── README.md
```
