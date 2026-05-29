# AutiSense

AutiSense is a Flutter Android app made to help parents track activities, reminders, screening results, and photo-based autism support analysis. It uses Supabase for login, database, storage, and server-side functions. The ML photo analysis backend runs separately.

This app is only for support and early screening guidance. It is not a medical diagnosis tool. Autism is not a disease, and parents should always consult a qualified professional for medical advice.

## Main Features

- Parent signup/login with Supabase Auth
- Child profile, activity progress, reminders, and streak tracking
- Assessment results saved in Supabase
- Photo analysis through a protected ML backend
- AI parent chat for general guidance
- First-time tutorial for new users
- Secure account deletion

## Tech Used

- Flutter
- Android
- Supabase
- Supabase Edge Functions
- Python/FastAPI ML backend

## Setup

Clone the project and install Flutter packages:

```powershell
cd D:\AutiSense-main\AutiSense-main
flutter pub get
```

Create your local config file:

```powershell
Copy-Item dev_defines.example.json dev_defines.json
```

Now open `dev_defines.json` and add your own public keys:

```json
{
  "SUPABASE_URL": "https://YOUR_PROJECT_REF.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_SUPABASE_ANON_KEY",
  "HCAPTCHA_SITE_KEY": "YOUR_HCAPTCHA_SITE_KEY"
}
```

Run on an Android phone:

```powershell
flutter devices
flutter run -d YOUR_DEVICE_ID --dart-define-from-file=dev_defines.json
```

Example:

```powershell
flutter run -d RMX2170 --dart-define-from-file=dev_defines.json
```

## Supabase Setup

1. Create a Supabase project.
2. Open SQL Editor.
3. Run `supabase_schema.sql`.
4. Keep RLS enabled.
5. Keep storage buckets private.
6. Enable Email auth.
7. Deploy the functions from `supabase/functions`.

Deploy functions:

```powershell
supabase functions deploy photo-analysis
supabase functions deploy delete-account
supabase functions deploy parent-chat
```

Add these secrets in Supabase, not in Flutter:

```powershell
supabase secrets set ML_BACKEND_URL=https://YOUR_ML_BACKEND_URL
supabase secrets set MLAPIKEY=YOUR_PRIVATE_ML_API_KEY
supabase secrets set SERVICE_ROLE_KEY=YOUR_SERVICE_ROLE_KEY
```

## ML Backend

The ML backend is inside `ml_backend/`. It can be deployed on Hugging Face Spaces or any Python hosting service.

Model files like `.h5` are not pushed to GitHub because they are large and should be handled separately.

The current recommended model file is:

```text
autism_detection_efficientnetb0_finetuned.weights.h5
```

## Build APK Without Play Store

To make an APK:

```powershell
flutter build apk --release --dart-define-from-file=dev_defines.json
```

APK location:

```text
build\app\outputs\flutter-apk\app-release.apk
```

You can copy this APK to an Android phone and install it manually. The phone may ask to allow installation from unknown sources.
