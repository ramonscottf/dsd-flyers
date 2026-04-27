# DSD Flyers — Implementation Plan (v1)

**For:** Code (the implementation agent)
**From:** Skippy (architecture and infrastructure)
**Last updated:** 2026-04-27 (revised: unified platform decision)
**Target ship date:** 2026-05-27 (30 days; superintendent pitch the same week)

---

## 1. Mission and constraints

### 1.1 What we are building

**One platform. Two doors.**

A unified flyer distribution platform for Davis School District (DSD) that lives at `daviskids.org/flyers`. It replaces **Peachjar** (currently used for parent-facing flyers) AND **DSDads** (currently used for employee announcements) with a single system.

There is no separate employee product. There is no separate parent product. There is just **Flyers**. Each flyer carries an `audience` flag (`parents` | `employees` | `both`), and the public site has two entry points — one for parents, one for employees — that filter the same underlying content.

The platform must be ADA-compliant by default — every flyer that ships through it should pass WCAG 2.1 AA.

### 1.2 Why we are building it

Federal Title II of the ADA (April 2024 rule) requires WCAG 2.1 AA on all public-facing digital content from public entities. Peachjar pushes image PDFs whose text is not duplicated as accessible text. Every Peachjar flyer is a potential OCR (Office for Civil Rights) complaint. The district already has a relationship with the OCR office and cannot afford continued exposure.

DSDads has the same problem internally — and arguably worse, because internal-facing tools historically receive less compliance scrutiny but the legal exposure is identical.

**Compliance is the wedge. Cost savings and platform consolidation are the bonuses.**

### 1.3 The contact graph (this changes the migration story)

DSD owns the parent contact list. We are not begging Peachjar for a data export. The district will hand us:
- Parent email addresses (associated with student-school relationships when available)
- Employee email addresses (`@dsdmail.net` accounts)

We seed the `subscriptions` table on day one of pilot from this district-owned data with `source = 'district_import'` and a default frequency. Imported subscribers are treated as opted-in (this is allowed for district-internal communications under CAN-SPAM since the district has a pre-existing relationship), but every digest still includes one-click unsubscribe and a "manage your preferences" link.

SMS is the opposite story. We are NOT importing SMS contacts from any vendor. Phone numbers are collected only via opt-in on our own subscribe form. The SMS channel grows organically as parents and employees opt in. Twilio rails on the Wicko A2P 10DLC campaign (registration in progress).

### 1.4 Hard constraints
- **30-day timeline.** v1 must be live with at least one pilot school posting real flyers before the superintendent meeting.
- **Lives inside daviskids.org.** Same brand. Same domain. Users never feel they have left the district site.
- **WCAG 2.1 AA from day one** on the platform UI itself — not retrofitted.
- **Sixth-grade reading level target** for all submitted flyer content. The district has formally adopted this as a communication standard. The platform must measure and surface this; it is not a hard block on submission, but it is surfaced on every submit and flagged for moderation.
- **Open-source first.** Free alternatives over paid services wherever the quality is acceptable.
- **No SharePoint dependencies.** The accessibility training that triggered this project specifically warned that SharePoint files break when employees leave. Do not store anything important in SharePoint.
- **Single platform from v1.** No phased rollout where employee features come later. Parent-facing and employee-facing are equal first-class citizens in v1.

### 1.5 Soft constraints (preferences)
- TypeScript over JavaScript
- Hono for routing (already in package.json)
- Server-rendered HTML (Hono JSX) over client-side React for v1 — accessibility is much easier to guarantee with server rendering, and we want every page to work without JavaScript
- HTMX or minimal JS for interactivity. No SPA framework in v1.
- All forms work without JavaScript enabled. JS is progressive enhancement only.

---

## 2. Architecture overview

### 2.1 Resources (already provisioned)

| Resource | Name | ID |
|---|---|---|
| GitHub repo | `ramonscottf/dsd-flyers` | — |
| D1 (prod) | `dsd-flyers` | `5b5de1d1-ca4a-4e27-bad5-f0a071a75b58` |
| D1 (dev) | `dsd-flyers-dev` | `2c95fbe9-ed47-4099-8b39-d7bbc6a873a5` |
| R2 bucket | `dsd-flyers-assets` | — |
| KV | `dsd-flyers-kv` | `72249a65614a42f987b766e8ee616f68` |
| Vectorize index | `dsd-flyers-search` | 768-dim, cosine, bge-base-en-v1.5 |
| Cloudflare zone | daviskids.org | `e9aac6e9fab72eae9eda35335bc47f40` |
| Worker route | `daviskids.org/flyers/*` | configured in wrangler.toml |

The Worker handles `/flyers` and `/flyers/*`. Everything else on `daviskids.org` continues to be served by the existing `def-site` Cloudflare Pages deployment. No changes to that deployment.

