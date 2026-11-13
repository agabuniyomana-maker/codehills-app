# Code Hills 1001 — development guide

Flutter app (Dart) rebuilt from the original Java Swing portal. One codebase
targets Android, iOS, Windows, macOS, Linux and web.

## Layout

```
lib/
  main.dart                  entry point (loads data + auth, then home)
  app_features.dart          ★ THE feature registry — start here
  theme/app_theme.dart       brand colors (gold/cream/dark brown) + styles
  widgets/portal_widgets.dart shared UI: PortalCard, PortalHeading, ImigongoBand,
                             ImigongoIdentityBadge (account pattern)…
  services/imigongo_identity.dart  stable account-derived Imigongo pattern
  models/models.dart         data types (BusinessPlan, ResourceCategory, PlanComment)
  data/app_data.dart         data store — currently seeded JSON, Supabase in phase 2
  services/auth_service.dart login/register — local now, Supabase Auth later
  features/<name>/           one folder per feature screen
test/
  widget_test.dart           login smoke test
  app_flow_test.dart         user flows (register, search, comment, admin)
  features_registry_test.dart opens EVERY feature in app_features.dart
```

## How to add a feature (5 steps)

1. Create `lib/features/<id>/<id>_screen.dart` — a self-contained widget.
   Reuse `PortalCard`, `PortalHeading`, `ImigongoBand`, `PortalButton` and the
   brand colors from `theme/app_theme.dart` so it matches the portal.
2. Append an `AppFeature` entry in `lib/app_features.dart` with a unique
   `id`, unique `icon`, `phoneLabel` (one word), and a `probeText`
   (a short substring, including original casing, that is always visible
   when that screen is open).
3. Run `flutter analyze` — it catches broken imports and type errors.
4. Run `flutter test` — `features_registry_test.dart` automatically opens
   your new feature and asserts its `probeText`. If your screen uses a new
   data type or flow, add a test in `app_flow_test.dart` too.
5. Done. The screen appears in the desktop rail and (for the first five
   entries) the phone bottom bar — no other file needs editing.

The first five registry entries are what phones show in the bottom bar;
reorder the list to change phone prominence. `initialFeatureIndex` in the
same file controls which feature the app opens on.

## How to update a feature

- **Text/layout**: edit the feature's own folder only.
- **Shared look & feel**: change `theme/app_theme.dart` or
  `widgets/portal_widgets.dart` — it applies everywhere at once.
- **Data fields**: `models/models.dart` + `data/app_data.dart`
  (keep JSON keys equal to the old SQLite column names so the seed export
  keeps working).
- **Login/registration rules**: `services/auth_service.dart`.

## Conventions

- No business logic inside build methods — put it in `data/` or `services/`.
- Keep screens self-contained; share through `widgets/`, never by importing
  another feature's screen unless it's a real navigation target.
- Colors only as `AppColors.*` constants; never hardcode hex values.
- Every navigable feature must be registered in `app_features.dart`
  (the registry test enforces the invariants: unique ids, unique icons).

## Commands

```bash
flutter analyze        # lint + type check (must stay clean)
flutter test           # all tests (must stay green)
flutter run -d web-server --web-port=8080   # dev server + hot reload (r)
flutter run -d windows                      # desktop
flutter build apk                          # Android installer
```

## Backend (Supabase) — how it works

The app has **two modes**, picked at build time by `services/backend_config.dart`:

* **Local mode (default)** — everything in SharedPreferences; seeded admin
  `admin / codehills1001` in **debug builds only**. Used by tests, demos and
  any debug build without keys. Release builds refuse local accounts, so a
  release without Supabase keys has no sign-in rather than plain-text
  credentials.
* **Supabase mode** — real accounts (Supabase Auth) and shared comments /
  inquiries / partner requests (Postgres). Enabled by passing keys:

```bash
flutter run -d web-server --web-port=8080 \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR-ANON-KEY
```

**Setup steps (once per Supabase project):**

1. Create a project at https://supabase.com/dashboard.
2. Run the schema: paste [supabase/migrations/20250101000000_init.sql](supabase/migrations/20250101000000_init.sql)
   into Dashboard → SQL Editor → Run (or `supabase db push`).
3. (Recommended) Dashboard → Authentication → Providers → Email →
   turn **Confirm email** off for smooth sign-up, or leave it on — the app
   tells the user to check their inbox.
4. Grab URL + anon key from Dashboard → Project Settings → API.
5. Sign up in the app with your email, then promote yourself to admin:

   ```sql
   update public.profiles set is_admin = true
   where username = 'your-email-name';
   ```

**Rules:**

* Keys are `--dart-define` only — never hard-code them, never commit them.
* `flutter test` always runs local mode (no dart-defines), so tests never
  touch a live backend.
* `data/app_data.dart` and `services/auth_service.dart` are still the only
  files that touch storage/auth — screens never know which mode is active.
* RLS is enabled on every table; the migration is the source of truth for
  policies (users insert their own rows, admins read inboxes).

**Not yet in the backend (later steps):** catalog/PDF hosting in Supabase
Storage, admin plan uploads, real-time comment updates.
