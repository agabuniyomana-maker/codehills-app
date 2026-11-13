# Code Hills 1001 — Flutter Rebuild

The original Java Swing desktop app, rebuilt in **Flutter** so one codebase can
run on **Android, iOS, Windows, macOS, Linux and the web** — ready for Google
Play, the Apple App Store and the Microsoft Store.

## What's ported so far (Phase 1)

| Original (Java Swing) | New (Flutter) |
|---|---|
| `Main.java` login/signup | `lib/features/auth/login_screen.dart`, `signup_screen.dart` |
| `CardLayout` screen switching | `lib/features/home/home_shell.dart` (responsive rail / bottom bar, registry-driven) |
| `NaturalResourcesPanel.java` | `lib/features/catalog/catalog_screen.dart` (search + filters + cards) |
| `PlanDetailPanel.java` | `lib/features/plan_detail/plan_detail_screen.dart` (PDF save, comments, partner request) |
| `Main.java` auth (`accounts.properties`) | `lib/services/auth_service.dart` (local, Supabase-ready) |
| SQLite `code_hills.db` | Exported to `assets/seed/seed_data.json` (Supabase in Phase 2) |
| JFreeChart stats | `lib/features/stats/stats_screen.dart` (animated bar chart) |
| Imigongo styling | `lib/theme/app_theme.dart` + `lib/widgets/portal_widgets.dart` |

Brand colors are preserved: gold `#BE964E`, yellow `#FFD23C`, cream `#FAF2D7`,
dark brown `#372314`.

All 7 business plans, 6 natural resources, the 7 PDFs and cover images from
the original database are bundled as assets.

## Demo credentials (debug builds without a backend only)

- **User:** register a new account from the Sign Up screen.
- **Admin:** username `admin`, password `codehills1001`

These work only when `AuthService.demoModeAvailable` is true — a **debug**
build with no Supabase keys. Release builds refuse local accounts entirely, so
real accounts must come from Supabase Auth.

## Backend (optional, Supabase)

The app runs fully offline by default. To enable real shared accounts and
data, create a Supabase project, run
[supabase/migrations/20250101000000_init.sql](supabase/migrations/20250101000000_init.sql)
in its SQL editor, and pass the keys at run time:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR-PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR-ANON-KEY
```

Full setup steps (email confirmation, first admin promotion) are in
[AGENTS.md](AGENTS.md#backend-supabase--how-it-works).

## Run it

```bash
flutter pub get
flutter run -d chrome        # web preview
flutter run -d windows       # Windows desktop
flutter build apk            # Android installer for the Play Store
```

## My Imigongo identity

Every account gets a permanent, deterministic Imigongo pattern derived from
its stable account id (`auth.users.id`, or a generated local account id) — see
`lib/services/imigongo_identity.dart`. The pattern is pure artwork: the same
account sees the same composition after logout/login, on another device or
after reinstalling, renaming the account never changes it, and it is never
used for authentication or password handling. It is shown in the header bar
(`lib/features/home/home_shell.dart`) with the accessible label "Your Imigongo
identity" and a short code (`IMI-ABC-DEF`) so identities do not rely on colour
alone.

## Phase 2 (next)

- Supabase backend: real accounts, shared comments/partner requests/inquiries —
  **done** (see Backend section above).
- PDF hosting in Supabase Storage + admin plan uploads.
- PDF reader inside the app instead of save-to-disk.
- Water Products and Product Articles: first full content added (expandable ventures and article text).

## Easy feature updates

Features are declared in **one place**: [lib/app_features.dart](lib/app_features.dart).
Each feature is a folder under `lib/features/` plus one registry entry
(id, label, icon, screen builder, test probe). Adding or reordering a
feature updates the desktop rail, the phone bottom bar, and is covered
automatically by `test/features_registry_test.dart` — no other file to touch.
Step-by-step instructions live in [AGENTS.md](AGENTS.md).

## Project layout

```
lib/
  main.dart                  app entry
  app_features.dart          ★ feature registry (add features here)
  theme/app_theme.dart       brand colors + component themes
  models/models.dart         BusinessPlan, ResourceCategory, PlanComment
  data/app_data.dart         data store (local or Supabase Postgres)
  services/backend_config.dart  local vs Supabase mode (dart-define keys)
  services/auth_service.dart auth (local or Supabase Auth)
  widgets/portal_widgets.dart PortalCard, ImigongoBand, buttons, avatars
  features/<name>/           one folder per feature screen
supabase/
  migrations/                SQL schema + RLS policies
assets/
  images/                    banner, resource photos, plan covers
  pdfs/                      the 7 business-plan PDFs
  seed/seed_data.json        exported from the original SQLite database
test/
  features_registry_test.dart opens every registered feature
  app_flow_test.dart         register / search / comment / admin flows
```