### 2.2 Worker bindings

```typescript
interface Env {
  DB: D1Database;            // dsd-flyers / dsd-flyers-dev
  ASSETS: R2Bucket;          // dsd-flyers-assets (PDFs, images)
  KV: KVNamespace;           // sessions, rate limits, audit cache
  VECTORIZE: VectorizeIndex; // semantic search
  AI: Ai;                    // embeddings + reading-level analysis
  BROWSER: Fetcher;          // axe-core HTML accessibility scans
  // + secrets and vars (see wrangler.toml)
}
```

### 2.3 Request flow

```
Parent visits daviskids.org/flyers/farmington-elementary/spring-fling
         |
         v
Cloudflare Worker (dsd-flyers) catches /flyers/*
         |
         +--- Public read paths: serve cached HTML from KV (5 min TTL)
         |     If miss: query D1, render Hono JSX, cache in KV
         |
         +--- Authenticated paths (/flyers/admin, /flyers/submit): verify session
         |     - Cookie -> KV session lookup -> user record from D1
         |
         +--- Asset paths (/flyers/asset/<id>): R2 public read with content-type
         |
         +--- API paths (/flyers/api/*): JSON responses
         |
         +--- Submit/upload: POST to D1 + R2, kick off a11y audit (Browser Rendering)
```

### 2.4 Why this architecture
- **D1 + R2 + KV** is the same stack we use across all our DSD/DEF projects (CTE Scholarships, Child Spree). Operationally familiar.
- **Server-rendered HTML** because (a) accessibility is easier, (b) SEO matters for daviskids.org, (c) email digests can render the same templates server-side, (d) we keep the bundle tiny.
- **Vectorize for search** because keyword search alone misses "looking for the science fair flyer" when the flyer is titled "STEM Showcase 2026". Semantic search is a low-cost feature that destroys Peachjar's UX.
- **Browser Rendering for accessibility audits** because it lets us run real axe-core scans inside a Worker without standing up separate infrastructure.

---

## 3. Data model

The full schema is in `schema.sql` and is already applied to both D1 databases. The seed data (69 schools, 10 departments) is already loaded. **Do not modify the schema without coordinating** — make a `migrations/` directory if you need to evolve it during the build.

### 3.1 Key entity relationships

```
users (auth) -- school_admins / department_admins -- schools / departments
                                                          |
                                                          v
                             flyers ---- flyer_schools / flyer_departments
                              | |
                              | +--- flyer_revisions (audit history)
                              | +--- accessibility_audits (a11y scan results)
                              | +--- analytics_events (views, clicks)
                              |
                              v
                       Vectorize search_vector_id

users / anonymous email --- subscriptions (per-school, per-category, frequency)
                                  |
                                  v
                            deliveries (every email/SMS sent)
```

### 3.2 Status lifecycle for `flyers`

```
draft -> pending_review -> approved -> published -> expired
                       \-> rejected (with rejected_reason)
                                  -> archived (manual)
```

- **draft** — submitter is still editing. Not visible to anyone except the submitter.
- **pending_review** — submitted; awaiting school/district admin approval.
- **approved** — passed review, will auto-publish at a scheduled time (or immediately if `published_at` <= now).
- **published** — visible to the public.
- **expired** — past `expires_at`. Auto-transitioned by a scheduled task (Cron Trigger). Still visible in archive views, but excluded from default browse and digests.
- **rejected** — admin sent it back with feedback. Submitter can revise and resubmit.
- **archived** — manually moved to long-term storage. Not visible in default views.

### 3.3 Conventions
- **All timestamps are unix epoch seconds** (`INTEGER`). Use `Math.floor(Date.now() / 1000)`.
- **All IDs are UUIDs (v4)** except for `schools`, `departments`, and lookup tables which use human-readable slugs.
- **All JSON columns** (tags, snapshots, findings) use `TEXT` and are parsed/stringified in app code.

---

## 4. API surface

All routes are prefixed with `/flyers`. The Worker route catches `daviskids.org/flyers/*`.

### 4.1 Public (no auth required for parents; SSO required for employee view)

The two-door pattern: `/flyers` (or `/flyers/parents`) is the parent-facing front door; `/flyers/employees` is the employee-facing front door. Same backend, same flyer pool, just filtered by audience.

