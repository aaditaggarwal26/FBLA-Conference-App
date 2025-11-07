# Firebase Admin Setup Guide

## Quick Setup (5 minutes)

### Step 1: Create Admin User in Firebase Auth
1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your FBLA Conference App project
3. Go to **Authentication** → **Users** tab
4. Click **"Add user"** button
5. Enter:
   - **Email:** `admin@gmail.com`
   - **Password:** Choose a secure password (min 6 characters)
6. Click **"Add user"**
7. ✅ **IMPORTANT:** Copy the **User UID** (looks like `xYz123AbC...`)

---

### Step 2: Create Admin Document in Firestore
1. Go to **Firestore Database** in Firebase Console
2. Click **"Start collection"**
3. **Collection ID:** `admins`
4. **Document ID:** Paste the UID you copied in Step 1
5. Add these fields (click "Add field" for each):

| Field Name | Type | Value |
|------------|------|-------|
| `uid` | string | [Paste the UID from Step 1] |
| `email` | string | `admin@gmail.com` |
| `role` | string | `super_admin` |
| `grantedAt` | timestamp | [Select today's date] |
| `grantedBy` | string | `system` |
| `permissions` | array | See below ↓ |

6. For the `permissions` array, click "Add item" for each:
   - `manage_events`
   - `manage_announcements`
   - `manage_schedule`
   - `manage_users`
   - `manage_pins`
   - `view_analytics`

7. Click **"Save"**

---

### Step 3: Deploy Firestore Indexes
Open your terminal and run:
```bash
cd /Users/aaditaggarwal/Github/FBLA-Conference-App
firebase deploy --only firestore:indexes
```

Wait for indexes to build (1-5 minutes)

---

### Step 4: Test Admin Access
1. Open your FBLA Conference App
2. Sign in with:
   - **Email:** `admin@gmail.com`
   - **Password:** [The password you set in Step 1]
3. Go to **Profile** tab
4. You should see a purple **"Admin Panel"** button
5. Click it to access admin features!

---

## Sample Data (Optional)

### Add Sample Event
1. In Firestore, create collection: `events`
2. Click "Add document" with auto-ID
3. Add fields:

```json
{
  "title": "Opening Ceremony",
  "description": "Join us for the official opening ceremony of FBLA Conference 2025",
  "location": "Main Auditorium",
  "dateTime": [timestamp: 2025-11-15 09:00:00],
  "createdAt": [timestamp: now],
  "createdBy": "[YOUR_ADMIN_UID]"
}
```

### Add Sample Announcement
1. In Firestore, create collection: `announcements`
2. Click "Add document" with auto-ID
3. Add fields:

```json
{
  "title": "Welcome to FBLA Conference 2025!",
  "message": "We're thrilled to have you join us for this year's conference. Check the schedule for all upcoming events!",
  "priority": "important",
  "createdAt": [timestamp: now],
  "createdBy": "[YOUR_ADMIN_UID]"
}
```

---

## Verification Checklist

- [ ] Admin user created in Firebase Authentication
- [ ] Admin UID copied
- [ ] Admin document created in `admins` collection
- [ ] All permissions added to admin document
- [ ] Firestore indexes deployed
- [ ] Can sign in to app with admin@gmail.com
- [ ] "Admin Panel" button appears in Profile
- [ ] Can access admin panel
- [ ] Can create events and announcements

---

## Troubleshooting

**Problem:** "Admin Panel" button doesn't appear
- **Solution:** Make sure the admin document UID exactly matches the Authentication UID

**Problem:** Can't create events/announcements
- **Solution:** Check that all permissions are in the `permissions` array

**Problem:** "Index building" error
- **Solution:** Wait 5-10 minutes for Firestore indexes to finish building, then try again

**Problem:** Can't sign in
- **Solution:** Reset password in Firebase Console → Authentication → Users → click user → Reset password

---

## Admin Features

Once logged in as admin, you can:
- ✅ Create conference events
- ✅ Post announcements (normal, important, urgent)
- ✅ View all pins
- ✅ Manage users (coming soon)
- ✅ Update schedules (coming soon)

---

## Security Notes

- Only users in the `admins` collection can access admin features
- Change the default password immediately after first login
- Don't share admin credentials
- Regularly review admin permissions

---

## Quick Reference: Admin Document Structure

```javascript
{
  uid: "ABC123xyz...",           // Must match Firebase Auth UID
  email: "admin@gmail.com",
  role: "super_admin",
  permissions: [
    "manage_events",
    "manage_announcements",
    "manage_schedule",
    "manage_users",
    "manage_pins",
    "view_analytics"
  ],
  grantedAt: Timestamp(2025-11-06 00:00:00),
  grantedBy: "system"
}
```
