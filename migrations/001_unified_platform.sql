-- Migration 001: Unified platform amendments
-- Date: 2026-04-27
-- Purpose: Reflect the single-platform decision (Flyers replaces both Peachjar
-- and DSDads). Adds parent contact import tracking and subscription source.

-- Source tracking on subscriptions
ALTER TABLE subscriptions ADD COLUMN source TEXT DEFAULT 'self_signup';
-- 'self_signup' | 'district_import' | 'admin_added'

ALTER TABLE subscriptions ADD COLUMN import_id INTEGER;
-- FK to contact_imports.id when source = 'district_import'

-- Track bulk parent contact imports from district SIS or other sources
CREATE TABLE IF NOT EXISTS contact_imports (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  source_label TEXT NOT NULL,           -- e.g. 'DSD SIS export Q1 2026'
  source_format TEXT,                   -- 'csv' | 'json' | 'sis_api'
  imported_by TEXT NOT NULL,            -- user_id of the admin who ran the import
  imported_at INTEGER NOT NULL,
  total_rows INTEGER,
  imported_rows INTEGER,                -- successfully imported
  skipped_rows INTEGER,                 -- duplicates, invalid emails, etc.
  failed_rows INTEGER,
  default_audience TEXT DEFAULT 'parents',
  default_frequency TEXT DEFAULT 'weekly',
  notes TEXT,
  raw_manifest TEXT,                    -- JSON metadata about the source file
  FOREIGN KEY (imported_by) REFERENCES users(id)
);

CREATE INDEX IF NOT EXISTS idx_contact_imports_at ON contact_imports(imported_at);
CREATE INDEX IF NOT EXISTS idx_subs_source ON subscriptions(source);
CREATE INDEX IF NOT EXISTS idx_subs_import ON subscriptions(import_id);
