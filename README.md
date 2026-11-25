# STI Legazpi eVoter

A voting app for student elections at STI College Legazpi, for **Android** and **Windows**. Students vote from their own phone or a school PC during a voting season. Admins run seasons, candidates and voter lists, and get the results the moment a season closes.

- **Download:** https://sti-legazpi-evoter.netlify.app
- **Server and maintenance:** see the backend repo, [`sti_legazpi_evoter_backend`](https://github.com/PlayerOne-bit/sti_legazpi_evoter_backend)

## For students

1. **Get the app** from the download page and sign in with your **student number** and the **season password**. The password is emailed to `lastname.XXXXXX@legazpi.sti.edu.ph` or given by your adviser. Signing in opens only the season that password belongs to.
2. **Check what's on:** the sign-in screen shows seasons voting now and coming up, with countdowns.
3. **Vote:** pick one candidate per position, review your choices, then submit. You can vote once per season, and only while it is open.
4. **See the results** after the season is closed and tallied.

Each season has its own password, so last season's password does not work for the next one.

## For admins

Sign in with **Admin** on the sign-in screen.

| Screen | What it does |
|---|---|
| **Dashboard** | The current season, a live countdown, and turnout. |
| **Seasons** | Create a season: club, school year, voting dates and who can vote by grade level. The date calendar shows the chosen days in blue and days already used by another season circled in red. Upcoming seasons can be edited or deleted. Once voting starts a season is locked; end it with **Close season and tally votes**. A season that still has no candidates when voting opens is deleted automatically. |
| **Candidates** | Candidates for a season, with photos (cropped square) and party lists. Positions are created from **Add candidate** by choosing **New position**; each position can be renamed, re-ranked or deleted from its own menu. Editable until voting starts. |
| **Party lists** | Names, colors and logos. |
| **Voters** | The season's voter list with a password for each student. Send passwords by email one at a time or all at once, make a new password, or export the list to Excel. |
| **Students** | Add students by hand or import from Excel, mark them inactive (graduated, transferred and so on), filter by school year and grade level. When a new school year starts (June), last year's students become inactive automatically. Importing them again (same student number, or same name with a new number) updates their school year, level and section and makes them active again. Student numbers and full names must be unique; people may share a first, middle or last name. The super admin can also edit a student's details. |
| **History** | Closed seasons with winners and polls. **Run again** copies a season's setup into a new one. |
| **Admins** | The super admin adds and removes other admins, and can turn on two-step sign-in by email. |

The app checks for a new version on the sign-in screen and offers **Update** when one is out.

## Developing

You need Flutter (stable), Android Studio for the Android SDK, and Visual Studio with "Desktop development with C++" for Windows builds. Run the backend on your PC first (see its README).

```powershell
flutter pub get
flutter run -d windows                      # talks to http://localhost:5080
flutter run -d <android-device>             # emulator uses http://10.0.2.2:5080
flutter run -d windows --dart-define=API_URL=https://sti-evoter-api.onrender.com
```

| Folder | What is in it |
|---|---|
| `lib/screens/` | `auth.dart` (sign-in), `client/` (student home and voting), `admin/` (all admin screens). |
| `lib/widgets/` | Shared pieces: season cards, the date range calendar, candidate cards, the update dialog. |
| `lib/data/` | `api.dart` (server calls and clock sync), `mock.dart` (app state and models), `app_update.dart` (self-update), `excel_io.dart`. |
| `scripts/` | `build_release.ps1` and `create_keystore.ps1`. |
| `download-site/` | The download page published on Netlify. |
| `assets/` | The logo, also used for the app icon (`dart run flutter_launcher_icons` after changing it). |

## Releasing a new version

One-time setup on the release PC:

1. Install the GitHub CLI and run `gh auth login`.
2. Run `scripts\create_keystore.ps1` once. **Back up `android\key.properties` and `C:\Users\<you>\keys\sti-evoter-release.jks`.** Without them no update can install over the existing Android app.
3. Keep a few GB free on the C: drive; the builds need it.

Each release:

1. Stop any debug session of the app. The script refuses a Windows build that has the debug engine in it.
2. Raise `version:` in `pubspec.yaml`, for example `1.0.6+7`. The number after `+` must go up every time.
3. Add the version to the **Update history** below and to `download-site/history.js`.
4. Run:
   ```powershell
   .\scripts\build_release.ps1 -ApiUrl https://sti-evoter-api.onrender.com -Notes "What changed" -GitHubRelease
   ```
   This builds the APK and Windows zip, checks the Windows app opens, writes `version.json` with sizes and SHA-256 hashes, and publishes GitHub release `v1.0.6`.
5. Commit and push. Netlify republishes the download page, and within 5 minutes installed apps show **Update**.

Add `-Mandatory` to force everyone to update. Always build both platforms, because the app only reads the newest release. To pull a bad release, delete it on GitHub; the one before becomes the newest again.

## Update history

Small fixes are grouped with the version they came with.

### 1.0.7 · November 25, 2026
- Works on phones held sideways: the admin menu moves to the side, and dialogs and the photo cropper fit the screen.
- The super admin can edit students. Student numbers and full names must be unique.
- New positions are created right in the Add candidate dialog.
- **Create voting season** is now a floating button that stays clear of the season list.

### 1.0.6 · November 25, 2026
- A student's sign-in opens only the season their password belongs to.
- Seasons with no candidates are deleted automatically when voting opens, and the season card warns about it beforehand.
- Students from past school years become inactive automatically. The Excel import updates returning students (same number, or same name with a new number) instead of skipping them.

### 1.0.4 – 1.0.5 · November 25, 2026
- The sign-in screen shows seasons **voting now** and **coming up**, with live countdowns.
- New calendar for season dates: pick the first and last day on one calendar, joined in blue. Days taken by another season are circled in red and cannot be picked.
- Seasons are locked once voting starts (no more editing an open season).

### 1.0.1 – 1.0.3 · November 25, 2026
- New app icon with the STI eVoter logo on Android and Windows.
- Fixed the Windows app closing right after it opens (1.0.1 only). Windows users on 1.0.1 must download again from the download page.
- The app version is shown at the bottom left of the sign-in screen.

### 1.0.0 · November 25, 2026
First public release.
- Students sign in with their student number and a per-season password, vote once per position, and see results after the tally.
- Admins manage seasons, candidates with photos, party lists with logos, students (with Excel import), voter lists and passwords, history and other admins.
- Season passwords can be emailed to students' school addresses.
- Light and dark mode.
- Self-update from the sign-in screen, and a download page for Android and Windows.
