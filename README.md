# DSD Flyers

**Davis School District Flyers** — ADA-compliant flyer distribution platform replacing Peachjar and DSDads.

Lives at `daviskids.org/flyers`. Built as a Cloudflare Worker that takes over the `/flyers/*` path while the rest of `daviskids.org` continues to be served by the existing Cloudflare Pages site.

## Status

🚧 **In active build** — targeting a working pilot for the superintendent meeting in 30 days.

## What this is

The district currently uses **Peachjar** to push flyers to parents and **DSDads** for employee announcements. Both systems push image PDFs that are not ADA-compliant. As of the April 2026 ADA Title II rule, this is a federal compliance liability, not just an inconvenience.

This platform replaces both, with:

- **Structured flyer content** (real text, not embedded-in-image text) so screen readers actually work
- **Automated accessibility audit** on every PDF and HTML upload — fail-closed, not fail-open
- **Sixth-grade reading level checks** on submitted content (district communication standard)
- **Single backend** for parent flyers and employee announcements, with audience targeting
- **District-owned data** — parent contact graph, analytics, archive, and audit trail all stay with DSD
- **Email + SMS digest delivery** with opt-in preferences per school and category
- **WCAG 2.1 AA from day one** on the platform itself, not bolted on later

## For Code (the implementation agent)

Everything you need to build the v1 is in [`IMPLEMENTATION_PLAN.md`](./IMPLEMENTATION_PLAN.md).

Read that document top to bottom before writing any code. Then check the open GitHub issue labeled `v1-build` for the work checklist.

## Architecture

- **Cloudflare Worker** — `dsd-flyers`, deployed to `daviskids.org/flyers/*`
- **D1** — `dsd-flyers` (production) / `dsd-flyers-dev` (staging)
- **R2** — `dsd-flyers-assets` for PDF/image uploads
- **KV** — `dsd-flyers-kv` for sessions, rate limits, and audit cache
- **Vectorize** — `dsd-flyers-search` (768-dim, bge-base-en-v1.5) for semantic flyer search
- **Workers AI** — for generating embeddings and reading-level analysis
- **Browser Rendering** — for axe-core HTML accessibility scans
- **Hono** — TypeScript routing framework

## Stack and conventions

- TypeScript strict mode
- Hono for routing and JSX server-side rendering
- All Cloudflare API calls use `X-Auth-Email` + `X-Auth-Key` headers (Global API Key), never Bearer tokens
- All deploys go through GitHub Actions or `wrangler deploy`
- D1 migrations live in `schema.sql`; seeds live in `seeds/`

## Setup

```bash
npm install
npm run db:migrate:dev   # apply schema to dev DB
npm run db:seed:dev      # seed schools and departments
npm run dev              # local dev server
```

To deploy:

```bash
npm run deploy:dev       # staging
npm run deploy           # production
```

## Secrets

Set with `wrangler secret put <NAME>`:

| Name | Purpose |
|------|---------|
| `MICROSOFT_CLIENT_ID` | Azure AD app registration for daviskids.org tenant |
| `MICROSOFT_CLIENT_SECRET` | Azure AD app secret |
| `MICROSOFT_TENANT_ID` | Davis tenant ID |
| `GOOGLE_CLIENT_ID` | Google OAuth |
| `GOOGLE_CLIENT_SECRET` | Google OAuth |
| `APPLE_CLIENT_ID` | Apple Sign-In service ID |
| `APPLE_TEAM_ID` | Apple developer team ID |
| `APPLE_KEY_ID` | Apple key ID |
| `APPLE_PRIVATE_KEY` | Apple private key |
| `RESEND_API_KEY` | Email delivery |
| `TWILIO_ACCOUNT_SID` | SMS delivery |
| `TWILIO_AUTH_TOKEN` | SMS auth |
| `TWILIO_FROM_NUMBER` | SMS sender |
| `SESSION_SECRET` | HMAC for signing session cookies |

## Resources (already provisioned)

- **Repo:** https://github.com/ramonscottf/dsd-flyers
- **D1 prod:** `5b5de1d1-ca4a-4e27-bad5-f0a071a75b58`
- **D1 dev:** `2c95fbe9-ed47-4099-8b39-d7bbc6a873a5`
- **R2:** `dsd-flyers-assets`
- **KV:** `72249a65614a42f987b766e8ee616f68`
- **Vectorize:** `dsd-flyers-search`
- **Cloudflare zone (daviskids.org):** `e9aac6e9fab72eae9eda35335bc47f40`

## License

This codebase is owned by the Davis Education Foundation. Built by Wicko Waypoint LLC.
