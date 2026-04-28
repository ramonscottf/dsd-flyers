# Decisions log

Running log of decisions that affect the build. Code: when you make a decision that doesn't change the spec, append it here. Skippy: when you resolve an open question, update the relevant section of `IMPLEMENTATION_PLAN.md` AND add a one-line entry here.

Format: `YYYY-MM-DD — short title — outcome (optionally why)`.

---

## 2026-04-27

- **Single platform, parents and employees both v1** — no phased rollout. Audience flag handles the targeting.
- **Lives at `daviskids.org/flyers`** — Worker-on-path beats subdomain because it stays inside the daviskids brand. Pages site continues to serve everything else.
- **Auth: Microsoft + Google + Apple SSO + magic link fallback** — daviskids.org Azure tenant already whitelisted at the tenant level (Child Spree's blocker is app-specific, not tenant-wide).
- **District owns the parent contact graph** — we import it on day one of the pilot. No Peachjar data extraction needed.
- **SMS subscribers grow only through self-signup** — no bulk import, TCPA-clean.
- **Peachjar is cancellable at any time** — no contract timing pressure on the pitch. We pitch when ready.
- **DSDads is not a vendor** — it's just internal email blasts today. We're not displacing a contract; we're displacing an ad-hoc workflow with zero compliance controls. The pitch beat: "your employee comms have NO audit trail and NO accessibility check today; Flyers fixes that on day one."
- **Pilot lead: Scott** — DEF marketing role + Wicko build seat means Scott posts the pilot flyers himself. No principal coordination required. Onboarding a separate pilot principal is post-pitch.
- **DEF owns the IP** — this is a DEF product, not a DSD product. DSD becomes the first deployment, but the platform is licensable to other Utah district foundations.
- **CSV import format** — `email`, `first_name`, `last_name`, `school` (or school_id/code), `grade`. Migration 002 adds `student_grades`, `parent_first_name`, `parent_last_name` to `subscriptions`.
- **Default frequency for district-imported subs** — `weekly`. Override available per import.
- **Compliance training reference** — the April 2026 DSD accessibility training (Brady + Range presenting) is the source-of-truth on what the district considers ADA-compliant. Specifically: image-with-adjacent-text is the only legal pattern; PDF tables are the riskiest single thing; SharePoint files are forbidden; custom URLs in Thrillshare are the one good pattern. Flyers is built to honor all of this by default.
