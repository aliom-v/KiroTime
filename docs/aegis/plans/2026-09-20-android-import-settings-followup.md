# Android Import And Settings Follow-Up Plan

## Goal

Apply the first real-device feedback from the `0.2.0` redesign:

- remove the black Android status bar and dark launch flash,
- accept academic-system host names without requiring users to type `https://`,
- use desktop User-Agent and persistent login as the forward defaults,
- provide an explicit action that fully clears WebView login data,
- replace split settings save behavior with one save action,
- build and verify release artifacts with the original release identity.

## Product Decisions

- HTTPS is mandatory. Bare host names are normalized to HTTPS; explicit HTTP URLs are rejected.
- No HTTP compatibility branch is retained.
- Desktop User-Agent is the default for new preferences.
- WebView login persistence is enabled by default.
- Clearing login state is a one-shot command, not a persistent toggle.
- Settings use one bottom `保存更改` action. The separate advanced-save action is removed.
- Destructive and command actions remain immediate and require their own confirmation where appropriate.
- The application remains light-only until a complete dark theme exists.

## Architecture

- `ImportPreferences` owns canonical HTTPS normalization and default values.
- Settings page state is an editable draft. One save coordinator persists semester, appearance, and import preferences.
- `CourseImportPage` owns the live WebView controller and cookie manager.
- A small application service owns cross-page WebView login-data clearing so settings does not construct a hidden WebView.
- Android launch theme and Flutter `SystemUiOverlayStyle` jointly own system-bar appearance before and after the first Flutter frame.
- Original release signing remains local and ignored by Git.

## Task 1: Fix Android System Bars

Files:

- `android/app/src/main/res/values/styles.xml`
- `android/app/src/main/res/values-night/styles.xml`
- `lib/main.dart`
- tests or static resource checks

Steps:

1. Use a light launch and normal theme in both system modes.
2. Set launch/status/navigation colors to the KiroTime light canvas.
3. Set dark status/navigation icons.
4. Apply the matching Flutter system overlay before `runApp`.

## Task 2: Canonical HTTPS Input And Defaults

Files:

- `lib/features/settings/domain/import_preferences.dart`
- import and settings presentation files
- domain and widget tests

Steps:

1. Add one public HTTPS normalizer.
2. Normalize bare hosts to `https://`.
3. Reject explicit HTTP and non-web schemes.
4. Reuse the normalizer for import loading, bookmarks, and settings save.
5. Change defaults to desktop User-Agent and persistent login.

## Task 3: Clear WebView Login Data

Files:

- import application/presentation files
- settings presentation files
- tests

Steps:

1. Clear cookies through `WebViewCookieManager`.
2. Clear cache and local storage on the live import WebView when available.
3. Expose a settings action with confirmation and completion feedback.
4. Stop clearing login data automatically when opening the import page.

## Task 4: Unified Settings Save

Files:

- `lib/features/settings/presentation/settings_center_dialog.dart`
- related widget tests

Steps:

1. Remove the advanced-section save button.
2. Rename the fixed bottom action to `保存更改`.
3. Persist semester and import preferences in one coordinated action.
4. Keep appearance preview responsive but ensure the current draft is persisted by the same action.
5. Keep URL bookmark edits in the page draft until save.
6. Add unsaved-change protection for back navigation where practical.

## Task 5: Release Verification

Steps:

1. Restore the verified original release secrets into ignored paths.
2. Run formatting, `flutter analyze`, and `flutter test`.
3. Build split release APKs and an Android App Bundle.
4. Verify package, version, alignment, and signer certificate.
5. Confirm the signer matches the previously released APK.
6. Commit tracked changes using the Lore commit protocol.

## Acceptance Criteria

- Android launch never selects a black theme solely because the system uses dark mode.
- `jw.school.edu.cn` becomes `https://jw.school.edu.cn`.
- `http://jw.school.edu.cn` is rejected.
- New preferences default to desktop UA and retained login.
- The settings screen contains one save action and no `保存高级设置` action.
- Clearing login data includes cookies, cache, and local storage.
- All automated tests and analysis pass.
- Release APK/AAB use `com.kirotime.app`, `0.2.0`, version code `2005`, and the original signer.

## Risks

- Some legacy intranet academic systems support only HTTP; they are intentionally unsupported.
- Cookie clearing is process-global for the WebView cookie store, so the confirmation text must say it clears all academic-system WebView sessions.
- System-bar rendering still requires a physical Android launch check because widget tests cannot capture the native pre-Flutter frame.

## Implementation Record

Completed on 2026-09-20:

- Android day and night launch themes now use the same light system-bar colors and dark icons.
- Academic URLs have one HTTPS-only normalizer shared by settings, bookmarks, and the import page.
- New preferences default to desktop User-Agent and retained WebView login state.
- Settings now keep a local draft and persist semester, appearance, and import preferences through one `保存更改` action.
- Clearing WebView cookies, cache, and local storage is an explicit confirmed action.
- Automatic WebView data clearing on import-page entry was retired.

Verification evidence:

- `flutter analyze`: passed with no issues.
- `flutter test`: 179 tests passed.
- Release outputs: universal APK, ABI-split APKs, and AAB built successfully.
- Universal APK: `com.kirotime.app`, `0.2.0`, version code `2005`, zip-aligned.
- Release signer SHA-256: `f1b788c709fda8eb8228bb5e66943ba051cf6cc842443478c21e244e68ee85de`.
- Remaining manual check: confirm the native launch/status-bar appearance on a physical Android device.