| Method | Path | Purpose |
|---|---|---|
| GET | `/flyers` | Default landing — same as `/flyers/parents`. Decision rationale: most traffic will be parents, so parent view is the default. |
| GET | `/flyers/parents` | Parent-facing flyer browse. Shows flyers where `audience IN ('parents', 'both')` and `status = 'published'`. No auth required. |
| GET | `/flyers/employees` | Employee-facing browse. Shows flyers where `audience IN ('employees', 'both')` and `status = 'published'`. **Requires employee SSO** (verifies `is_employee = 1`). |
| GET | `/flyers/school/<school-id>` | All published flyers for a school, filtered by current audience context |
| GET | `/flyers/category/<category>` | All published flyers in a category, filtered by audience |
| GET | `/flyers/<flyer-slug>` | Single flyer detail page. If audience is `employees` only, requires employee SSO; otherwise public. |
| GET | `/flyers/asset/<r2-key>` | Public image/PDF fetch from R2 |
| GET | `/flyers/api/health` | Health check (already implemented in scaffold) |
| GET | `/flyers/api/search?q=<query>&audience=<aud>` | Semantic search (Vectorize) + keyword fallback, audience-filtered |
| GET | `/flyers/feeds/<school-id>.rss` | RSS feed per school (parents-audience by default; ?audience=employees requires auth) |
| GET | `/flyers/feeds/<school-id>.ics` | iCal feed of events from school's flyers |
| POST | `/flyers/api/subscribe` | Subscribe to digest (email or SMS); audience captured at signup |
| GET | `/flyers/unsubscribe/<token>` | Unsubscribe page (token-based, no login) |
| GET | `/flyers/manage/<token>` | Manage subscription preferences (token-based, no login) |
| GET | `/flyers/auth/login` | Login page (provider chooser) |
| GET | `/flyers/auth/<provider>` | Initiate OAuth (microsoft, google, apple) |
| GET | `/flyers/auth/<provider>/callback` | OAuth callback |
| POST | `/flyers/auth/magic` | Request magic link |
| GET | `/flyers/auth/magic/<token>` | Consume magic link |
| POST | `/flyers/auth/logout` | Logout |
| GET | `/flyers/api/event/track` | 1x1 pixel for email open tracking + click redirect |

### 4.2 Authenticated submitter

| Method | Path | Purpose |
|---|---|---|
| GET | `/flyers/submit` | Submission form |
| POST | `/flyers/submit` | Create draft |
| GET | `/flyers/my` | My submissions |
| GET | `/flyers/my/<id>/edit` | Edit my draft or rejected flyer |
| POST | `/flyers/my/<id>/edit` | Save edit |
| POST | `/flyers/my/<id>/submit` | Move draft to pending_review |
| POST | `/flyers/my/<id>/withdraw` | Withdraw a pending submission |
| POST | `/flyers/api/upload/image` | Upload decorative image (returns R2 key) |
| POST | `/flyers/api/upload/pdf` | Upload PDF (returns R2 key, kicks off a11y audit) |
| GET | `/flyers/api/audit/<flyer-id>` | Poll for a11y audit results |
| GET | `/flyers/api/reading-level` | Analyze pasted text for reading level (live preview) |

### 4.3 School / department admin

| Method | Path | Purpose |
|---|---|---|
| GET | `/flyers/admin` | Admin dashboard (their school/dept queue) |
| GET | `/flyers/admin/queue` | Pending review list |
| GET | `/flyers/admin/<flyer-id>` | Review a specific flyer |
| POST | `/flyers/admin/<flyer-id>/approve` | Approve and publish (or schedule) |
| POST | `/flyers/admin/<flyer-id>/reject` | Reject with reason |
| POST | `/flyers/admin/<flyer-id>/edit` | Make edit on behalf of submitter (auditable) |
| GET | `/flyers/admin/analytics` | School-level analytics |

### 4.4 District admin

| Method | Path | Purpose |
|---|---|---|
| GET | `/flyers/admin/district` | District-wide dashboard |
| GET | `/flyers/admin/district/users` | Manage admins and roles |
| POST | `/flyers/admin/district/users/grant` | Grant role |
| POST | `/flyers/admin/district/users/revoke` | Revoke role |
| GET | `/flyers/admin/district/analytics` | District-wide analytics |
| GET | `/flyers/admin/district/audit-log` | Admin action audit log |
| GET | `/flyers/admin/district/cost-savings` | "vs Peachjar" running counter (for the pitch) |
| GET | `/flyers/admin/district/imports` | List parent contact imports |
| POST | `/flyers/admin/district/imports` | Upload a CSV of parent emails to seed subscriptions |
| GET | `/flyers/admin/district/imports/<id>` | Detail view of a specific import (rows imported, skipped, failed) |
| POST | `/flyers/admin/district/imports/<id>/rollback` | Roll back an import (deactivate all subscriptions created by it) |

### 4.5 Response conventions

- HTML routes return server-rendered Hono JSX
- API routes return JSON with shape `{ ok: true, data: ... }` or `{ ok: false, error: string, code?: string }`
- Error responses use proper HTTP status codes (400, 401, 403, 404, 422, 500)
- Rate limit on auth endpoints: 5/min per IP; on submit: 10/hour per user; tracked in KV

