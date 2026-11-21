# API Contract — Silah (Masjid Management & Namaz Time)

> **Source of Truth**: Generated directly from NestJS backend controllers & DTOs (`backend/src/modules/`).
> All endpoints are verified against the live backend production server.

---

## 1. Environment & Base URLs

| Environment | Base URL |
|---|---|
| **Production (Vercel Live)** | `https://backend-finytive.vercel.app/v1` |
| **Local Development** | `http://localhost:3000/v1` |
| **Swagger Interactive Docs** | `https://backend-finytive.vercel.app/v1/docs` or `http://localhost:3000/v1/docs` |

---

## 2. Standard Response Envelope

All API endpoints pass through `TransformInterceptor` and `HttpExceptionFilter`.

### Success Response Envelope (HTTP 200 / 201)
```json
{
  "success": true,
  "data": { ... },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

### Error Response Envelope (HTTP 4xx / 5xx)
```json
{
  "success": false,
  "error": {
    "code": "BAD_REQUEST",
    "message": "Human-readable error description",
    "details": ["Specific field validation errors if any"]
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

## 3. Authentication & Authorization

- **Protected Endpoints**: Require `Authorization: Bearer <accessToken>` header.
- **Tokens**: Access tokens have 120-day validity for frictionless user mobile experience.
- **Roles**:
  - `SUPER_ADMIN`: System-wide administrator.
  - `ADMIN`: Masjid Mutawalli / Chief Administrator.
  - `FINANCE`: Masjid Treasurer (manages Sandha and collections).
  - `ANNOUNCEMENT`: Masjid Communication volunteer.
  - `PUBLIC` / `MUSALLI`: Regular registered worshipper.

---

## 4. Auth Module (`/v1/auth`)

### 4.1 POST `/auth/check-user` 🔓
Check whether a mobile number is already registered and onboarded before prompting or sending OTP.

- **Auth**: None (Public)
- **Request Body**:
```json
{
  "phone": "+919876543210"
}
```
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "exists": true,
    "isOnboarded": true,
    "isSuperAdmin": false,
    "name": "Ahmed",
    "hasMasjid": true
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```
*(If user does not exist, `exists: false, isOnboarded: false`)*.

---

### 4.2 POST `/auth/login-direct` 🔓
Direct mobile number login (bypasses OTP for seamless 120-day persistent mobile login).

- **Auth**: None (Public)
- **Request Body**:
```json
{
  "phone": "+919876543210"
}
```
- **Response** (HTTP 200 - User Exists):
```json
{
  "success": true,
  "data": {
    "exists": true,
    "user": {
      "id": "c1f7a0b3-...",
      "phone": "+919876543210",
      "name": "Ahmed",
      "age": 32,
      "address": "No 12, Main Road, Chennai",
      "isOnboarded": true,
      "isSuperAdmin": false,
      "hasMasjid": true,
      "primaryMasjidId": "m-8f7a...",
      "adminRoles": [
        {
          "masjidId": "m-8f7a...",
          "role": "ADMIN"
        }
      ]
    },
    "tokens": {
      "accessToken": "eyJhbGciOi...",
      "refreshToken": "eyJhbGciOi...",
      "expiresIn": 10368000
    },
    "hasMasjid": true
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```
*(If user does not exist: `{ "exists": false, "message": "User does not exist. Please register." }`)*.

---

### 4.3 POST `/auth/register` 🔓
Registers or updates a user profile and marks `isOnboarded: true`. Auto-links any existing Sandha records matching this mobile number.

- **Auth**: None (Public)
- **Request Body**:
```json
{
  "phone": "+919876543210",
  "name": "Ahmed",
  "age": 32,
  "address": "No 12, Main Road, Chennai"
}
```
*(Fields: `phone` [required], `name` [required], `age` [optional, 5-120], `address` [optional])*.

- **Response** (HTTP 201):
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "c1f7a0b3-...",
      "phone": "+919876543210",
      "name": "Ahmed",
      "age": 32,
      "address": "No 12, Main Road, Chennai",
      "isOnboarded": true,
      "isSuperAdmin": false,
      "hasMasjid": false,
      "adminRoles": []
    },
    "tokens": {
      "accessToken": "eyJhbGciOi...",
      "refreshToken": "eyJhbGciOi...",
      "expiresIn": 10368000
    }
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 4.4 POST `/auth/device-token` 🔒
Registers or updates the user's FCM device token for targeted push notifications.

- **Auth**: Bearer Token required
- **Request Body**:
```json
{
  "fcmToken": "fcm_token_sample_string_12345",
  "platform": "ANDROID"
}
```
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "success": true,
    "message": "FCM device token registered"
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 4.5 POST `/auth/otp/send` 🔓
Generates and sends an OTP to the specified mobile number.

- **Auth**: None (Public)
- **Request Body**:
```json
{
  "phone": "+919876543210"
}
```
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "message": "OTP sent successfully",
    "expiresInSeconds": 300
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 4.6 POST `/auth/otp/verify` 🔓
Verifies the 6-digit OTP and authenticates the user.

- **Auth**: None (Public)
- **Request Body**:
```json
{
  "phone": "+919876543210",
  "otp": "123456"
}
```
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "c1f7a0b3-...",
      "phone": "+919876543210",
      "name": "Ahmed",
      "language": "en",
      "isOnboarded": true,
      "isSuperAdmin": false,
      "hasMasjid": true,
      "adminRoles": []
    },
    "tokens": {
      "accessToken": "eyJhbGciOi...",
      "refreshToken": "eyJhbGciOi...",
      "expiresIn": 10368000
    },
    "isNewUser": false
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 4.7 POST `/auth/refresh` 🔓
Refreshes an expired access token using a valid refresh token.

- **Auth**: None (Public)
- **Request Body**:
```json
{
  "refreshToken": "eyJhbGciOi..."
}
```
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "eyJhbGciOi...",
    "expiresIn": 10368000
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 4.8 GET `/auth/me` 🔒
Retrieves current authenticated profile, admin roles, and masjid memberships.

- **Auth**: Bearer Token required
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "id": "c1f7a0b3-...",
    "phone": "+919876543210",
    "name": "Ahmed",
    "language": "en",
    "avatarUrl": null,
    "isSuperAdmin": false,
    "adminRoles": [
      {
        "masjidId": "m-8f7a...",
        "masjidName": "Jamia Masjid",
        "masjidNameTa": "ஜாமியா பள்ளிவாசல்",
        "role": "ADMIN"
      }
    ],
    "memberships": [
      {
        "masjidId": "m-8f7a...",
        "masjidName": "Jamia Masjid",
        "masjidNameTa": "ஜாமியா பள்ளிவாசல்",
        "isPrimary": true
      }
    ]
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

## 5. Masjids Module (`/v1/masjids`)

### 5.1 GET `/masjids` 🔓
Search and list all active and approved masjids.

- **Auth**: None (Public)
- **Query Parameters**:
  - `search` (optional): Filter by name or Tamil name.
  - `city` (optional): Filter by city.
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": [
    {
      "id": "a933fef7-47b7-4c40-9da2-04e38605eb82",
      "name": "Tiruvarur Big Masjid",
      "nameTa": "திருவாரூர் பெரிய பள்ளிவாசல்",
      "address": "Main Road",
      "city": "Tiruvarur",
      "state": "Tamil Nadu",
      "latitude": 10.7712,
      "longitude": 79.6366,
      "qrToken": "7b06886e06f97ef7ffad1921356bebe3",
      "approvalStatus": "APPROVED",
      "isActive": true
    }
  ],
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 5.2 GET `/masjids/:id` 🔓
Get complete details of a specific masjid by its ID, including admin contacts.

- **Auth**: None (Public)
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "id": "a933fef7-...",
    "name": "Tiruvarur Big Masjid",
    "nameTa": "திருவாரூர் பெரிய பள்ளிவாசல்",
    "address": "Main Road",
    "city": "Tiruvarur",
    "qrToken": "7b06886e...",
    "admins": [
      {
        "id": "ma-123",
        "role": { "name": "ADMIN" },
        "user": {
          "id": "u-456",
          "name": "Mutawalli Sahib",
          "phone": "+919876543210"
        }
      }
    ]
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 5.3 GET `/masjids/qr/:qrToken` 🔓
Scan & lookup masjid details via permanent QR token string.

- **Auth**: None (Public)
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "id": "a933fef7-...",
    "name": "Tiruvarur Big Masjid",
    "city": "Tiruvarur"
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 5.4 POST `/masjids` 🔒
Submit a registration for a new masjid.
- Regular user submissions enter `PENDING` approval.
- Super Admin submissions are automatically `APPROVED` and `isActive: true`.
- Automatically enforces duplicate prevention (~100m proximity check and exact name in city check).

- **Auth**: Bearer Token required
- **Request Body**:
```json
{
  "name": "Masjid An-Noor",
  "nameTa": "மஸ்ஜித் அந்-நூர்",
  "address": "45 Anna Salai",
  "city": "Chennai",
  "state": "Tamil Nadu",
  "latitude": 13.0604,
  "longitude": 80.2496,
  "phone": "+914428291234"
}
```
- **Response** (HTTP 201):
```json
{
  "success": true,
  "data": {
    "id": "new-uuid",
    "name": "Masjid An-Noor",
    "approvalStatus": "PENDING",
    "isActive": false,
    "isPendingApproval": true,
    "message": "Masjid registration request submitted! It will be reviewed and approved by the Super Admin."
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 5.5 POST `/masjids/:id/join` 🔒
Join or follow a masjid as a member / favorite.

- **Auth**: Bearer Token required
- **Request Body**:
```json
{
  "isPrimary": true
}
```
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "id": "membership-uuid",
    "userId": "u-123",
    "masjidId": "m-456",
    "isPrimary": true
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 5.6 POST `/masjids/:masjidId/roles` 🔒
Assign a role (`ADMIN`, `FINANCE`, `ANNOUNCEMENT`) to a member by phone number.

- **Auth**: Bearer Token (Masjid `ADMIN` only)
- **Request Body**:
```json
{
  "phone": "+919876543215",
  "name": "Janab Farooq",
  "role": "FINANCE"
}
```
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "success": true,
    "message": "Assigned FINANCE role to Janab Farooq"
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 5.7 GET `/masjids/requests/pending` 🔒
List all pending masjid registration requests awaiting Super Admin review.

- **Auth**: Bearer Token (Super Admin only)
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": [
    {
      "id": "req-uuid",
      "name": "Masjid Al-Huda",
      "city": "Madurai",
      "address": "West Street",
      "approvalStatus": "PENDING",
      "createdAt": "2026-11-21T06:00:00.000Z",
      "creator": {
        "id": "u-creator",
        "name": "Brother Bilal",
        "phone": "+919876543299",
        "age": 40,
        "address": "Madurai"
      }
    }
  ],
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 5.8 POST `/masjids/requests/:id/approve` 🔒
Super Admin approves a pending masjid registration request. Activates the masjid and grants the creator the `ADMIN` role.

- **Auth**: Bearer Token (Super Admin only)
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "success": true,
    "message": "Masjid \"Masjid Al-Huda\" approved successfully. Creator has been granted Masjid Admin role.",
    "masjid": {
      "id": "req-uuid",
      "name": "Masjid Al-Huda",
      "approvalStatus": "APPROVED",
      "isActive": true
    }
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 5.9 POST `/masjids/requests/:id/reject` 🔒
Super Admin rejects a pending masjid request with an optional reason.

- **Auth**: Bearer Token (Super Admin only)
- **Request Body**:
```json
{
  "reason": "Duplicate registration of existing masjid"
}
```
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "success": true,
    "message": "Masjid request rejected."
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

## 6. Prayer Times Module (`/v1/masjids/:masjidId/prayer-times`)

### 6.1 GET `/masjids/:masjidId/prayer-times/today` 🔓
Get prayer times for today or a specific date. Falls back gracefully to the latest configured date if the target day is not configured.

- **Auth**: None (Public)
- **Query Parameters**:
  - `date` (optional, `YYYY-MM-DD`): Target date. Defaults to current date.
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "id": "pt-uuid",
    "masjidId": "m-uuid",
    "date": "2026-11-21T00:00:00.000Z",
    "fajrAdhan": "05:00",
    "fajrJamaah": "05:30",
    "dhuhrAdhan": "12:30",
    "dhuhrJamaah": "13:15",
    "asrAdhan": "16:15",
    "asrJamaah": "16:45",
    "maghribAdhan": "18:15",
    "maghribJamaah": "18:20",
    "ishaAdhan": "19:45",
    "ishaJamaah": "20:15",
    "jummahKhutbah": "12:45",
    "jummahJamaah": "13:30"
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 6.2 GET `/masjids/:masjidId/prayer-times/schedule` 🔓
Get full monthly prayer schedule for a given year and month.

- **Auth**: None (Public)
- **Query Parameters**:
  - `year` (required, number, e.g. `2026`)
  - `month` (required, number, 1-12, e.g. `11`)
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": [
    {
      "date": "2026-11-01T00:00:00.000Z",
      "fajrJamaah": "05:30",
      "dhuhrJamaah": "13:15",
      "asrJamaah": "16:45",
      "maghribJamaah": "18:20",
      "ishaJamaah": "20:15"
    }
  ],
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 6.3 PUT `/masjids/:masjidId/prayer-times` 🔒
Update or create prayer timings for a specific date (Masjid Admin only).

- **Auth**: Bearer Token (Masjid `ADMIN` only)
- **Request Body**:
```json
{
  "date": "2026-11-21",
  "fajrAdhan": "05:00",
  "fajrJamaah": "05:30",
  "dhuhrAdhan": "12:30",
  "dhuhrJamaah": "13:15",
  "asrAdhan": "16:15",
  "asrJamaah": "16:45",
  "maghribAdhan": "18:15",
  "maghribJamaah": "18:20",
  "ishaAdhan": "19:45",
  "ishaJamaah": "20:15",
  "jummahKhutbah": "12:45",
  "jummahJamaah": "13:30"
}
```
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "id": "pt-uuid",
    "masjidId": "m-uuid",
    "date": "2026-11-21T00:00:00.000Z",
    "fajrJamaah": "05:30",
    "dhuhrJamaah": "13:15"
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

## 7. Announcements Module (`/v1/masjids/:masjidId/announcements`)

### 7.1 GET `/masjids/:masjidId/announcements` 🔓
List all active published announcements for a masjid (pinned items first, then descending by date).

- **Auth**: None (Public)
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": [
    {
      "id": "ann-uuid-1",
      "masjidId": "m-uuid",
      "category": "GENERAL",
      "title": "ஜும்ஆ தொழுகை நேரம் மாற்றம் / Jummah Time Update",
      "titleTa": "ஜும்ஆ தொழுகை நேரம் மாற்றம்",
      "body": "Jummah khutbah will start at 12:45 PM starting this Friday.",
      "bodyTa": "இந்த வாரம் முதல் ஜும்ஆ குத்பா மதியம் 12:45 மணிக்கு தொடங்கும்.",
      "isPinned": true,
      "publishedAt": "2026-11-20T10:00:00.000Z",
      "creator": {
        "id": "u-admin",
        "name": "Mutawalli Sahib"
      }
    }
  ],
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 7.2 POST `/masjids/:masjidId/announcements` 🔒
Create and broadcast a new announcement. Automatically triggers FCM push notification to all followers if `notifyPush: true`.

- **Auth**: Bearer Token (Masjid `ADMIN` or `ANNOUNCEMENT` volunteer)
- **Request Body**:
```json
{
  "category": "GENERAL",
  "title": "ஜும்ஆ தொழுகை நேரம் மாற்றம் / Jummah Time Update",
  "titleTa": "ஜும்ஆ தொழுகை நேரம் மாற்றம்",
  "body": "Jummah khutbah will start at 12:45 PM starting this Friday.",
  "bodyTa": "இந்த வாரம் முதல் ஜும்ஆ குத்பா மதியம் 12:45 மணிக்கு தொடங்கும்.",
  "isPinned": true,
  "notifyPush": true
}
```
*(Categories: `GENERAL`, `EVENT`, `JANAZAH`, `RAMADAN`, `EMERGENCY`)*.

- **Response** (HTTP 201):
```json
{
  "success": true,
  "data": {
    "id": "ann-new-uuid",
    "title": "ஜும்ஆ தொழுகை நேரம் மாற்றம் / Jummah Time Update",
    "publishedAt": "2026-11-21T06:55:00.000Z"
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 7.3 DELETE `/masjids/:masjidId/announcements/:id` 🔒
Delete an announcement.

- **Auth**: Bearer Token (Masjid `ADMIN` or `ANNOUNCEMENT` volunteer)
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "count": 1
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

## 8. Sandha Module (`/v1/masjids/:masjidId/sandha`)

### 8.1 GET `/masjids/:masjidId/sandha/plans` 🔓
List all active sandha (subscription / maintenance) plans for a masjid.

- **Auth**: None (Public)
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": [
    {
      "id": "plan-uuid-1",
      "masjidId": "m-uuid",
      "name": "மாதாந்திர சந்தா / Monthly Maintenance",
      "amount": 200.00,
      "frequency": "MONTHLY",
      "description": "General maintenance fund",
      "isActive": true,
      "_count": {
        "members": 45,
        "payments": 128
      }
    }
  ],
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 8.2 POST `/masjids/:masjidId/sandha/plans` 🔒
Create a new Sandha plan for a masjid.

- **Auth**: Bearer Token (Masjid `ADMIN` or `FINANCE` volunteer)
- **Request Body**:
```json
{
  "name": "மாதாந்திர சந்தா / Monthly Maintenance",
  "amount": 200.00,
  "frequency": "MONTHLY",
  "description": "General maintenance fund"
}
```
*(Frequencies: `MONTHLY`, `QUARTERLY`, `YEARLY`, `ONE_TIME`)*.

- **Response** (HTTP 201):
```json
{
  "success": true,
  "data": {
    "id": "plan-new-uuid",
    "name": "மாதாந்திர சந்தா / Monthly Maintenance",
    "amount": 200.00,
    "frequency": "MONTHLY"
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 8.3 POST `/masjids/:masjidId/sandha/plans/:planId/members` 🔒
Enroll a member into a sandha plan. Automatically links to a registered user if their phone number matches.

- **Auth**: Bearer Token (Masjid `ADMIN` or `FINANCE` volunteer)
- **Request Body**:
```json
{
  "phone": "+919876543213",
  "name": "Abdul Rahman"
}
```
- **Response** (HTTP 201):
```json
{
  "success": true,
  "data": {
    "id": "member-uuid",
    "planId": "plan-uuid-1",
    "phone": "+919876543213",
    "name": "Abdul Rahman",
    "autoLinked": true,
    "linkedAt": "2026-11-21T06:55:00.000Z"
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 8.4 POST `/masjids/:masjidId/sandha/payments` 🔒
Record a cash or UPI payment for an enrolled member.

- **Auth**: Bearer Token (Masjid `ADMIN` or `FINANCE` volunteer)
- **Request Body**:
```json
{
  "planMemberId": "member-uuid",
  "amount": 200.00,
  "method": "CASH",
  "receiptNumber": "REC-2026-001",
  "periodStart": "2026-11-01",
  "periodEnd": "2026-11-30",
  "notes": "Paid in cash after Friday prayer"
}
```
*(Methods: `CASH`, `UPI`, `BANK_TRANSFER`, `CHEQUE`)*.

- **Response** (HTTP 201):
```json
{
  "success": true,
  "data": {
    "id": "pay-uuid",
    "amount": 200.00,
    "paidAt": "2026-11-21T06:55:00.000Z",
    "receiptNumber": "REC-2026-001"
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 8.5 GET `/masjids/:masjidId/sandha/my-status` 🔒
Get current logged-in user's Sandha enrollment details and full payment history for this masjid.

- **Auth**: Bearer Token required
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": [
    {
      "id": "member-uuid",
      "name": "Ahmed",
      "phone": "+919876543210",
      "plan": {
        "id": "plan-uuid-1",
        "name": "மாதாந்திர சந்தா / Monthly Maintenance",
        "amount": 200.00,
        "frequency": "MONTHLY",
        "masjid": {
          "id": "m-uuid",
          "name": "Jamia Masjid",
          "nameTa": "ஜாமியா பள்ளிவாசல்"
        }
      },
      "payments": [
        {
          "id": "pay-uuid-1",
          "amount": 200.00,
          "paidAt": "2026-11-05T12:00:00.000Z",
          "method": "CASH",
          "periodStart": "2026-11-01T00:00:00.000Z",
          "periodEnd": "2026-11-30T00:00:00.000Z",
          "receiptNumber": "REC-2026-001"
        }
      ]
    }
  ],
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

## 9. Dashboard Module (`/v1/dashboard`)

### 9.1 GET `/dashboard/super-admin` 🔒
Super Admin system-wide overview: total masjids, registered users, total followers, sandha collections, recent masjids, and pending approval requests.

- **Auth**: Bearer Token (Super Admin only)
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "metrics": {
      "totalMasjids": 1,
      "totalUsers": 2,
      "totalFollowers": 2,
      "totalSandhaPlans": 1,
      "totalSandhaCollected": 200.00,
      "totalTransactions": 1,
      "pendingRequestsCount": 1
    },
    "recentMasjids": [
      {
        "id": "m-uuid",
        "name": "Tiruvarur Big Masjid",
        "_count": { "memberships": 2, "admins": 1 }
      }
    ],
    "pendingRequests": [
      {
        "id": "req-uuid",
        "name": "Masjid Al-Huda",
        "creator": {
          "id": "u-creator",
          "name": "Brother Bilal",
          "phone": "+919876543299"
        }
      }
    ]
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 9.2 GET `/dashboard/masjid/:masjidId` 🔒
Masjid Admin and volunteers operational dashboard: member count, today's prayer timing status, active notices, sandha plans, and recent collections.

- **Auth**: Bearer Token (Masjid `ADMIN`, `FINANCE`, or `ANNOUNCEMENT`)
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "masjid": {
      "id": "m-uuid",
      "name": "Jamia Masjid"
    },
    "metrics": {
      "memberCount": 42,
      "hasConfiguredTodayTimes": true,
      "activeAnnouncementsCount": 2,
      "activePlansCount": 1
    },
    "todayPrayerTimes": {
      "fajrJamaah": "05:30",
      "dhuhrJamaah": "13:15"
    },
    "sandhaPlans": [ ... ],
    "recentPayments": [ ... ]
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

## 10. Users Module (`/v1/users`)

### 10.1 GET `/users/profile` 🔒
Get complete profile of logged-in user including memberships and masjid administration roles.

- **Auth**: Bearer Token required
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "id": "u-uuid",
    "phone": "+919876543210",
    "name": "Ahmed",
    "age": 32,
    "address": "No 12, Main Road, Chennai",
    "language": "ta",
    "avatarUrl": null,
    "isOnboarded": true,
    "isSuperAdmin": false,
    "memberships": [ ... ],
    "masjidAdmins": [ ... ]
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 10.2 PUT `/users/profile` 🔒
Update user profile details (Name, Language preference, Avatar URL).

- **Auth**: Bearer Token required
- **Request Body**:
```json
{
  "name": "Janab Abdul Rahman",
  "language": "ta",
  "avatarUrl": "https://example.com/avatar.jpg"
}
```
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "id": "u-uuid",
    "name": "Janab Abdul Rahman",
    "language": "ta"
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

### 10.3 GET `/users` 🔒
List all registered users in the system (Super Admin only) with pagination.

- **Auth**: Bearer Token (Super Admin only)
- **Query Parameters**:
  - `search` (optional): Filter by name or mobile number.
  - `page` (optional, default: 1)
  - `limit` (optional, default: 20)
- **Response** (HTTP 200):
```json
{
  "success": true,
  "data": {
    "total": 42,
    "page": 1,
    "limit": 20,
    "items": [
      {
        "id": "u-uuid",
        "phone": "+919876543210",
        "name": "Ahmed",
        "isSuperAdmin": false,
        "isOnboarded": true,
        "createdAt": "2026-11-20T10:00:00.000Z"
      }
    ]
  },
  "timestamp": "2026-11-21T06:55:00.000Z"
}
```

---

## 11. Complete Endpoint Summary Matrix (26 Endpoints)

| # | HTTP Method | Endpoint Path | Module | Access / Role | Summary |
|---|---|---|---|---|---|
| 1 | `POST` | `/v1/auth/check-user` | Auth | 🔓 Public | Check if phone exists and onboarding status |
| 2 | `POST` | `/v1/auth/login-direct` | Auth | 🔓 Public | Direct phone login (120-day persistent session) |
| 3 | `POST` | `/v1/auth/register` | Auth | 🔓 Public | Register profile (Name, Age, Address) |
| 4 | `POST` | `/v1/auth/device-token` | Auth | 🔒 Authenticated | Register/update FCM device token |
| 5 | `POST` | `/v1/auth/otp/send` | Auth | 🔓 Public | Request OTP |
| 6 | `POST` | `/v1/auth/otp/verify` | Auth | 🔓 Public | Verify OTP and authenticate |
| 7 | `POST` | `/v1/auth/refresh` | Auth | 🔓 Public | Refresh expired JWT token |
| 8 | `GET` | `/v1/auth/me` | Auth | 🔒 Authenticated | Current user profile, roles & masjids |
| 9 | `GET` | `/v1/masjids` | Masjids | 🔓 Public | Search & list active approved masjids |
| 10 | `GET` | `/v1/masjids/requests/pending` | Masjids | 🔒 Super Admin | List pending masjid creation requests |
| 11 | `POST` | `/v1/masjids/requests/:id/approve` | Masjids | 🔒 Super Admin | Approve pending masjid request |
| 12 | `POST` | `/v1/masjids/requests/:id/reject` | Masjids | 🔒 Super Admin | Reject pending masjid request |
| 13 | `GET` | `/v1/masjids/:id` | Masjids | 🔓 Public | Get masjid details by ID |
| 14 | `GET` | `/v1/masjids/qr/:qrToken` | Masjids | 🔓 Public | Lookup masjid by permanent QR token |
| 15 | `POST` | `/v1/masjids` | Masjids | 🔒 Authenticated | Register masjid (User: Pending / Admin: Direct) |
| 16 | `POST` | `/v1/masjids/:id/join` | Masjids | 🔒 Authenticated | Join / favorite masjid |
| 17 | `POST` | `/v1/masjids/:masjidId/roles` | Masjids | 🔒 Masjid Admin | Assign Finance/Announcement/Admin role |
| 18 | `GET` | `/v1/masjids/:masjidId/prayer-times/today` | Prayer Times | 🔓 Public | Today's or specific date prayer times |
| 19 | `GET` | `/v1/masjids/:masjidId/prayer-times/schedule` | Prayer Times | 🔓 Public | Monthly prayer schedule |
| 20 | `PUT` | `/v1/masjids/:masjidId/prayer-times` | Prayer Times | 🔒 Masjid Admin | Update/set prayer times for date |
| 21 | `GET` | `/v1/masjids/:masjidId/announcements` | Announcements | 🔓 Public | List active notices |
| 22 | `POST` | `/v1/masjids/:masjidId/announcements` | Announcements | 🔒 Admin / Announcement | Create notice + FCM push notification |
| 23 | `DELETE` | `/v1/masjids/:masjidId/announcements/:id` | Announcements | 🔒 Admin / Announcement | Delete notice |
| 24 | `GET` | `/v1/masjids/:masjidId/sandha/plans` | Sandha | 🔓 Public | List active sandha plans |
| 25 | `POST` | `/v1/masjids/:masjidId/sandha/plans` | Sandha | 🔒 Admin / Finance | Create sandha plan |
| 26 | `POST` | `/v1/masjids/:masjidId/sandha/plans/:planId/members` | Sandha | 🔒 Admin / Finance | Enroll member into sandha plan |
| 27 | `POST` | `/v1/masjids/:masjidId/sandha/payments` | Sandha | 🔒 Admin / Finance | Record payment (Cash/UPI/etc.) |
| 28 | `GET` | `/v1/masjids/:masjidId/sandha/my-status` | Sandha | 🔒 Authenticated | User's sandha status and payments |
| 29 | `GET` | `/v1/dashboard/super-admin` | Dashboard | 🔒 Super Admin | System-wide metrics & pending approvals |
| 30 | `GET` | `/v1/dashboard/masjid/:masjidId` | Dashboard | 🔒 Masjid Admin / Volunteer | Masjid operational dashboard |
| 31 | `GET` | `/v1/users/profile` | Users | 🔒 Authenticated | Current user profile |
| 32 | `PUT` | `/v1/users/profile` | Users | 🔒 Authenticated | Update user profile |
| 33 | `GET` | `/v1/users` | Users | 🔒 Super Admin | List all registered users (paginated) |
