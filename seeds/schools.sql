-- DSD Schools seed data
-- Source: Davis School District directory + DonorsChoose listing
-- Last updated: 2026-04-27
-- Note: Code should verify and supplement this list against the official directory at davis.k12.ut.us
-- Schools may have been added/closed since this snapshot.

-- DISTRICT-LEVEL ENTITY (for district-wide announcements)
INSERT OR REPLACE INTO schools (id, name, short_name, level, active, display_order, created_at)
VALUES ('district', 'Davis School District', 'District-Wide', 'district', 1, 0, 1761609600);

-- ELEMENTARY SCHOOLS
INSERT OR REPLACE INTO schools (id, name, short_name, level, active, display_order, created_at) VALUES
  ('adams-elementary', 'Adams Elementary School', 'Adams', 'elementary', 1, 100, 1761609600),
  ('adelaide-elementary', 'Adelaide Elementary School', 'Adelaide', 'elementary', 1, 100, 1761609600),
  ('antelope-elementary', 'Antelope Elementary School', 'Antelope', 'elementary', 1, 100, 1761609600),
  ('bluff-ridge-elementary', 'Bluff Ridge Elementary School', 'Bluff Ridge', 'elementary', 1, 100, 1761609600),
  ('boulton-elementary', 'Boulton Elementary School', 'Boulton', 'elementary', 1, 100, 1761609600),
  ('bountiful-elementary', 'Bountiful Elementary School', 'Bountiful', 'elementary', 1, 100, 1761609600),
  ('buffalo-point-elementary', 'Buffalo Point Elementary School', 'Buffalo Point', 'elementary', 1, 100, 1761609600),
  ('burton-elementary', 'H.C. Burton Elementary School', 'Burton', 'elementary', 1, 100, 1761609600),
  ('canyon-creek-elementary', 'Canyon Creek Elementary School', 'Canyon Creek', 'elementary', 1, 100, 1761609600),
  ('centerville-elementary', 'Centerville Elementary School', 'Centerville', 'elementary', 1, 100, 1761609600),
  ('clinton-elementary', 'Clinton Elementary School', 'Clinton', 'elementary', 1, 100, 1761609600),
  ('columbia-elementary', 'Columbia Elementary School', 'Columbia', 'elementary', 1, 100, 1761609600),
  ('cook-elementary', 'Cook Elementary School', 'Cook', 'elementary', 1, 100, 1761609600),
  ('creekside-elementary', 'Creekside Elementary School', 'Creekside', 'elementary', 1, 100, 1761609600),
  ('crestview-elementary', 'Crestview Elementary School', 'Crestview', 'elementary', 1, 100, 1761609600),
  ('doxey-elementary', 'Doxey Elementary School', 'Doxey', 'elementary', 1, 100, 1761609600),
  ('eagle-bay-elementary', 'Eagle Bay Elementary School', 'Eagle Bay', 'elementary', 1, 100, 1761609600),
  ('east-layton-elementary', 'East Layton Elementary School', 'East Layton', 'elementary', 1, 100, 1761609600),
  ('ellison-park-elementary', 'Ellison Park Elementary School', 'Ellison Park', 'elementary', 1, 100, 1761609600),
  ('endeavour-elementary', 'Endeavour Elementary School', 'Endeavour', 'elementary', 1, 100, 1761609600),
  ('farmington-elementary', 'Farmington Elementary School', 'Farmington', 'elementary', 1, 100, 1761609600),
  ('foxboro-elementary', 'Foxboro Elementary School', 'Foxboro', 'elementary', 1, 100, 1761609600),
  ('heritage-elementary', 'Heritage Elementary School', 'Heritage', 'elementary', 1, 100, 1761609600),
  ('hill-field-elementary', 'Hill Field Elementary School', 'Hill Field', 'elementary', 1, 100, 1761609600),
  ('holbrook-elementary', 'Holbrook Elementary School', 'Holbrook', 'elementary', 1, 100, 1761609600),
  ('holt-elementary', 'Holt Elementary School', 'Holt', 'elementary', 1, 100, 1761609600),
  ('island-view-elementary', 'Island View Elementary', 'Island View', 'elementary', 1, 100, 1761609600),
  ('ja-taylor-elementary', 'J.A. Taylor Elementary School', 'J.A. Taylor', 'elementary', 1, 100, 1761609600),
  ('kays-creek-elementary', 'Kay''s Creek Elementary School', 'Kay''s Creek', 'elementary', 1, 100, 1761609600),
  ('kaysville-elementary', 'Kaysville Elementary School', 'Kaysville', 'elementary', 1, 100, 1761609600),
  ('king-elementary', 'King Elementary School', 'King', 'elementary', 1, 100, 1761609600),
  ('knowlton-elementary', 'Knowlton Elementary School', 'Knowlton', 'elementary', 1, 100, 1761609600),
  ('lakeside-elementary', 'Lakeside Elementary School', 'Lakeside', 'elementary', 1, 100, 1761609600),
  ('layton-elementary', 'Layton Elementary School', 'Layton', 'elementary', 1, 100, 1761609600),
  ('leo-j-muir-elementary', 'Leo J Muir Elementary School', 'Leo J Muir', 'elementary', 1, 100, 1761609600),
  ('lincoln-elementary', 'Lincoln Elementary School', 'Lincoln', 'elementary', 1, 100, 1761609600),
  ('meadowbrook-elementary', 'Meadowbrook Elementary School', 'Meadowbrook', 'elementary', 1, 100, 1761609600),
  ('morgan-elementary', 'Morgan Elementary School', 'Morgan', 'elementary', 1, 100, 1761609600),
  ('mountain-view-elementary', 'Mountain View Elementary School', 'Mountain View', 'elementary', 1, 100, 1761609600),
  ('oak-hills-elementary', 'Oak Hills Elementary School', 'Oak Hills', 'elementary', 1, 100, 1761609600),
  ('odyssey-elementary', 'Odyssey Elementary School', 'Odyssey', 'elementary', 1, 100, 1761609600),
  ('orchard-elementary', 'Orchard Elementary School', 'Orchard', 'elementary', 1, 100, 1761609600),
  ('parkside-elementary', 'Parkside Elementary School', 'Parkside', 'elementary', 1, 100, 1761609600),
  ('reading-elementary', 'Reading Elementary School', 'Reading', 'elementary', 1, 100, 1761609600),
  ('sand-springs-elementary', 'Sand Springs Elementary School', 'Sand Springs', 'elementary', 1, 100, 1761609600),
  ('snow-horse-elementary', 'Snow Horse Elementary School', 'Snow Horse', 'elementary', 1, 100, 1761609600),
  ('south-clearfield-elementary', 'South Clearfield Elementary', 'South Clearfield', 'elementary', 1, 100, 1761609600);

