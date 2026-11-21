# RBAC Permission Matrix — Masjid Management & Namaz Time

## Legend

| Symbol | Meaning |
|--------|---------|
| ✅ | Allowed (unrestricted) |
| ❌ | Denied |
| 🔒 | Own masjid only (masjid where user holds this role) |
| 👤 | Own data only (user's own records) |

## Roles

| Role | Scope | Description |
|------|-------|-------------|
| **Super Admin** | Global | Full system access across all masjids |
| **Admin** | Per-masjid | Manages one or more specific masjids |
| **Finance** | Per-masjid | Sandha/payment management for one masjid |
| **Announcement** | Per-masjid | Posts announcements for one masjid |
| **User** | Self + joined masjids | Registered user, may or may not have joined a masjid |
| **Guest** | Public read-only | Unauthenticated visitor (no JWT) |

---

## 1. Auth Module

| Action | Super Admin | Admin | Finance | Announcement | User | Guest |
|--------|:-----------:|:-----:|:-------:|:------------:|:----:|:-----:|
| Request OTP | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Verify OTP & Login | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Refresh token | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Logout | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |

## 2. Users Module

| Action | Super Admin | Admin | Finance | Announcement | User | Guest |
|--------|:-----------:|:-----:|:-------:|:------------:|:----:|:-----:|
| Get own profile | ✅ | ✅ | ✅ | ✅ | 👤 | ❌ |
| Update own profile | ✅ | ✅ | ✅ | ✅ | 👤 | ❌ |
| Delete own account | ✅ | ✅ | ✅ | ✅ | 👤 | ❌ |
| List all users | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Get any user profile | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Create user | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Deactivate any user | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

## 3. Masjids Module

| Action | Super Admin | Admin | Finance | Announcement | User | Guest |
|--------|:-----------:|:-----:|:-------:|:------------:|:----:|:-----:|
| List/search masjids | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Get masjid details | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Create masjid | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ |
| Update masjid details | ✅ | 🔒 | ❌ | ❌ | ❌ | ❌ |
| Delete masjid | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Regenerate QR token | ✅ | 🔒 | ❌ | ❌ | ❌ | ❌ |
| Upload masjid photo | ✅ | 🔒 | ❌ | ❌ | ❌ | ❌ |

## 4. Memberships Module

| Action | Super Admin | Admin | Finance | Announcement | User | Guest |
|--------|:-----------:|:-----:|:-------:|:------------:|:----:|:-----:|
| Join masjid (QR scan) | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Join masjid (search) | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Leave masjid | ✅ | ✅ | ✅ | ✅ | 👤 | ❌ |
| List own memberships | ✅ | ✅ | ✅ | ✅ | 👤 | ❌ |
| List masjid members | ✅ | 🔒 | 🔒 | ❌ | ❌ | ❌ |
| Remove member from masjid | ✅ | 🔒 | ❌ | ❌ | ❌ | ❌ |
| Set primary masjid | ✅ | ✅ | ✅ | ✅ | 👤 | ❌ |

## 5. Prayer Times Module

| Action | Super Admin | Admin | Finance | Announcement | User | Guest |
|--------|:-----------:|:-----:|:-------:|:------------:|:----:|:-----:|
| View prayer times | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Set/update prayer times | ✅ | 🔒 | ❌ | ❌ | ❌ | ❌ |
| Set region-wide default times | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Bulk set prayer times (week) | ✅ | 🔒 | ❌ | ❌ | ❌ | ❌ |

## 6. Special Schedules Module

| Action | Super Admin | Admin | Finance | Announcement | User | Guest |
|--------|:-----------:|:-----:|:-------:|:------------:|:----:|:-----:|
| View special schedules | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Create special schedule | ✅ | 🔒 | ❌ | ❌ | ❌ | ❌ |
| Update special schedule | ✅ | 🔒 | ❌ | ❌ | ❌ | ❌ |
| Delete special schedule | ✅ | 🔒 | ❌ | ❌ | ❌ | ❌ |

## 7. Announcements Module

| Action | Super Admin | Admin | Finance | Announcement | User | Guest |
|--------|:-----------:|:-----:|:-------:|:------------:|:----:|:-----:|
| View announcements (masjid) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Create announcement | ✅ | 🔒 | ❌ | 🔒 | ❌ | ❌ |
| Update announcement | ✅ | 🔒 | ❌ | 🔒 | ❌ | ❌ |
| Delete announcement | ✅ | 🔒 | ❌ | ❌ | ❌ | ❌ |
| Pin/unpin announcement | ✅ | 🔒 | ❌ | ❌ | ❌ | ❌ |
| Send global announcement | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

## 8. Sandha (Dues) Module

| Action | Super Admin | Admin | Finance | Announcement | User | Guest |
|--------|:-----------:|:-----:|:-------:|:------------:|:----:|:-----:|
| View own sandha status | ✅ | ✅ | ✅ | ✅ | 👤 | ❌ |
| Create sandha plan | ✅ | 🔒 | 🔒 | ❌ | ❌ | ❌ |
| Update sandha plan | ✅ | 🔒 | 🔒 | ❌ | ❌ | ❌ |
| Delete sandha plan | ✅ | 🔒 | ❌ | ❌ | ❌ | ❌ |
| Add member to plan | ✅ | 🔒 | 🔒 | ❌ | ❌ | ❌ |
| Remove member from plan | ✅ | 🔒 | 🔒 | ❌ | ❌ | ❌ |
| Record payment | ✅ | 🔒 | 🔒 | ❌ | ❌ | ❌ |
| View all payments (masjid) | ✅ | 🔒 | 🔒 | ❌ | ❌ | ❌ |
| View payment reports | ✅ | 🔒 | 🔒 | ❌ | ❌ | ❌ |
| Export payment data | ✅ | 🔒 | 🔒 | ❌ | ❌ | ❌ |

## 9. Devices & Notifications Module

| Action | Super Admin | Admin | Finance | Announcement | User | Guest |
|--------|:-----------:|:-----:|:-------:|:------------:|:----:|:-----:|
| Register device | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| Update device token | ✅ | ✅ | ✅ | ✅ | 👤 | ❌ |
| Get notification prefs | ✅ | ✅ | ✅ | ✅ | 👤 | ❌ |
| Update notification prefs | ✅ | ✅ | ✅ | ✅ | 👤 | ❌ |
| Send push to masjid | ✅ | 🔒 | ❌ | 🔒 | ❌ | ❌ |
| Send global push | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

## 10. Admin Dashboard

| Action | Super Admin | Admin | Finance | Announcement | User | Guest |
|--------|:-----------:|:-----:|:-------:|:------------:|:----:|:-----:|
| View masjid dashboard | ✅ | 🔒 | ❌ | ❌ | ❌ | ❌ |
| View masjid member count | ✅ | 🔒 | ❌ | ❌ | ❌ | ❌ |
| View sandha collection summary | ✅ | 🔒 | 🔒 | ❌ | ❌ | ❌ |
| Assign custom role | ✅ | 🔒 | ❌ | ❌ | ❌ | ❌ |
| Revoke custom role | ✅ | 🔒 | ❌ | ❌ | ❌ | ❌ |
| View admin activity log | ✅ | 🔒 | ❌ | ❌ | ❌ | ❌ |

## 11. Super Admin Dashboard

| Action | Super Admin | Admin | Finance | Announcement | User | Guest |
|--------|:-----------:|:-----:|:-------:|:------------:|:----:|:-----:|
| View all masjids | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| View all users | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| View platform analytics | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Create admin for masjid | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Delete masjid | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| Set region-wide prayer defaults | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| View all sandha payers | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| View follower analytics | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

## 12. Qibla

| Action | Super Admin | Admin | Finance | Announcement | User | Guest |
|--------|:-----------:|:-----:|:-------:|:------------:|:----:|:-----:|
| View Qibla direction | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

> [!NOTE]
> Qibla is a client-side-only feature using device compass sensor. No API call or authentication required.

---

## Edge Cases & Rules

### Multi-Masjid Admin

- A user can be **Admin** of Masjid A and Masjid B simultaneously (separate rows in `masjid_admins`).
- When Admin accesses an endpoint with 🔒, the backend checks `masjid_admins` for a matching `(user_id, masjid_id, role_id)` row.
- An Admin of Masjid A **cannot** access Masjid B's admin-only data, even though they are an admin elsewhere.

### Cross-Masjid Access Denial

```
Admin of Masjid A → GET /api/v1/masjids/{masjidB}/prayer-times → ✅ (public read)
Admin of Masjid A → PUT /api/v1/masjids/{masjidB}/prayer-times → 403 FORBIDDEN
Admin of Masjid A → GET /api/v1/masjids/{masjidB}/members      → 403 FORBIDDEN
```

Backend guard pattern:
```typescript
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
@MasjidScoped() // custom decorator: extracts masjidId from route param, 
                 // verifies user has the required role for THAT masjid
```

### Sandha Auto-Link Logic

1. **Admin adds phone to sandha plan** → system checks `users.phone`:
   - **Phone found**: `sandha_plan_members.user_id` = matched user ID, `auto_linked = true`.
   - **Phone not found**: `user_id` remains NULL.
2. **New user registers with that phone** → application hook scans `sandha_plan_members WHERE phone = ? AND user_id IS NULL`:
   - All matching rows get `user_id` set, `auto_linked = true`, `linked_at = now()`.
3. **User can see their sandha records** once linked, via their own profile's sandha section.

### Custom Role Scope

- **Finance** and **Announcement** roles are always scoped to exactly one masjid.
- They **cannot** self-assign or escalate to Admin.
- Only **Admin** (of that masjid) or **Super Admin** can assign/revoke custom roles.
- Custom role users can still perform regular **User** actions (join other masjids, view prayer times, etc.).

### Guest Access Boundaries

- Guests can browse masjids, view prayer times, and view published announcements.
- Guests **cannot** join masjids, set preferences, receive notifications, or access any admin/financial data.
- Any attempt to access a protected endpoint without a JWT returns `401 UNAUTHORIZED`.

### Role Hierarchy (for backend guard resolution)

```
SUPER_ADMIN > ADMIN > FINANCE | ANNOUNCEMENT > USER > GUEST
```

Super Admin inherits all permissions. An Admin inherits User permissions. Finance and Announcement inherit User permissions but have no overlap with each other.
