-- Migration 002: Student grade segmentation
-- Date: 2026-04-27
-- Purpose: District CSV will include student grade per parent record.
-- Allows future segment-by-grade digests (e.g. "K-3 only", "high school only").

ALTER TABLE subscriptions ADD COLUMN student_grades TEXT;
-- JSON array of grades the parent's student(s) are in, e.g. ["K","2","5"]
-- Null means no grade information / opted in to all

ALTER TABLE subscriptions ADD COLUMN parent_first_name TEXT;
ALTER TABLE subscriptions ADD COLUMN parent_last_name TEXT;
-- These help personalize digest emails ("Hi Sarah,") for district-imported subs
-- Optional — only populated when present in the import CSV

CREATE INDEX IF NOT EXISTS idx_subs_grades ON subscriptions(student_grades);
