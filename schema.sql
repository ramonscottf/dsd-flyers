-- DSD Flyers Database Schema
-- Davis School District Flyers Platform
-- Schema version: 1.0
-- Last updated: 2026-04-27

-- ============================================================
-- USERS & AUTH
-- ============================================================

CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,                    -- UUID
  email TEXT NOT NULL UNIQUE,
  display_name TEXT,
  auth_provider TEXT,                     -- 'microsoft' | 'google' | 'apple' | 'magic_link'
  provider_user_id TEXT,                  -- ID from the SSO provider
  is_employee INTEGER DEFAULT 0,          -- 1 if @dsdmail.net domain
  is_district_admin INTEGER DEFAULT 0,    -- super-admin role
  created_at INTEGER NOT NULL,            -- unix timestamp
  last_login INTEGER,
  last_active INTEGER
);

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_provider ON users(auth_provider, provider_user_id);

-- Magic link tokens
CREATE TABLE IF NOT EXISTS magic_links (
  token TEXT PRIMARY KEY,
  email TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  used_at INTEGER,
  ip_address TEXT
);

CREATE INDEX IF NOT EXISTS idx_magic_links_email ON magic_links(email);
CREATE INDEX IF NOT EXISTS idx_magic_links_expires ON magic_links(expires_at);

