# AutiSense

AutiSense is an Android-first Flutter app for parent support, guided activities, reminders, screening history, and ML-assisted photo analysis. It uses Supabase for authentication, database, storage, and Edge Functions. The ML model runs separately behind an authenticated backend.

Important: AutiSense is a support and screening tool, not a medical diagnosis app. Autism is not a disease. For diagnosis or treatment decisions, users should consult a qualified professional.

## Features

- Email/password authentication with Supabase Auth
- Secure parent profiles, child profiles, reminders, activity progress, and assessment history
- Private Supabase Storage buckets for user-owned photos
- Row Level Security policies for user-scoped database access
- Photo analysis through Supabase Edge Function plus a protected ML backend
- AI parent chat through a protected backend function
- First-run tutorial/onboarding for new users
- Account deletion through a secure server-side function
- Android release APK support for sideloading without Play Store

## Tech Stack

- Flutter and Dart
- Android SDK
- Supabase Auth, Postgres, Storage, and Edge Functions
- Hugging Face Spaces or another Python host for the ML backend
- FastAPI/TensorFlow backend in `ml_backend/`

## Project Structure

```text
lib/                    Flutter app code
supabase/functions/     Supabase Edge Functions
supabase_schema.sql     Database tables, indexes, RLS policies, and storage policies
ml_backend/             Python ML API for photo analysis
android/                Android project
dev_defines.example.json Safe example runtime config
```

## Security Rules

Never commit these files or values:

- `dev_defines.json`
- `.env` or `.env.*`
- Supabase service-role key
- ML API key
- SMTP/API provider secrets
- hCaptcha secret key
- Android signing files such as `.jks`, `.keystore`, and `key.properties`
- Large/private ML model files such as `.h5`, `.keras`, `.tflite`, `.onnx`

The Supabase anon key and hCaptcha site key are public client keys, but they should still be used with RLS, rate limits, and proper backend checks. The service-role key must only live in Supabase Edge Function secrets.

## Local Setup

Install:

- Flutter stable
- Android Studio and Android SDK
- A real Android phone with USB debugging, or an Android emulator

Copy the example config:

```powershell
Copy-Item dev_defines.example.json dev_defines.json
```

Then edit `dev_defines.json` with your own public project values:

```json
{
  "SUPABASE_URL": "https://YOUR_PROJECT_REF.supabase.co",
  "SUPABASE_ANON_KEY": "YOUR_PUBLIC_SUPABASE_ANON_KEY",
  "HCAPTCHA_SITE_KEY": "YOUR_PUBLIC_HCAPTCHA_SITE_KEY"
}
```

Run the app on Android:

```powershell
cd D:\AutiSense-main\AutiSense-main
flutter pub get
flutter devices
flutter run -d YOUR_DEVICE_ID --dart-define-from-file=dev_defines.json
```

For your Realme device, if Flutter shows `RMX2170`, use:

```powershell
flutter run -d RMX2170 --dart-define-from-file=dev_defines.json
```

## Supabase Setup

Create a Supabase project, then:

1. Open SQL Editor.
2. Run `supabase_schema.sql`.
3. Keep RLS enabled on all user-data tables.
4. Keep storage buckets private.
5. In Authentication, enable Email provider.
6. Keep anonymous sign-ins off unless you intentionally support guest mode.
7. Keep manual linking off unless you need it.
8. Configure rate limits and attack protection for production.
9. Add app redirect URLs for auth flows.

Useful redirect URL for Android deep links:

```text
com.example.autisense://auth-callback
```

For local web/debug callback testing, only use localhost while developing:

```text
http://localhost:3000
```

## Supabase Edge Function Secrets

Set secrets in Supabase, not in Flutter and not in GitHub:

```powershell
supabase secrets set ML_BACKEND_URL=https://YOUR_ML_BACKEND_HOST
supabase secrets set MLAPIKEY=YOUR_PRIVATE_ML_API_KEY
supabase secrets set SERVICE_ROLE_KEY=YOUR_PRIVATE_SERVICE_ROLE_KEY
```

If you use AI chat:

```powershell
supabase secrets set AI_PROVIDER=groq
supabase secrets set AI_MODEL=YOUR_MODEL_NAME
supabase secrets set GROQ_API_KEY=YOUR_PRIVATE_GROQ_KEY
```

Deploy functions:

```powershell
supabase functions deploy photo-analysis
supabase functions deploy delete-account
supabase functions deploy parent-chat
```

## ML Backend

The Python ML backend is in `ml_backend/`. It should be deployed separately, for example on Hugging Face Spaces. Keep the ML API protected with an API key.

Required private backend secret:

```text
MLAPIKEY
```

Health check:

```powershell
curl.exe -H "x-ml-api-key: YOUR_PRIVATE_ML_API_KEY" https://YOUR_SPACE_URL/health
```

Model files are ignored by Git because they are large and should not be pushed accidentally. Upload model files to your backend host manually or use Git LFS only if you intentionally want model files in a model/backend repository.

Current recommended model file:

```text
autism_detection_efficientnetb0_finetuned.weights.h5
```

Local evaluation reproduced about `86.33%` accuracy on the available 300-image test split. Do not claim medical-grade accuracy from this alone.

## Build APK Without Play Store

To launch normally without Play Store, create a release APK and install/share it manually:

```powershell
cd D:\AutiSense-main\AutiSense-main
flutter build apk --release --dart-define-from-file=dev_defines.json
```

APK output:

```text
build\app\outputs\flutter-apk\app-release.apk
```

Install on your connected phone:

```powershell
flutter install -d RMX2170 --release
```

Or copy `app-release.apk` to the phone and install it manually. On Android, the user may need to allow "Install unknown apps" for the file manager/browser used to open the APK.

For wider real-world sharing, create a proper release signing key and keep these files private:

```text
android/key.properties
android/app/*.jks
```

They are already ignored by `.gitignore`.

## GitHub Push Checklist

Before pushing:

```powershell
cd D:\AutiSense-main\AutiSense-main
git status
git status --ignored
```

Confirm these are ignored or absent:

- `dev_defines.json`
- `.env`
- `supabase/.temp/`
- `ml_backend/.venv/`
- `ml_backend/*.h5`
- `android/key.properties`
- `*.jks`
- `*.keystore`
- `*.apk`

First push to GitHub:

```powershell
git init
git add .
git status
git commit -m "Prepare AutiSense for Android release"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
git push -u origin main
```

If Git shows any real secret in `git status`, stop and remove it before committing.

## Production Notes

- Use Supabase RLS for every user-owned table.
- Store child photos in private buckets only.
- Keep the ML API key only in Supabase Edge Function secrets and the ML host secrets.
- Keep service-role access only in Edge Functions.
- Use custom SMTP for reliable confirmation and reset emails when possible.
- Keep a clear medical disclaimer in the UI.
- Load test the ML backend separately because ML inference is the slowest part of the system.