-- JUNIOR HIGH SCHOOLS
INSERT OR REPLACE INTO schools (id, name, short_name, level, active, display_order, created_at) VALUES
  ('bountiful-junior', 'Bountiful Junior High School', 'Bountiful JH', 'junior', 1, 200, 1761609600),
  ('centennial-junior', 'Centennial Junior High School', 'Centennial JH', 'junior', 1, 200, 1761609600),
  ('centerville-junior', 'Centerville Junior High School', 'Centerville JH', 'junior', 1, 200, 1761609600),
  ('central-davis-junior', 'Central Davis Junior High School', 'Central Davis JH', 'junior', 1, 200, 1761609600),
  ('fairfield-junior', 'Fairfield Junior High School', 'Fairfield JH', 'junior', 1, 200, 1761609600),
  ('horizon-junior', 'Horizon Junior High School', 'Horizon JH', 'junior', 1, 200, 1761609600),
  ('kaysville-junior', 'Kaysville Junior High School', 'Kaysville JH', 'junior', 1, 200, 1761609600),
  ('legacy-junior', 'Legacy Junior High School', 'Legacy JH', 'junior', 1, 200, 1761609600),
  ('millcreek-junior', 'Millcreek Junior High School', 'Millcreek JH', 'junior', 1, 200, 1761609600),
  ('mueller-park-junior', 'Mueller Park Junior High School', 'Mueller Park JH', 'junior', 1, 200, 1761609600),
  ('north-davis-junior', 'North Davis Junior High School', 'North Davis JH', 'junior', 1, 200, 1761609600),
  ('north-layton-junior', 'North Layton Junior High School', 'North Layton JH', 'junior', 1, 200, 1761609600),
  ('shoreline-junior', 'Shoreline Junior High School', 'Shoreline JH', 'junior', 1, 200, 1761609600);

-- HIGH SCHOOLS
INSERT OR REPLACE INTO schools (id, name, short_name, level, active, display_order, created_at) VALUES
  ('bountiful-high', 'Bountiful High School', 'Bountiful HS', 'high', 1, 300, 1761609600),
  ('clearfield-high', 'Clearfield High School', 'Clearfield HS', 'high', 1, 300, 1761609600),
  ('davis-high', 'Davis High School', 'Davis HS', 'high', 1, 300, 1761609600),
  ('layton-high', 'Layton High School', 'Layton HS', 'high', 1, 300, 1761609600),
  ('mountain-high', 'Mountain High School', 'Mountain HS', 'high', 1, 300, 1761609600),
  ('northridge-high', 'Northridge High School', 'Northridge HS', 'high', 1, 300, 1761609600),
  ('renaissance-academy', 'Davis High School Renaissance Academy', 'Renaissance Academy', 'high', 1, 300, 1761609600),
  ('viewmont-high', 'Viewmont High School', 'Viewmont HS', 'high', 1, 300, 1761609600);

-- DEPARTMENTS (for employee-side / DSDads replacement)
INSERT OR REPLACE INTO departments (id, name, description, active, created_at) VALUES
  ('comms', 'Communications', 'District-wide communications and marketing', 1, 1761609600),
  ('hr', 'Human Resources', 'HR announcements, benefits, training', 1, 1761609600),
  ('cte', 'Career & Technical Education', 'CTE programs, scholarships, partnerships', 1, 1761609600),
  ('it', 'Information Technology', 'IT updates, system notices', 1, 1761609600),
  ('food-services', 'Food Services', 'School lunch program, nutrition', 1, 1761609600),
  ('transportation', 'Transportation', 'Bus routes, schedules, driver communications', 1, 1761609600),
  ('teaching-learning', 'Teaching & Learning', 'Curriculum, professional development', 1, 1761609600),
  ('special-ed', 'Special Education', 'Special education programs and resources', 1, 1761609600),
  ('athletics', 'Athletics', 'District athletic programs', 1, 1761609600),
  ('foundation', 'Davis Education Foundation', 'DEF programs, fundraising, grants', 1, 1761609600);