-- Active sessions (also mirrored in KV for fast lookup)
CREATE TABLE IF NOT EXISTS sessions (
  id TEXT PRIMARY KEY,                    -- session token
  user_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  expires_at INTEGER NOT NULL,
  user_agent TEXT,
  ip_address TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_sessions_user ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_expires ON sessions(expires_at);

-- ============================================================
-- SCHOOLS & ORG STRUCTURE
-- ============================================================

CREATE TABLE IF NOT EXISTS schools (
  id TEXT PRIMARY KEY,                    -- e.g. 'farmington-elementary'
  name TEXT NOT NULL,                     -- 'Farmington Elementary'
  short_name TEXT,                        -- 'Farmington'
  level TEXT NOT NULL,                    -- 'elementary' | 'junior' | 'high' | 'district'
  address TEXT,
  phone TEXT,
  website TEXT,
  active INTEGER DEFAULT 1,
  display_order INTEGER DEFAULT 100,
  created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_schools_level ON schools(level);
CREATE INDEX IF NOT EXISTS idx_schools_active ON schools(active);

-- School-level admin permissions
CREATE TABLE IF NOT EXISTS school_admins (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  school_id TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'editor',    -- 'editor' | 'approver' | 'admin'
  created_at INTEGER NOT NULL,
  created_by TEXT,                        -- user_id who granted
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (school_id) REFERENCES schools(id),
  UNIQUE(user_id, school_id)
);

CREATE INDEX IF NOT EXISTS idx_school_admins_user ON school_admins(user_id);
CREATE INDEX IF NOT EXISTS idx_school_admins_school ON school_admins(school_id);

-- Departments (for employee-side flyers — DSDads replacement)
CREATE TABLE IF NOT EXISTS departments (
  id TEXT PRIMARY KEY,                    -- e.g. 'comms', 'hr', 'cte'
  name TEXT NOT NULL,
  description TEXT,
  active INTEGER DEFAULT 1,
  created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS department_admins (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  department_id TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'editor',
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (department_id) REFERENCES departments(id),
  UNIQUE(user_id, department_id)
);

-- ============================================================
-- FLYERS (CORE ENTITY)
-- ============================================================

CREATE TABLE IF NOT EXISTS flyers (
  id TEXT PRIMARY KEY,                    -- UUID
  slug TEXT NOT NULL UNIQUE,              -- URL-friendly slug
  title TEXT NOT NULL,
  summary TEXT NOT NULL,                  -- 1-2 sentence summary, parent-readable
  body_html TEXT NOT NULL,                -- The full structured content as accessible HTML
  body_plain TEXT NOT NULL,               -- Same content as plain text (for screen readers, search)
  reading_level REAL,                     -- Flesch-Kincaid grade level (target: <= 6.0)
  word_count INTEGER,

  -- Audience targeting
  audience TEXT NOT NULL,                 -- 'parents' | 'employees' | 'both'
  scope TEXT NOT NULL,                    -- 'school' | 'multi_school' | 'department' | 'district'

  -- Categorization
  category TEXT NOT NULL,                 -- 'event' | 'fundraiser' | 'announcement' | 'club' | 'sports' | 'academic' | 'community' | 'health' | 'other'
  tags TEXT,                              -- JSON array of free-form tags

  -- Lifecycle
  status TEXT NOT NULL DEFAULT 'draft',   -- 'draft' | 'pending_review' | 'approved' | 'published' | 'expired' | 'rejected' | 'archived'
  published_at INTEGER,                   -- when it actually went live
  expires_at INTEGER NOT NULL,            -- required expiration date
  event_start_at INTEGER,                 -- if it's an event flyer
  event_end_at INTEGER,
  event_location TEXT,

  -- Optional visual
  image_r2_key TEXT,                      -- R2 path for decorative image
  image_alt_text TEXT,                    -- REQUIRED if image_r2_key is set
  image_width INTEGER,
  image_height INTEGER,

  -- Optional PDF (must pass a11y audit before publish)
  pdf_r2_key TEXT,
  pdf_a11y_score INTEGER,                 -- 0-100, from automated audit
  pdf_a11y_passed INTEGER DEFAULT 0,      -- 1 if it passes our threshold
  pdf_a11y_report TEXT,                   -- JSON of findings

  -- Submission metadata
  submitted_by TEXT NOT NULL,
  submitted_at INTEGER NOT NULL,
  approved_by TEXT,
  approved_at INTEGER,
  rejected_reason TEXT,

  -- Search & optimization
  search_vector_id TEXT,                  -- ID in the Vectorize index

  -- Audit
  updated_at INTEGER NOT NULL,
  version INTEGER DEFAULT 1,

  FOREIGN KEY (submitted_by) REFERENCES users(id),
  FOREIGN KEY (approved_by) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_flyers_slug ON flyers(slug);
CREATE INDEX IF NOT EXISTS idx_flyers_status ON flyers(status);
CREATE INDEX IF NOT EXISTS idx_flyers_audience ON flyers(audience);
CREATE INDEX IF NOT EXISTS idx_flyers_published ON flyers(published_at);
CREATE INDEX IF NOT EXISTS idx_flyers_expires ON flyers(expires_at);
CREATE INDEX IF NOT EXISTS idx_flyers_category ON flyers(category);
CREATE INDEX IF NOT EXISTS idx_flyers_event_start ON flyers(event_start_at);

-- Many-to-many: which schools/departments a flyer is associated with
CREATE TABLE IF NOT EXISTS flyer_schools (
  flyer_id TEXT NOT NULL,
  school_id TEXT NOT NULL,
  PRIMARY KEY (flyer_id, school_id),
  FOREIGN KEY (flyer_id) REFERENCES flyers(id) ON DELETE CASCADE,
  FOREIGN KEY (school_id) REFERENCES schools(id)
);

CREATE INDEX IF NOT EXISTS idx_flyer_schools_school ON flyer_schools(school_id);

CREATE TABLE IF NOT EXISTS flyer_departments (
  flyer_id TEXT NOT NULL,
  department_id TEXT NOT NULL,
  PRIMARY KEY (flyer_id, department_id),
  FOREIGN KEY (flyer_id) REFERENCES flyers(id) ON DELETE CASCADE,
  FOREIGN KEY (department_id) REFERENCES departments(id)
);

CREATE INDEX IF NOT EXISTS idx_flyer_departments_dept ON flyer_departments(department_id);

-- ============================================================
-- FLYER REVISIONS (audit history)
-- ============================================================

CREATE TABLE IF NOT EXISTS flyer_revisions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  flyer_id TEXT NOT NULL,
  version INTEGER NOT NULL,
  snapshot TEXT NOT NULL,                 -- JSON snapshot of the flyer at this version
  changed_by TEXT NOT NULL,
  changed_at INTEGER NOT NULL,
  change_note TEXT,
  FOREIGN KEY (flyer_id) REFERENCES flyers(id) ON DELETE CASCADE,
  FOREIGN KEY (changed_by) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_flyer_revisions_flyer ON flyer_revisions(flyer_id);

-- ============================================================
-- ACCESSIBILITY AUDIT LOG
-- ============================================================

CREATE TABLE IF NOT EXISTS accessibility_audits (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  flyer_id TEXT NOT NULL,
  audit_type TEXT NOT NULL,               -- 'pdf' | 'html' | 'image_alt'
  score INTEGER,                          -- 0-100
  passed INTEGER DEFAULT 0,
  findings TEXT,                          -- JSON array of issues
  audited_at INTEGER NOT NULL,
  audited_version INTEGER NOT NULL,
  FOREIGN KEY (flyer_id) REFERENCES flyers(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_a11y_audits_flyer ON accessibility_audits(flyer_id);

-- ============================================================
-- SUBSCRIPTIONS (parents/employees subscribing to schools/categories)
-- ============================================================

CREATE TABLE IF NOT EXISTS subscriptions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT,                           -- nullable for anonymous email-only subs
  email TEXT NOT NULL,                    -- always present
  audience TEXT NOT NULL,                 -- 'parents' | 'employees'

  -- What they want
  school_ids TEXT,                        -- JSON array of school IDs (or null = all)
  department_ids TEXT,                    -- JSON array (or null = all, employees only)
  categories TEXT,                        -- JSON array (or null = all)

  -- How often
  digest_frequency TEXT NOT NULL DEFAULT 'weekly', -- 'instant' | 'daily' | 'weekly' | 'never'
  delivery TEXT NOT NULL DEFAULT 'email', -- 'email' | 'sms' | 'both'
  phone TEXT,                             -- if SMS

  -- State
  active INTEGER DEFAULT 1,
  verified INTEGER DEFAULT 0,
  verification_token TEXT,
  unsubscribe_token TEXT NOT NULL,

  created_at INTEGER NOT NULL,
  last_sent_at INTEGER,
  last_opened_at INTEGER,

  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_subs_email ON subscriptions(email);
CREATE INDEX IF NOT EXISTS idx_subs_audience ON subscriptions(audience);
CREATE INDEX IF NOT EXISTS idx_subs_active ON subscriptions(active);
CREATE INDEX IF NOT EXISTS idx_subs_unsub ON subscriptions(unsubscribe_token);

-- ============================================================
-- DELIVERY LOG (every email/SMS we send)
-- ============================================================

CREATE TABLE IF NOT EXISTS deliveries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  subscription_id INTEGER,
  flyer_id TEXT,                          -- nullable for digests covering multiple
  channel TEXT NOT NULL,                  -- 'email' | 'sms'
  recipient TEXT NOT NULL,
  subject TEXT,
  status TEXT NOT NULL,                   -- 'queued' | 'sent' | 'delivered' | 'opened' | 'clicked' | 'bounced' | 'failed'
  provider_message_id TEXT,
  sent_at INTEGER,
  delivered_at INTEGER,
  opened_at INTEGER,
  clicked_at INTEGER,
  error TEXT,
  FOREIGN KEY (subscription_id) REFERENCES subscriptions(id),
  FOREIGN KEY (flyer_id) REFERENCES flyers(id)
);

CREATE INDEX IF NOT EXISTS idx_deliveries_sub ON deliveries(subscription_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_flyer ON deliveries(flyer_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_status ON deliveries(status);
CREATE INDEX IF NOT EXISTS idx_deliveries_sent ON deliveries(sent_at);

-- ============================================================
-- ANALYTICS EVENTS
-- ============================================================

CREATE TABLE IF NOT EXISTS analytics_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_type TEXT NOT NULL,               -- 'view' | 'click' | 'share' | 'pdf_open' | 'subscribe' | 'unsubscribe'
  flyer_id TEXT,
  user_id TEXT,                           -- nullable for anonymous
  session_id TEXT,                        -- for unique-visitor counting
  referrer TEXT,
  user_agent TEXT,
  country TEXT,
  created_at INTEGER NOT NULL,
  metadata TEXT,                          -- JSON for event-specific data
  FOREIGN KEY (flyer_id) REFERENCES flyers(id)
);

CREATE INDEX IF NOT EXISTS idx_events_flyer ON analytics_events(flyer_id);
CREATE INDEX IF NOT EXISTS idx_events_type ON analytics_events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_created ON analytics_events(created_at);

-- ============================================================
-- AUDIT LOG (admin actions)
-- ============================================================

CREATE TABLE IF NOT EXISTS admin_audit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT NOT NULL,
  action TEXT NOT NULL,                   -- 'approve' | 'reject' | 'edit' | 'delete' | 'grant_role' | 'revoke_role'
  target_type TEXT NOT NULL,              -- 'flyer' | 'user' | 'school' | 'subscription'
  target_id TEXT NOT NULL,
  before_state TEXT,                      -- JSON
  after_state TEXT,                       -- JSON
  ip_address TEXT,
  created_at INTEGER NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_audit_user ON admin_audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_target ON admin_audit_log(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_audit_created ON admin_audit_log(created_at);
