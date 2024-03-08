-- CRIS user creates a crash record with two unit records

INSERT INTO public.cris_crashes(crash_id, latitude, longitude, primary_address, road_type_id) values (2000000, 30.48501694, -97.72865645, '1234 hello world ave', 3);
INSERT INTO public.cris_units(crash_id, unit_type_id) values (2000000, 3);
INSERT INTO public.cris_units(crash_id, unit_type_id) values (2000000, 5);

-- VZ user changes a crash’s Location ID by updating the crash lat/lon

UPDATE public.crashes SET latitude = 30.19850686, longitude = -97.76400348 WHERE crash_id = 1;
UPDATE public.crashes SET latitude = 30.31860473, longitude = -97.62621625 WHERE crash_id = 1;

-- VZ user edits a unit type

UPDATE public.units SET unit_type_id = 6 WHERE unit_id = 1;

-- CRIS user updates the crash lat/lon, and road type

UPDATE public.cris_crashes SET latitude = 30.47371683, longitude = -97.6891157, road_type_id = 4 WHERE crash_id = 2;

-- CRIS user updates a unit type

UPDATE public.cris_units set unit_type_id = 1 WHERE unit_id = 2;

-- VZ user adds a custom lookup value and uses it

INSERT INTO public.unit_type_lkp(id, description) values (11111, 'scooter');
UPDATE public.units set unit_type_id = 11111 WHERE unit_id = 2;

-- Create a query that demonstrates the correct source of truth when crashes and units have edits from both CRIS and the VZ user

SELECT * FROM public.cris_units WHERE unit_id = 2;
SELECT * FROM public.units WHERE unit_id = 2;

SELECT * FROM public.cris_crashes WHERE crash_id = 2;
SELECT * FROM public.crashes WHERE crash_id = 2;

-- Query for a single crash by ID

SELECT * FROM public.crashes WHERE crash_id = 100;

-- Query for a large number of crashes

SELECT * FROM public.crashes LIMIT 100;

-- Create a query/view that powers a simplified version of the locations table, for example by calculating total number of units per location (for reference see: locations_with_crash_injury_counts in the DB)

CREATE OR REPLACE VIEW public.locations_with_crash_unit_counts AS
WITH crashes AS (
  SELECT crashes.vz_location_id,
      count(DISTINCT crashes.crash_id) AS crash_count,
      count(units.unit_id) AS unit_count
      FROM crashes
        LEFT JOIN units ON units.crash_id = crashes.crash_id
    WHERE true AND crashes.vz_location_id IS NOT NULL
    GROUP BY crashes.vz_location_id
)
  SELECT locations.description,
  locations.location_id,
  COALESCE(crashes.crash_count, 0) AS crash_count,
  COALESCE(crashes.unit_count) AS unit_count
   FROM locations
     LEFT JOIN crashes ON locations.location_id::text = crashes.vz_location_id::text
  WHERE locations.location_group = 1;

SELECT * FROM public.locations_with_crash_unit_counts;

-- Create a test case, or simply write out the steps that would be involved if we wanted to add a new editable column to crashes

ALTER TABLE public.crashes ADD COLUMN vz_law_enforcement_num integer;
UPDATE TABLE public.crashes SET vz_law_enforcement_num = 1 WHERE crash_id = 1;


-- [Optional] Create a test case or simply describe the mechanism to support a conflict management system as described in the functional requirements.