---

## 5. User flows

### 5.1 Parent browsing flyers (the most common path)

1. Parent lands on `daviskids.org/flyers` (no login required)
2. Sees a hero with "Browse by your school" prompt — search bar, school filter dropdown, category chips
3. If they have visited before with cookies, surfaces their previously-viewed schools at the top
4. Each flyer card shows: title, summary (1-2 sentence plain-language version), school badge, category badge, expiration indicator, accessible thumbnail (alt text always present)
5. Click into a flyer detail page: structured content as primary, image/PDF secondary
6. From any flyer page: "Subscribe to flyers from this school" button, "Add to calendar" button if event, "Share" link

**Critical:** Every flyer must be readable without JavaScript. Test this. The student/parent on a school Chromebook with strict policies needs this to work.

### 5.2 School staff submitting a flyer

1. Staff visits `/flyers/submit`
2. If not logged in: provider chooser (Microsoft for `dsdmail.net` accounts, Google, Apple, magic link fallback)
3. After auth: the submission form
4. Form fields:
    - **Title** (required, 100 char max)
    - **Plain-language summary** (required, 280 char max — like a tweet for a flyer; live counter)
    - **Full content** (required, rich text editor with restrictive options — paragraphs, headings, lists, links only; live reading-level meter showing target ≤ 6th grade)
    - **Audience** (required: parents / employees / both)
    - **Schools** (required if scope is school or multi_school; checklist with search)
    - **Departments** (only shown if audience includes employees)
    - **Category** (required dropdown)
    - **Tags** (optional, free-form, comma-separated)
    - **Event details** (only if category is event: start, end, location)
    - **Expiration date** (required, defaults to 30 days from today, max 1 year)
    - **Optional decorative image** (uploader; alt text REQUIRED if image is uploaded)
    - **Optional PDF attachment** (uploader; warns user that PDF must pass a11y audit)
5. Live preview pane on the right — shows how the flyer will render to a parent
6. "Save draft" / "Submit for review"
7. If submit: a11y audit runs on PDF if present (async); user sees "submitted, audit in progress" and can navigate away
8. Once audit completes:
    - If pass: status is `pending_review`, school admin gets notification
    - If fail: status reverts to `draft`, user gets specific feedback ("table on page 2 is not tagged", "image on page 1 is missing alt text") with link to fix

### 5.3 School admin reviewing a flyer

1. Admin sees badge in nav with pending count
2. Goes to `/flyers/admin/queue`
3. Reviews list with: title, submitter, school, audience, submission time, a11y status (pass/fail/pending)
4. Click into a flyer: full preview, audit report, "Approve and publish now", "Approve and schedule for…", "Reject with reason", "Edit on behalf of submitter"
5. On approve: flyer goes live; subscribers matching audience criteria get queued for digest delivery
6. On reject: submitter notified by email with the reason; flyer goes back to `draft` so they can revise

### 5.4 Subscriber (parent or employee) signing up for digests

1. From any flyer page or the index, click "Get email updates"
2. Modal/page: enter email, choose schools (default: all), categories (default: all), frequency (instant / daily / weekly), opt-in checkbox
3. Verification email sent immediately
4. Click link in verification email → subscription activated
5. Manage at `/flyers/manage?token=<unsubscribe_token>` (no login needed; token-based)
6. Unsubscribe is one click, no friction. Required for CAN-SPAM compliance.

---

## 6. Accessibility requirements (WCAG 2.1 AA)

This is the differentiator. Get this right or the project fails.

### 6.1 Platform UI requirements

**Every page must:**
- Have a unique, descriptive `<title>`
- Have proper landmark elements: `<header>`, `<main>`, `<nav>`, `<footer>`
- Use semantic HTML — `<button>` for actions, `<a>` for navigation, never `<div onclick>`
- Have a visible skip-to-main-content link as the first focusable element
- Have a focus state on every interactive element, with at least 3:1 contrast against adjacent colors
- Have all text at minimum 4.5:1 contrast against background (3:1 for large text)
- Be keyboard navigable end-to-end with visible focus indicators
- Have alt text on every image (decorative images get `alt=""`)
- Have form labels properly associated with inputs (`<label for>` or wrapping)
- Have form errors announced to screen readers via `aria-live` or `role="alert"`
- Use heading hierarchy correctly — exactly one `<h1>`, no skipped levels
- Set the `lang` attribute on `<html>` (default `en`, but should support translation in v2)
- Be readable at 200% zoom without horizontal scroll
- Not rely on color alone to convey information

**Forbidden patterns:**
- No `<div>` or `<span>` with click handlers
- No tooltips that disappear on hover-out before screen reader can read them
- No autoplay video
- No `aria-hidden` on focusable elements
- No positive `tabindex` values
- No fixed pixel sizes that break at zoom

