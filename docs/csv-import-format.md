# Parent contact CSV import — format spec

The district will provide a CSV of parent contacts to seed the `subscriptions` table on day one of the pilot. The exact format from the SIS is TBD; this document specifies what the importer must accept.

## Required columns

The importer recognizes any of these header variations (case-insensitive, normalized):

| Logical field | Acceptable headers |
|---|---|
| Email | `email`, `email_address`, `parent_email`, `e-mail` |
| First name | `first_name`, `firstname`, `first`, `parent_first`, `parent_first_name` |
| Last name | `last_name`, `lastname`, `last`, `parent_last`, `parent_last_name`, `surname` |
| School | `school`, `school_name`, `school_id`, `school_code`, `student_school` |
| Grade | `grade`, `student_grade`, `grade_level` |

**Email is the only strictly required field.** First and last names enable personalization. School + grade enable per-school and per-grade-band digests. The importer logs and skips rows missing email.

## Optional columns

If present, these are stored:

| Logical field | Acceptable headers | Stored as |
|---|---|---|
| Phone | `phone`, `phone_number`, `mobile`, `cell` | `subscriptions.phone` (only used if parent later opts in to SMS) |
| Student first name | `student_first`, `student_first_name`, `child_first` | Logged in audit only — we don't store student data |
| Student last name | `student_last`, `student_last_name`, `child_last` | Logged in audit only |

**We do NOT store student names or other student PII in the subscriptions table.** Student grades and school assignments are stored as parent-level segmentation hints, never as individual student records.

## School matching

The importer maps the school field to a `schools.id` using:
1. Exact match on `id` (e.g. `farmington-elementary`)
2. Exact match on `name` (e.g. `Farmington Elementary School`)
3. Normalized match on `name` (lowercase, strip punctuation): `farmington elementary school`
4. Match on `short_name` (e.g. `Farmington`)
5. Fuzzy match (Levenshtein ≤ 2) — flagged for admin review before commit

Unmatched school values are logged as failures with a suggestion ("did you mean X?"). The admin can edit the CSV and re-import, or manually assign in the import review screen.

## Grade normalization

Acceptable grade values, normalized on import:

| Input | Stored |
|---|---|
| `K`, `k`, `Kindergarten`, `kindergarten`, `0` | `K` |
| `1`, `1st`, `First`, `1st Grade` | `1` |
| ... | ... |
| `12`, `12th`, `Senior` | `12` |
| `PK`, `Pre-K`, `Preschool` | `PK` |

Stored as a JSON array on `subscriptions.student_grades` so a parent with multiple students gets all their grades represented.

## Import process (admin POV)

1. District admin uploads CSV at `/flyers/admin/district/imports/new`
2. Worker streams the CSV row-by-row, validates each row, logs results to a staged session in KV
3. Admin sees a preview: "X rows will be imported, Y rows skipped (with reasons), Z rows failed"
4. Admin clicks "Confirm import" → rows committed to `subscriptions` with `source = 'district_import'`, `import_id = <new contact_imports.id>`
5. New `contact_imports` record stores: source label, file metadata, totals
6. Admin can roll back the entire import within 30 days from `/flyers/admin/district/imports/<id>` → flips `active = 0` on every row with that `import_id`

## Privacy and data retention

- Parent emails stay in `subscriptions` for as long as the subscription is active OR until rollback
- A FERPA review with the district legal team should happen before the first import. Code: surface a "FERPA review confirmed by [name] on [date]" requirement on the import confirmation screen so it's never bypassed.
- Student names from the CSV are logged in `contact_imports.raw_manifest` but NEVER stored in queryable form — they're only for audit reconciliation if a parent disputes their inclusion
- Phone numbers from the CSV are stored but NOT used for SMS until the parent self-opts-in via the manage page (TCPA compliance)

## Sample CSV (for testing)

```csv
email,first_name,last_name,school,grade,phone
parent1@example.com,Sarah,Johnson,Farmington Elementary,3,801-555-0101
parent2@example.com,Mike,Chen,Farmington Elementary,5,
parent3@example.com,Lisa,Davis,Davis High School,11,801-555-0103
parent4@example.com,Tom,Williams,kaysville-elementary,K,
```

Code: keep `seeds/sample-parent-import.csv` in the repo for testing. Generate it programmatically with realistic but obviously fake data (no real parent emails, no real phone numbers).
