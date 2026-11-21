# QA Test Plan & Verification Matrix — Masjid Management & Namaz Time

## 1. Scope & Objectives
This test plan validates security, data integrity, and compliance with the functional specifications.
Testing spans:
1. **RBAC Guard Enforcement**: Testing both allowed and strictly forbidden endpoints per role.
2. **Auth & OTP Edge Cases**: Expirations, brute-force attempts, format validation, and console-mode fallbacks.
3. **Sandha Phone Auto-Link**: Ensuring unregistered phone numbers automatically link upon subsequent user registration.
4. **Offline Resilience & Accessibility**: 48dp+ tap targets, WCAG AAA contrast, and cached data rendering.

---

## 2. RBAC Enforcement Matrix (Allowed vs Forbidden Test Cases)

| Endpoint | Method | Super Admin | Masjid Admin | Finance | Announcement | Regular User | Unauthenticated |
|---|---|---|---|---|---|---|---|
| `/v1/auth/otp/send` | POST | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |
| `/v1/auth/otp/verify` | POST | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |
| `/v1/masjids` (search) | GET | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |
| `/v1/masjids/:id/prayer-times/today` | GET | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW | ALLOW |
| `/v1/masjids/:id/prayer-times` | PUT | ALLOW | ALLOW (Owned) | **403 FORBIDDEN** | **403 FORBIDDEN** | **403 FORBIDDEN** | **401 UNAUTH** |
| `/v1/masjids/:id/announcements` | POST | ALLOW | ALLOW (Owned) | **403 FORBIDDEN** | ALLOW (Owned) | **403 FORBIDDEN** | **401 UNAUTH** |
| `/v1/masjids/:id/sandha/payments` | POST | ALLOW | ALLOW (Owned) | ALLOW (Owned) | **403 FORBIDDEN** | **403 FORBIDDEN** | **401 UNAUTH** |
| `/v1/dashboard/super-admin` | GET | ALLOW | **403 FORBIDDEN** | **403 FORBIDDEN** | **403 FORBIDDEN** | **403 FORBIDDEN** | **401 UNAUTH** |
| `/v1/users` (List all users) | GET | ALLOW | **403 FORBIDDEN** | **403 FORBIDDEN** | **403 FORBIDDEN** | **403 FORBIDDEN** | **401 UNAUTH** |

### Automated Test Cases:
- **TEST-SEC-01**: Finance volunteer attempts to PUT `/v1/masjids/:id/prayer-times`.
  - *Expected Result*: HTTP 403 Forbidden (`Requires role: ADMIN`).
- **TEST-SEC-02**: Announcement volunteer attempts to POST `/v1/masjids/:id/sandha/payments`.
  - *Expected Result*: HTTP 403 Forbidden (`Requires role: ADMIN or FINANCE`).
- **TEST-SEC-03**: Masjid Admin of Masjid A attempts to update prayer times for Masjid B.
  - *Expected Result*: HTTP 403 Forbidden (`You do not have administrative access to this masjid`).
- **TEST-SEC-04**: Super Admin updates prayer times for any masjid without explicit admin membership row.
  - *Expected Result*: HTTP 200 OK (Super Admin bypass rule passes).

---

## 3. Auth & OTP Test Cases

| Test ID | Scenario | Input | Expected Outcome |
|---|---|---|---|
| **OTP-01** | Valid Indian Mobile Number | `+919876543210` | 200 OK, OTP logged to dev console |
| **OTP-02** | Invalid Phone Format (missing +) | `9876543210` | 400 Bad Request (E.164 format error) |
| **OTP-03** | Wrong OTP entered | `000000` | 400 Bad Request (`Invalid or expired OTP`) |
| **OTP-04** | Expired OTP (> 5 minutes) | Generated OTP after 301s | 400 Bad Request |
| **OTP-05** | Reuse of already used OTP | Valid OTP used twice | 400 Bad Request (`Invalid or expired OTP`) |
| **OTP-06** | New User Registration | Unregistered phone + valid OTP | Creates User, sets default name, runs Sandha auto-link hook |

---

## 4. Sandha Auto-Linking Test Cases

- **SANDHA-01**: Admin enrolls offline donor (`+919876543299`, Name: "Farooq") before user installs app.
  - *Verification*: `sandha_plan_members.user_id` is NULL, `auto_linked` is false.
- **SANDHA-02**: User with mobile `+919876543299` logs in via OTP.
  - *Verification*: Backend scans `sandha_plan_members`, sets `user_id = new_user.id`, `auto_linked = true`, and links prior payments. User instantly sees historical dues and receipts under `/v1/masjids/:id/sandha/my-status`.

---

## 5. UI Accessibility & Elderly Persona Verification

- **UI-ACC-01**: Touch target size check across all buttons, dropdowns, and cards.
  - *Verification*: Pass ($\ge 48\times 48$ dp).
- **UI-ACC-02**: Contrast check on Next Prayer Hero Card (`#0D5C3A` on `#E8F5E9`).
  - *Verification*: Pass (Contrast ratio $> 7.5:1$, meets WCAG AAA).
- **UI-ACC-03**: Dual-language typography readability.
  - *Verification*: Both Tamil (`ஃபஜ்ர்`, `ஜமாஅத்`) and English (`Fajr`, `Jamaah`) render simultaneously without truncation on 360dp width screens.
