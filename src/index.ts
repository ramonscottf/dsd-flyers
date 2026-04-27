/**
 * DSD Flyers — Davis School District Flyers Platform
 *
 * This is a SCAFFOLD. Code: replace this with the full implementation
 * per IMPLEMENTATION_PLAN.md.
 *
 * The placeholder route below proves the deployment works at
 * daviskids.org/flyers — confirm the route is hitting this Worker
 * before doing anything else.
 */

import { Hono } from 'hono';

export interface Env {
  DB: D1Database;
  ASSETS: R2Bucket;
  KV: KVNamespace;
  VECTORIZE: VectorizeIndex;
  AI: Ai;
  BROWSER: Fetcher;

  // Vars
  ENVIRONMENT: string;
  PUBLIC_BASE_URL: string;
  ALLOWED_EMAIL_DOMAINS: string;
  EMPLOYEE_EMAIL_DOMAIN: string;
  MAGIC_LINK_TTL_MINUTES: string;
  SESSION_TTL_DAYS: string;
  TARGET_READING_GRADE: string;
  A11Y_PASS_THRESHOLD: string;

  // Secrets (set via wrangler secret put)
  MICROSOFT_CLIENT_ID?: string;
  MICROSOFT_CLIENT_SECRET?: string;
  MICROSOFT_TENANT_ID?: string;
  GOOGLE_CLIENT_ID?: string;
  GOOGLE_CLIENT_SECRET?: string;
  APPLE_CLIENT_ID?: string;
  APPLE_TEAM_ID?: string;
  APPLE_KEY_ID?: string;
  APPLE_PRIVATE_KEY?: string;
  RESEND_API_KEY?: string;
  TWILIO_ACCOUNT_SID?: string;
  TWILIO_AUTH_TOKEN?: string;
  TWILIO_FROM_NUMBER?: string;
  SESSION_SECRET?: string;
}

const app = new Hono<{ Bindings: Env }>();

// Health check
app.get('/flyers/api/health', async (c) => {
  // Verify DB connection
  try {
    const result = await c.env.DB.prepare('SELECT COUNT(*) as count FROM schools').first();
    return c.json({
      status: 'ok',
      environment: c.env.ENVIRONMENT,
      timestamp: new Date().toISOString(),
      schools_count: result?.count ?? 0,
    });
  } catch (err) {
    return c.json(
      {
        status: 'error',
        error: err instanceof Error ? err.message : String(err),
      },
      500,
    );
  }
});

// Placeholder homepage — REPLACE with the real flyers index per implementation plan
app.get('/flyers', async (c) => {
  return c.html(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Flyers — Davis School District</title>
  <meta name="description" content="Davis School District Flyers platform — coming soon. Replacing Peachjar with an ADA-compliant, district-owned flyer distribution system.">
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
      max-width: 720px;
      margin: 0 auto;
      padding: 2rem 1.25rem;
      color: #1a202c;
      line-height: 1.6;
    }
    h1 { color: #1e40af; margin-top: 0; }
    .badge {
      display: inline-block;
      background: #fef3c7;
      color: #92400e;
      padding: 0.25rem 0.75rem;
      border-radius: 9999px;
      font-size: 0.875rem;
      font-weight: 600;
      margin-bottom: 1rem;
    }
    .hero {
      background: #f0f9ff;
      border-left: 4px solid #1e40af;
      padding: 1.5rem;
      border-radius: 4px;
      margin: 1.5rem 0;
    }
    code {
      background: #f1f5f9;
      padding: 0.125rem 0.375rem;
      border-radius: 4px;
      font-size: 0.875rem;
    }
    a {
      color: #1e40af;
      text-decoration: underline;
    }
    a:focus { outline: 2px solid #1e40af; outline-offset: 2px; }
    footer {
      margin-top: 3rem;
      padding-top: 1.5rem;
      border-top: 1px solid #e2e8f0;
      font-size: 0.875rem;
      color: #64748b;
    }
  </style>
</head>
<body>
  <main>
    <span class="badge">Coming Soon</span>
    <h1>Flyers</h1>
    <p>The Davis School District is building a new home for school and district flyers — built right here, for you, accessible to everyone.</p>

    <div class="hero">
      <p><strong>Why we are building this:</strong> Every flyer that goes out from Davis schools should be readable by every parent, every teacher, every student — including those who use screen readers, magnifiers, or assistive technology. The new Flyers system makes that the default, not an afterthought.</p>
    </div>

    <p>This page is a placeholder while we build. Have questions? Contact your school or the Davis Education Foundation.</p>

    <p><a href="https://daviskids.org/">Return to daviskids.org</a></p>
  </main>

  <footer>
    <p>Davis School District · Farmington, Utah · <code>${c.env.ENVIRONMENT}</code></p>
  </footer>
</body>
</html>`);
});

app.get('/flyers/*', async (c) => {
  return c.text('Flyers — coming soon. (Path placeholder)', 200);
});

export default app;
