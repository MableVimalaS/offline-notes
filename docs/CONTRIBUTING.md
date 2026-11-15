# Contributing to Scribble

Thanks for considering a contribution to Scribble! This guide describes a small, repeatable workflow for improving the Flutter app and its Bun/Hono mock API.

## Before you start

- Read the project [README](../README.md) to understand the offline-first sync flow.
- Check existing issues before starting substantial work.
- For a larger change, open an issue first so the scope can be discussed.
- Keep pull requests focused and explain the user-facing impact.

## Flutter app workflow

The Flutter application is in the `offline_notes_app` directory.

```bash
cd offline_notes_app
flutter pub get
dart format .
flutter analyze
flutter test
```

If a test command reports that no tests are configured for a particular area, mention that in your pull request rather than claiming the area is covered.

## Backend workflow

The mock REST API uses Bun and Hono. From the backend project directory:

```bash
bun install
bun run index.ts
```

The app's remote data source points to the deployed API by default. For local development, update its base URL to your local server and restore the intended value before committing.

## Pull request checklist

- [ ] The change solves one clearly described problem.
- [ ] Formatting and static analysis have been run for the affected code.
- [ ] Relevant tests have been added or updated.
- [ ] No API keys, credentials, personal data, or local configuration files are included.
- [ ] README or screenshots are updated when the user-visible behavior changes.
- [ ] The pull request description explains what changed and how it was checked.

## Scope and design principles

Scribble is an offline-first notes app. Contributions should preserve local access to notes when connectivity is unavailable, make sync behavior understandable, and handle conflicts explicitly. Avoid silently discarding local edits when remote data changes.

Thank you for helping make Scribble more reliable and easier to use.
