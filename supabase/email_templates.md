# Email templates for 6-digit codes (OTP)

In the Supabase dashboard go to **Authentication -> Emails -> Templates**
(older dashboards: Authentication -> Email Templates). For EACH template
below, replace the body so it shows `{{ .Token }}` and has no
`{{ .ConfirmationURL }}` link, then save.

## Confirm sign up   (subject: `Your Adaptive Tasks code`)

```html
<h2>Confirm your email</h2>
<p>Enter this 6-digit code in the app:</p>
<h1 style="letter-spacing:8px">{{ .Token }}</h1>
<p>The code expires soon. If you did not sign up, ignore this email.</p>
```

## Reset password   (subject: `Your password reset code`)

```html
<h2>Reset your password</h2>
<p>Enter this 6-digit code in the app:</p>
<h1 style="letter-spacing:8px">{{ .Token }}</h1>
<p>If you did not ask for this, ignore this email.</p>
```

## Magic link, Change email address, Invite user

Not used by the app today, but change them the same way (`{{ .Token }}`
instead of `{{ .ConfirmationURL }}`) so no email ever contains a link.
"Reauthentication" already uses `{{ .Token }}`.

## Settings to check

- Authentication -> Sign In / Providers -> Email: **Confirm email = ON**
  (required, otherwise sign-up never asks for a code).
- Same page: **Email OTP length = 6**, and set the expiry you want
  (default is 1 hour).
- Supabase's built-in email sender is limited to a couple of emails per hour.
  Use Custom SMTP (see your earlier SMTP settings) while testing.
