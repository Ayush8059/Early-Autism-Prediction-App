# AutiSense Supabase Backend Plan

This project is now prepared for an Android Flutter app that uses Supabase for authentication, database, and storage.

## Run The App With Supabase

Use your real Supabase project values:

```bash
flutter run --dart-define=SUPABASE_URL=https://your-project.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Do not hardcode the service-role key in Flutter. The anon key is okay for the app because Row Level Security protects the data.

## Supabase Setup

1. Create a Supabase project.
2. Open SQL Editor.
3. Run `supabase_schema.sql`.
4. Enable email/password auth in Authentication settings.
5. Create a private storage bucket named `child-photos`.
6. Add storage policies so users can only access paths under their own user id.
7. In Authentication > URL Configuration, add this redirect URL:

```txt
com.example.autisense://auth-callback
```

Recommended image path format:

```txt
{user_id}/{child_id}/{assessment_id}.jpg
```

## Authentication

Supabase Auth handles password hashing, session refresh, password reset, and email confirmation. Do not create a custom passwords table and do not use bcrypt in Flutter.

The Flutter app now supports:

- signup
- login
- password reset request
- logout
- session-based routing

## Scalability

Supabase can handle many simultaneous users if the schema and app are designed correctly:

- Use indexed columns for common queries.
- Keep Row Level Security enabled.
- Store photos in Supabase Storage, not database rows.
- Use Edge Functions or a separate worker for ML analysis.
- Do not run heavy image/ML work inside the mobile app request flow.
- Insert a `photo_assessments` row with `pending`, process it asynchronously, then update status.

For very high traffic later, move ML/photo processing to:

- Supabase Edge Functions for lightweight processing
- a Node/Python worker service for heavier ML
- a queue-based design using status fields and background workers

## CORS

CORS is mostly a browser issue. Android apps can call Supabase directly. If you later add Flutter Web or an admin dashboard, restrict allowed origins in that separate backend/dashboard.

## Security Rules

- Never expose the Supabase service-role key in Flutter.
- Keep all sensitive tables protected with RLS.
- Validate file size and type before upload.
- Avoid storing child photos longer than needed.
- Add a clear screening disclaimer because this app is not a medical diagnosis.
