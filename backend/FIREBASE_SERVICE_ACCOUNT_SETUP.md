# Firebase Service Account Setup Guide

## ✅ Mobile App Configuration - DONE!
Your `google-services.json` file has been saved to:
- `mobile/android/app/google-services.json`

This file is for the **Android mobile app** and is already configured.

---

## 🔥 Backend Server Configuration - REQUIRED

For the **backend server** to work with Firebase Authentication, you need a **Service Account Key**.

### Step 1: Download Service Account Key

1. Go to Firebase Console: https://console.firebase.google.com/project/fluentfly-d442d/settings/serviceaccounts/adminsdk

2. Click on **"Generate New Private Key"** button

3. A JSON file will download with a name like:
   ```
   fluentfly-d442d-firebase-adminsdk-xxxxx-xxxxxxxxxx.json
   ```

4. **IMPORTANT**: Keep this file secure! It contains private keys.

### Step 2: Save the File

Move the downloaded file to your backend folder:

```bash
# From your project root
cd backend

# Copy the downloaded file (replace with your actual filename)
cp ~/Downloads/fluentfly-d442d-firebase-adminsdk-*.json ./firebase-service-account.json
```

### Step 3: Verify Setup

The file should look like this:

```json
{
  "type": "service_account",
  "project_id": "fluentfly-d442d",
  "private_key_id": "xxxxxxxxxxxxx",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIE...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxxxx@fluentfly-d442d.iam.gserviceaccount.com",
  "client_id": "xxxxxxxxxxxxx",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/..."
}
```

### Step 4: Update .env (Already Done)

Your `.env` file already has:
```env
FIREBASE_PROJECT_ID=fluentfly-d442d
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json
```

### Step 5: Test the Setup

```bash
# Start the backend server
npm run start:dev

# You should see:
# [Nest] INFO [AuthService] Firebase Admin SDK initialized successfully
```

---

## 🧪 For Testing Without Service Account

If you want to run tests without Firebase (temporary):

### Option 1: Mock Firebase in Tests

The integration tests are already configured to handle Firebase failures gracefully. They will:
- Accept 401 errors for auth endpoints (expected without Firebase)
- Skip Firebase-dependent tests
- Continue testing other endpoints

### Option 2: Use Test Environment Variables

Create a `.env.test` file:

```bash
cp .env .env.test
```

Then modify it to skip Firebase initialization:

```env
# Set to empty to skip Firebase
FIREBASE_PROJECT_ID=
FIREBASE_SERVICE_ACCOUNT_PATH=
```

---

## 📱 What You Have Now

✅ **Mobile App**: `google-services.json` configured for Android
✅ **Backend**: Project ID configured, waiting for Service Account Key

## 🎯 Next Steps

1. **Download Service Account Key** from Firebase Console
2. **Save it** as `backend/firebase-service-account.json`
3. **Restart backend** server
4. **Run tests** with `npm run test:e2e`

---

## 🔒 Security Notes

- ⚠️ **NEVER commit** `firebase-service-account.json` to Git
- ✅ It's already in `.gitignore`
- ✅ Use environment variables in production
- ✅ Rotate keys if accidentally exposed

---

## Need Help?

If you encounter issues:
1. Check Firebase Console permissions
2. Verify the JSON file format
3. Ensure file path is correct in `.env`
4. Check server logs for detailed errors