### 6.2 Submitted flyer requirements

The submission flow enforces these on submit:
- **Title** must be present and ≤ 100 chars
- **Summary** must be present and ≤ 280 chars
- **Body content** must be present and parsed into valid semantic HTML (no `<style>`, no `<script>`, no inline `style=`, no positive `tabindex`)
- **Image alt text** is required if an image is uploaded; the form input is required
- **Reading level** (Flesch-Kincaid grade) is calculated on the body and shown to submitter; if > 6.0, surfaces a warning with simplification suggestions; admin sees this score during review
- **PDF** if uploaded gets scanned by Browser Rendering with axe-core (see §7); must pass before publish
- **Color contrast in body** — if the rich text editor allows custom colors (it shouldn't in v1, but if it does), validate contrast on save

### 6.3 Screen reader testing

Code: every page must be tested with at least one of: VoiceOver (macOS), NVDA (Windows), or TalkBack (Android). Document a quick test script in `docs/a11y-test.md`. Before declaring v1 done, the test script must pass on:
- Index page
- Single flyer page
- Submission form
- Admin review page
- Subscribe form

---

## 7. Accessibility audit pipeline

### 7.1 The flow

```
PDF uploaded -> R2 -> Worker enqueues audit -> Browser Rendering opens PDF
   -> axe-core injected -> findings returned -> stored in accessibility_audits
   -> score calculated -> flyer status updated
```

### 7.2 PDF audit specifics

PDFs are tricky because axe-core doesn't directly scan PDF format — it scans HTML. Two valid approaches:

**Approach A (preferred for v1):** Convert PDF to HTML using a library or Cloudflare R2 + a conversion step, then run axe-core on the HTML. This catches:
- Tagged structure presence
- Heading order
- Reading order
- Image alt text in the PDF
- Form field labels

**Approach B:** Use `pdf-lib` to inspect PDF metadata directly (tags, structure tree, alt text on image XObjects) and combine with a heuristic scoring system. Less rigorous but doesn't require browser conversion.

Code: start with Approach A using Browser Rendering. Render the PDF in a browser tab via PDF.js, then run axe-core on the rendered DOM. The PDF.js text layer gives us a queryable representation.

### 7.3 HTML audit (for the structured body content)

Run axe-core on the rendered preview before allowing publish. This catches:
- Missing alt text
- Bad heading order
- Insufficient contrast (with custom rules disabled — we don't render the user's CSS, so contrast is platform-determined)
- Empty links or buttons
- Improper landmarks

### 7.4 Scoring

```
score = 100 - (critical_count * 25) - (serious_count * 10) - (moderate_count * 3) - (minor_count * 1)
score = max(0, score)
passed = score >= A11Y_PASS_THRESHOLD  // env var, prod=85, dev=70
```

Findings stored as JSON:

```json
{
  "violations": [
    {
      "id": "image-alt",
      "impact": "critical",
      "help": "Images must have alternate text",
      "occurrences": 2,
      "page": 3,
      "suggestion": "Add alt text to image on page 3"
    }
  ],
  "passes": 47,
  "score": 88,
  "passed": true
}
```

### 7.5 User-facing feedback

When a PDF fails, the submitter sees a list like:

> Your PDF has accessibility issues:
>
> ❌ **Critical** — Image on page 3 has no alt text. (2 occurrences)
> ❌ **Critical** — Table on page 2 is not tagged. Screen readers cannot read it.
> ⚠ **Serious** — Heading order skips from H1 to H3 on page 1.
>
> [Learn how to fix these](#) · [Submit as text-only instead](#)

The "submit as text-only instead" option is critical — sometimes the right answer is "give up on the PDF, we have your structured content already, ship it without the PDF."

---

## 8. Email and SMS distribution

### 8.1 Provider choices

- **Email:** Resend (preferred — clean API, accessibility-friendly templates) or SendGrid as fallback
- **SMS:** Twilio (we already have the rails and an A2P 10DLC campaign in progress under Wicko brand)

### 8.2 Subscription model

Subscriptions are stored in `subscriptions` table with three possible **sources** (added in migration 001):

- **`self_signup`** — parent or employee signed up through the public form. Requires email verification (double opt-in for CAN-SPAM). Default frequency: weekly.
- **`district_import`** — bulk-imported from district SIS or other district-owned contact list. Treated as opted-in on import (legal under CAN-SPAM for district-internal communications), but every digest still includes one-click unsubscribe and a "manage your preferences" link. Default frequency: weekly. Default audience: parents (or employees if employee email).
- **`admin_added`** — manually added by an admin (rare, but supported for edge cases).

Subscription criteria:
- `school_ids` — JSON array of school IDs to receive flyers from (null = all)
- `categories` — JSON array of categories (null = all)
- `audience` — `parents` or `employees` (each subscription is for one audience; if a user is both, they get two subscriptions)
- `digest_frequency` — `instant` (per flyer), `daily`, `weekly`, `never` (paused)
- `delivery` — `email`, `sms`, or `both` (SMS only available if `phone` is set)

### 8.3 Parent contact import flow (district-owned data)

The district has the parent contact graph. We import it; we do not lease it from a vendor.

The import flow (district admin only):

1. District admin uploads a CSV with required columns: `email`, `first_name`, `last_name`. Optional columns: `school_id` (which school the parent's student attends), `student_grade`, `phone`.
2. The Worker validates the CSV: email format, school_id exists in `schools` table, etc.
3. For each valid row:
   - Look up by email — if a `subscriptions` row already exists, skip (track as "skipped").
   - Otherwise insert a new subscription with `source = 'district_import'`, `import_id = <new contact_imports.id>`, `verified = 1`, `active = 1`, `audience = 'parents'`, `digest_frequency = 'weekly'`, `school_ids = [<school_id>]` if provided.
4. Track results in `contact_imports` table: total, imported, skipped, failed.
5. The first digest these subscribers receive includes a clear "you're receiving this because the Davis School District has your email on file. [Manage preferences] [Unsubscribe]" header.
6. **Rollback support**: if an import was a mistake, district admin can roll it back from `/flyers/admin/district/imports/<id>` — sets `active = 0` on every subscription with that `import_id`. Reversible if needed.

### 8.4 SMS subscriber growth (organic only)

We do NOT bulk-import phone numbers. SMS subscribers come exclusively from:
- Self-signup on the subscribe form (parent or employee opts in by entering their phone)
- Adding phone to an existing email subscription via the manage page

This keeps us TCPA-compliant and avoids the "got a text I didn't ask for" complaint that destroys text channels.

The platform tracks SMS subscriber growth as an explicit metric on the district analytics dashboard. This is a multi-month organic build, not a v1 feature gate.

### 8.5 Digest scheduling

A Cron Trigger runs every hour:
- For `instant` subscribers: send any approved flyers since `last_sent_at` matching their criteria
- For `daily` subscribers: at a configurable hour per timezone (default 7am MT for parents, 8am MT for employees), send the past 24 hours' approved flyers
- For `weekly` subscribers: Monday 7am MT, send the past 7 days

Digests are bundled per recipient, not per flyer — one email with multiple flyers, never spam.

### 8.6 Email template requirements

- Plain text alternative always included
- All images have alt text in HTML version
- Single-column layout, no tables for layout
- 14px+ body text, 1.5 line height
- High-contrast CTA buttons
- Footer with: physical address (CAN-SPAM), unsubscribe link, "manage preferences" link, district contact info
- For `district_import` subscribers: a clear opening line on their FIRST digest stating "You are receiving this because the Davis School District has your email on file."
- Open tracking via 1x1 pixel pointing at `/flyers/api/event/track`
- Click tracking via redirect URLs

### 8.7 SMS templates

- Max 160 chars
- Format: `[School Name]: <flyer title>. <short link>. Reply STOP to opt out.`
- Short links via Cloudflare or a simple D1 lookup table — no third-party shorteners (data ownership)
- Frequency caps: never more than 1 SMS per recipient per day, even if multiple flyers match. Bundle into "[School]: 3 new flyers. <link>"

---

## 9. Admin dashboards and analytics

### 9.1 School admin dashboard (`/flyers/admin`)

Top of page:
- Pending review count (large, clickable)
- This week: flyers published, parent reach, employee reach, accessibility issues caught
- Quick actions: "New flyer," "Review queue," "Subscribers"

Tabs:
- **Queue** — pending flyers with batch actions
- **Published** — recently published, with click-through stats per flyer
- **Drafts** — staff drafts in progress
- **Analytics** — see §9.3

### 9.2 District admin dashboard (`/flyers/admin/district`)

Same as school but cross-school, plus:
- User management (grant/revoke roles)
- Audit log (who approved what, who edited what)
- "vs Peachjar" running counter (see §9.4)
- System health (delivery rates, audit failure rate, etc.)

### 9.3 Analytics

Per flyer:
- Views (unique sessions)
- Click-throughs from email/SMS digests
- PDF downloads (if PDF attached)
- Share clicks
- Subscribe-from-this-flyer count

Per school:
- Total flyers published
- Average reach per flyer
- Subscriber count
- Top-performing flyers

District-level:
- Total flyers across district, by category, by audience
- Subscriber growth over time
- Email delivery rate, open rate, click rate
- Accessibility audit pass rate over time
- Cost savings vs Peachjar

### 9.4 The "vs Peachjar" counter (pitch ammunition)

This is critical for the superintendent meeting. We need a hard number.

Display on district admin dashboard:
- "Peachjar would have charged: $X this month / $Y year-to-date"
- "Cost to operate dsd-flyers: $Z this month / $W year-to-date"
- "Net savings: $X-Z this month / $Y-W YTD"

For the calculation, we need real Peachjar pricing. **Code: build a configurable input on the dashboard for the per-flyer-or-annual rate so the district admin can plug in their actual contract numbers.** Default to a placeholder ("$X to be confirmed") until we have real numbers.

---

## 10. Branding and design system

### 10.1 Visual identity

- **Match daviskids.org existing styles** — same primary brand color, typography, spacing
- **Higher accessibility bar** than the parent site — but don't introduce visual inconsistency
- The Worker should fetch the daviskids.org header/footer once per cache window and inject them so the chrome matches automatically. If that's too brittle, hand-code a simplified version of the daviskids.org header/footer that we update quarterly.

### 10.2 Design tokens

```css
:root {
  --color-primary: #1e40af;       /* DSD blue */
  --color-primary-hover: #1e3a8a;
  --color-text: #1a202c;          /* almost black, max contrast */
  --color-text-muted: #4b5563;
  --color-bg: #ffffff;
  --color-bg-muted: #f8fafc;
  --color-border: #e2e8f0;
  --color-success: #047857;
  --color-warning: #b45309;
  --color-error: #b91c1c;
  --color-info: #1e40af;

  --font-body: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
  --font-heading: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;

  --space-xs: 0.25rem;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --space-lg: 1.5rem;
  --space-xl: 2.5rem;

  --radius: 6px;
  --radius-lg: 12px;

  --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
  --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1);

  --max-width: 72rem;
  --content-width: 42rem;
}
```

All contrast pairs in this palette have been verified for WCAG AA compliance against white and against `--color-text`. Code: add a CI check that validates token contrast on every commit.

### 10.3 Components needed

- `<Button>` — variants: primary, secondary, ghost, destructive
- `<Card>` — flyer card and admin item card
- `<Input>`, `<Textarea>`, `<Select>`, `<Checkbox>`, `<Radio>` — all with labels and error states
- `<FileUpload>` — drag-drop with keyboard support, alt-text-required modal for images
- `<Alert>` — info, success, warning, error
- `<Badge>` — for school name, category, audience, a11y status
- `<Pagination>` — accessible cursor-based
- `<DateInput>` — native `<input type="date">` plus picker fallback
- `<RichTextEditor>` — minimal toolbar (B, I, H2, H3, ul, ol, link); wraps a `contenteditable` and emits validated HTML; live reading-level meter

---

## 11. Testing requirements

### 11.1 Automated

- **Unit tests** with Vitest for: parsers, validators, reading-level calculator, slug generator, audit scorer
- **Integration tests** for: auth flows, submission, approval, digest generation
- **a11y tests** with `@axe-core/playwright` against rendered HTML for: index, flyer page, submit form, admin queue
- **CI** on every PR: type check, lint, unit + integration tests, a11y check

### 11.2 Manual

- VoiceOver smoke test on macOS Safari (5 critical pages)
- NVDA smoke test on Windows Firefox/Chrome (same 5 pages)
- Keyboard-only navigation walkthrough (no mouse, complete a full submission)
- Mobile screen reader test (TalkBack on Android Chrome)
- 200% zoom test in Chrome and Firefox
- High contrast mode test (Windows)
- Color-blindness simulation (Chrome devtools rendering)

### 11.3 Acceptance criteria for v1 ship

- [ ] Public can browse `/flyers/parents` and read every parent flyer without JS, without auth
- [ ] Employees can sign in and access `/flyers/employees` to see employee-targeted flyers
- [ ] A flyer with `audience = 'both'` appears in both views simultaneously
- [ ] Submitter can sign in with at least magic link (SSO if at least one provider is configured)
- [ ] Submitter can create a draft, save, edit, submit for review
- [ ] Submitter selects audience at submission time (parents / employees / both) and platform respects it
- [ ] PDF upload triggers a11y audit; failure feedback is specific and actionable
- [ ] School admin can review and approve/reject from the queue
- [ ] District admin can grant/revoke school admin roles
- [ ] District admin can upload a parent contact CSV and seed subscriptions
- [ ] District admin can roll back a contact import
- [ ] Approved flyers are visible publicly within 30 seconds
- [ ] Subscribe-by-email works end-to-end (verification → digest delivery)
- [ ] District-imported subscribers receive their first digest with the proper "you are receiving this because…" notice
- [ ] Unsubscribe works in one click for both self-signups and district-imports
- [ ] All 5 critical pages pass automated a11y check
- [ ] Manual screen reader smoke test passes on all 5 critical pages
- [ ] Digest cron runs successfully in dev, sends real emails to a test mailbox
- [ ] "vs Peachjar" counter is visible to district admin (even with placeholder rate)
- [ ] At least one pilot school has been onboarded with at least 3 real flyers
- [ ] At least one pilot department has posted at least 1 employee-only flyer (proves the unified platform end-to-end)
- [ ] README and `docs/operating.md` are written so a new admin can be onboarded without us

---

## 12. Deployment and rollback

### 12.1 Environments
- **Production:** `dsd-flyers` Worker, deployed to `daviskids.org/flyers/*`
- **Development:** `dsd-flyers-dev` Worker, deployed to `dsd-flyers-dev.fosterlabs.workers.dev`

### 12.2 Deploy flow
- Push to `dev` branch → auto-deploy to dev environment
- Push to `main` → auto-deploy to prod
- Cloudflare GitHub integration handles both
- For manual deploys: `npm run deploy:dev` or `npm run deploy`

### 12.3 Rollback
- Cloudflare Workers keeps a deployment history. To rollback: `wrangler rollback <deployment-id>` or via dashboard
- D1 changes are forward-only. **Never destructive migrations on prod** — always additive (new columns, new tables). If a column needs to be removed, plan a 2-step migration: deprecate → wait → remove.
- KV is a cache; flushing on rollback is fine: `wrangler kv:bulk delete --binding=KV --all`

### 12.4 Secrets management
- Production secrets: `wrangler secret put <NAME>` against the prod environment
- Dev secrets: `wrangler secret put <NAME> --env dev`
- Local dev: use `.dev.vars` file (gitignored)
- Never commit secrets. Rotate immediately if exposed.

---

## 13. What is OUT of scope for v1

Resist scope creep. These are explicitly NOT v1:
- Translation / multi-language support (English only)
- Push notifications (email + SMS only)
- Native mobile apps
- Calendar integration with Google/Outlook (RSS/iCal feeds only)
- AI-generated alt text suggestions (we may add this — but require human review)
- Per-school custom branding (one platform brand for v1)
- Two-factor auth (SSO providers handle MFA themselves)
- Comments or reactions on flyers
- Print layout templates
- Video flyers / multimedia attachments beyond PDF + image
- Analytics export to PDF (analytics dashboard is enough)
- Public API for third parties
- Pulling old flyers out of Peachjar (no migration FROM Peachjar — only forward; existing Peachjar flyers stay there until they expire)
- Bulk SMS import (organic opt-in only)

---

## 14. Definition of done (v1)

The build is "done" when ALL of the following are true:

1. All acceptance criteria in §11.3 pass
2. README and operating docs are complete enough that someone unfamiliar can run a school admin onboarding
3. The pilot school is live with real flyers
4. The accessibility audit pipeline catches at least one real failure during the pilot (proves it's not vaporware)
5. The "vs Peachjar" counter has at least placeholder numbers wired in
6. The deck has slides 4-6 with real screenshots from the live system

After that, hand back to Skippy for refinement, deck assembly, and pitch prep.

---

## 15. Open questions and decisions still needed

These are tracked in GitHub issues. Code: do not block on them — proceed with reasonable defaults and we will refine.

- Exact Peachjar contract terms (annual cost, renewal date, notice required) — pitch input
- DSDads details — is it a contract with Peachjar or a separate vendor? Cost?
- Pilot school identity — Skippy and Scott will identify within first week
- Pilot department — at least one DSD department needs to volunteer to post employee flyers via the new system during the pilot
- DEF vs DSD ownership of the IP — affects open-source decisions and licensing to other Utah districts
- Microsoft Azure AD app registration — Skippy will register the app; Code uses the credentials
- Final brand sign-off — Karah has approval authority
- Format of the parent contact CSV the district will provide — Code: build the importer to accept the most common SIS export columns (`email`, `first_name`, `last_name`, `school_id`/`school_code`/`school_name`, `student_grade`, `phone`); if other columns appear, log and ignore.

**Resolved decisions (do not relitigate):**
- ✅ Single platform, parents and employees both v1
- ✅ Lives at `daviskids.org/flyers`, not a subdomain
- ✅ District owns the parent contact list and will provide it for import
- ✅ SMS subscribers grow only through self-signup (no bulk import)
- ✅ Auth: Microsoft + Google + Apple SSO + magic link fallback

---

## 16. How to ask Skippy for help

If Code gets stuck:
1. Document the question in a GitHub issue with the `question:skippy` label
2. Include: what you were trying to do, what blocked you, what options you considered, your recommendation
3. If urgent, drop a comment in the v1 build PR

For decisions that don't change the spec, just decide and note it in `docs/decisions.md`. We can refine later.

---

**End of plan.** Build with confidence. We are the only ADA-compliant flyer platform in the state when this ships.
