# Member Field App

Native iOS member portal for [stockman-bellweather-labs](../stockman-bellweather-labs). This app mirrors the web **Member Portal** (`/portal`) and member-accessible tools (animals, account settings). It does not include admin dashboard features.

## Features

| Area | Web route | Mobile tab / screen |
|------|-----------|---------------------|
| Portal home | `/portal` | **Home** — welcome, quick actions, member info |
| Society news | `/portal` | **News** — published society newsletters |
| My Animals | `/portal/animals` | **My Animals** — list, detail, new registration, bulk actions |
| Learning Center | `/portal/learning-center` | **More → Learning Center** |
| Contact Society | `/portal/contact-society` | **More → Contact Society** |
| Account | `/dashboard/account/*` | **More → My Account** |
| Onboarding | `/onboarding/*` | Profile + membership payment gates |

### Quick actions (from portal home)

- My Animals
- Births / New Registrations
- Transfer (creates admin approval request)
- Castrates
- Deaths
- Flag For Sale / Hire / AI
- Check Mate (opens selected animals)

## Setup

1. Open `MemberFieldApp/MemberFieldApp.xcodeproj` in Xcode.
2. Configure Supabase credentials in `MemberFieldApp/App/AppConfig.swift` using values from stockman-bellweather-labs `.env.local`:
   - `NEXT_PUBLIC_SUPABASE_URL` → `supabaseURL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY` → `supabaseAnonKey`

   Alternatively, set Xcode scheme environment variables `SUPABASE_URL` and `SUPABASE_ANON_KEY`.

3. Build and run on a simulator or device (iOS 17+ recommended).

## Architecture

- **SwiftUI** + **Supabase Swift SDK** for auth and data (same database/RLS as the web app)
- Session, onboarding, dues, and portal flows match the web member portal
- Membership payment uses the same placeholder/simulated flow as the web onboarding form

## Sign in

Use the same member email/password created through society invitation or application approval in stockman-bellweather-labs.

## Notes

- Admin users can sign in but only see member portal functionality (no admin dashboard).
- Learning Center is a placeholder, matching the web portal.
- Notification settings are read-only, matching the web member account page.

<!-- tiny change for push test -->
