# Packed backend setup (Supabase)

Everything the app needs on the Supabase side beyond the original tables.
Do these once, in order. Steps 1 and 2 are required for the app to work at
all; the rest turn on the new features.

## 1. Point the app at your project

1. Copy `Config/SupabaseSecrets.example.plist` to `Packed/SupabaseSecrets.plist`.
2. Fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY` from **Project Settings -> API**.

`Packed/SupabaseSecrets.plist` is git-ignored, so it never ends up in the
public repo. (The anon key is designed to be public, but this keeps your
project details out of GitHub anyway.) Xcode picks the file up
automatically because the project uses a synchronized folder.

## 2. Install the Supabase CLI and link the project

```sh
brew install supabase/tap/supabase
supabase login
supabase link --project-ref YOUR_PROJECT_REF
```

## 3. Run the database migration

Either paste `supabase/migrations/20261007000000_sharing_and_ai_limits.sql`
into the **SQL Editor** and run it, or:

```sh
supabase db push
```

This adds list sharing (`list_shares` + a few functions) and the
`ai_generations` table used to cap AI usage. It also makes usernames
unique, case-insensitive. If that last part fails, you have duplicate
usernames in `profiles`; fix them and re-run.

## 4. Deploy the account-deletion function (App Store requirement)

```sh
supabase functions deploy delete-account
```

No secrets needed: Supabase gives Edge Functions the service-role key
automatically. The app's **Profile -> Delete Account** button calls it.

## 5. Deploy the AI packing-list function

```sh
supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
supabase functions deploy generate-packing-list
```

Optional settings:

```sh
supabase secrets set MONTHLY_LIST_LIMIT=20                      # per user, per 30 days (default 20)
supabase secrets set ANTHROPIC_MODEL=claude-haiku-4-5-20251001  # default; cheapest
```

This is what lets normal users get AI lists without their own API key.
**You pay for these API calls**, so set a monthly spend limit in the
Anthropic Console. Users who add their own key in Profile still call
Anthropic directly and don't count against your bill or the cap.

If this function isn't deployed, the app quietly falls back to the
built-in rule-based lists, same as before.

## 6. Turn on password reset codes

The app's **Forgot password?** flow has users type a 6-digit code from
the email (no web page or deep link needed). In the dashboard go to
**Authentication -> Emails -> Reset Password** and make sure the template
includes the code, for example:

```html
<h2>Reset your Packed password</h2>
<p>Enter this code in the app: <strong>{{ .Token }}</strong></p>
```

Supabase's built-in email sender is heavily rate-limited (a few emails
per hour). Before launch, set up custom SMTP under
**Authentication -> Emails -> SMTP Settings**.
