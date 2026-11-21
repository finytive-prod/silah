# Backend Live Verification Report

> **Executed Against**: Live Production Server (`https://backend-finytive.vercel.app/v1`) & PostgreSQL Database (`silah-db` / `eojasudtbpgwwtivcvbs`).
> **Zero Mock Guarantee**: All requests, HTTP codes, and responses documented below are from real HTTP executions and direct Postgres database queries.

---

## 1. User Registration Flow Verification

### Test User
- **Phone**: `+919940112233`
- **Name**: `Kamil Hameed`
- **Age**: `35`
- **Address**: `Anna Nagar, Chennai`

### Step 1: Pre-Check (User Does Not Exist)
Direct query to PostgreSQL before test:
```sql
SELECT id, phone, name, "isOnboarded" FROM "User" WHERE phone = '+919940112233';
```
**Result**: `null` (No row in database).

---

### Step 2: Trigger Live Registration (`POST /v1/auth/register`)
```bash
curl -i -X POST https://backend-finytive.vercel.app/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "phone": "+919940112233",
    "name": "Kamil Hameed",
    "age": 35,
    "address": "Anna Nagar, Chennai"
  }'
```

**HTTP Status**: `201 Created`  
**Live Response Payload**:
```json
{
  "success": true,
  "data": {
    "user": {
      "id": "24ed8a4c-5e08-4e16-a8e5-e75b20571445",
      "phone": "+919940112233",
      "name": "Kamil Hameed",
      "age": 35,
      "address": "Anna Nagar, Chennai",
      "isOnboarded": true,
      "isSuperAdmin": false,
      "hasMasjid": false,
      "adminRoles": []
    },
    "tokens": {
      "accessToken": "eyJhbGciOiJIUzI1Ni...",
      "refreshToken": "eyJhbGciOiJIUzI1Ni...",
      "expiresIn": 900,
      "refreshExpiresIn": 10368000
    }
  },
  "timestamp": "2026-11-21T07:16:51.992Z"
}
```

---

### Step 3: Database Physical Record Verification
Direct query to PostgreSQL table immediately following the `curl` execution:
```sql
SELECT id, phone, name, age, address, "isOnboarded", "isActive", "createdAt" 
FROM "User" 
WHERE phone = '+919940112233';
```

**Database Row Output**:
```json
{
  "id": "24ed8a4c-5e08-4e16-a8e5-e75b20571445",
  "phone": "+919940112233",
  "name": "Kamil Hameed",
  "age": 35,
  "address": "Anna Nagar, Chennai",
  "isOnboarded": true,
  "isActive": true,
  "createdAt": "2026-11-21T07:16:49.279Z"
}
```
**Conclusion**: `isOnboarded: true`, `name`, `age`, and `address` were permanently persisted in PostgreSQL.

---

### Step 4: Check User (`POST /v1/auth/check-user`)
```bash
curl -i -X POST https://backend-finytive.vercel.app/v1/auth/check-user \
  -H "Content-Type: application/json" \
  -d '{"phone": "+919940112233"}'
```

**HTTP Status**: `200 OK`  
**Live Response Payload**:
```json
{
  "success": true,
  "data": {
    "exists": true,
    "isOnboarded": true,
    "isSuperAdmin": false,
    "name": "Kamil Hameed",
    "hasMasjid": false
  },
  "timestamp": "2026-11-21T07:16:54.868Z"
}
```

---

### Step 5: Direct Login (`POST /v1/auth/login-direct`)
```bash
curl -i -X POST https://backend-finytive.vercel.app/v1/auth/login-direct \
  -H "Content-Type: application/json" \
  -d '{"phone": "+919940112233"}'
```

**HTTP Status**: `200 OK`  
**Live Response Payload**:
```json
{
  "success": true,
  "data": {
    "exists": true,
    "user": {
      "id": "24ed8a4c-5e08-4e16-a8e5-e75b20571445",
      "phone": "+919940112233",
      "name": "Kamil Hameed",
      "age": 35,
      "address": "Anna Nagar, Chennai",
      "isOnboarded": true,
      "isSuperAdmin": false,
      "hasMasjid": false,
      "adminRoles": []
    },
    "tokens": {
      "accessToken": "eyJhbGciOiJIUzI1Ni...",
      "refreshToken": "eyJhbGciOiJIUzI1Ni...",
      "expiresIn": 900,
      "refreshExpiresIn": 10368000
    },
    "hasMasjid": false
  },
  "timestamp": "2026-11-21T07:16:57.324Z"
}
```

---

### Step 6: Authenticated Profile (`GET /v1/auth/me`)
```bash
curl -i -X GET https://backend-finytive.vercel.app/v1/auth/me \
  -H "Authorization: Bearer <accessToken>"
```

**HTTP Status**: `200 OK`  
**Live Response Payload**:
```json
{
  "success": true,
  "data": {
    "id": "24ed8a4c-5e08-4e16-a8e5-e75b20571445",
    "phone": "+919940112233",
    "name": "Kamil Hameed",
    "language": "en",
    "avatarUrl": null,
    "isSuperAdmin": false,
    "adminRoles": [],
    "memberships": []
  },
  "timestamp": "2026-11-21T07:16:59.101Z"
}
```

---

## 2. Super Admin & Data Endpoints Verification

### Super Admin Dashboard (`GET /v1/dashboard/super-admin`)
```bash
curl -i -X GET https://backend-finytive.vercel.app/v1/dashboard/super-admin \
  -H "Authorization: Bearer <superAdminToken>"
```
**HTTP Status**: `200 OK`  
**Returned Metrics**:
- `totalMasjids`: 1
- `totalUsers`: 9
- `totalFollowers`: 2
- `totalSandhaPlans`: 1
- `totalSandhaCollected`: 200.00
- `pendingRequestsCount`: 1

---

### Masjids Listing (`GET /v1/masjids`)
```bash
curl -i -X GET https://backend-finytive.vercel.app/v1/masjids
```
**HTTP Status**: `200 OK`  
**Live Data**:
- `id`: `a933fef7-47b7-4c40-9da2-04e38605eb82`
- `name`: "Tiruvarur Big Masjid"
- `city`: "Tiruvarur"
- `approvalStatus`: "APPROVED"
- `isActive`: true
