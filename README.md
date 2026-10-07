# Packed

An iOS packing-list app: tell it where you're going and when, and it builds
a packing list from the real weather for your trip (AI-personalized when
you're logged in), lets you check things off, share lists with travel
buddies, and pin trip photos to a map.

## Getting it running

1. Open `Packed.xcodeproj` in Xcode (iOS 17+, iPhone).
2. Copy `Config/SupabaseSecrets.example.plist` to `Packed/SupabaseSecrets.plist`
   and fill in your Supabase project URL and anon key.
3. Build and run.

Backend setup (database migration, Edge Functions for account deletion and
AI lists, password reset email) is in [`supabase/README.md`](supabase/README.md).

## Before submitting to the App Store

- Publish `docs/privacy-policy.md` (fill in the bracketed parts first). With
  GitHub Pages on for the `docs/` folder, it lives at
  `https://dhritiburugupalli.github.io/Packed/privacy-policy`, which is what
  `Packed/AppLinks.swift` points to. Put the same URL in App Store Connect.
- Fill in the App Store Connect privacy questionnaire to match
  `Packed/PrivacyInfo.xcprivacy`: Contact Info (email, name), Identifiers
  (user ID), User Content (photos, other content), Location (precise), all
  linked to the user, none used for tracking.
