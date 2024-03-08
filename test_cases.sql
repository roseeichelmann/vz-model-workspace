-- 1. CRIS user creates a crash record with two unit records

INSERT INTO public.cris_crashes(crash_id, latitude, longitude, primary_address, road_type_id) values (2000000, 30.48501694, -97.72865645, '1234 hello world ave', 3);
INSERT INTO public.cris_units(crash_id, unit_type_id) values (2000000, 3);
INSERT INTO public.cris_units(crash_id, unit_type_id) values (2000000, 5);

-- 2. VZ user changes a crash’s Location ID by updating the crash lat/lon

create or replace procedure vz_update_latlon (id integer, lat double precision, long double precision) language plpgsql as 
$$
declare old_location text;
declare new_location text;
begin 
    raise notice 'VZ user updating lat/long of crash_id %', id;
    SELECT INTO old_location vz_location_id FROM public.crashes WHERE crash_id = id;
    UPDATE public.crashes SET latitude = lat, longitude = long WHERE crash_id = id;
    SELECT INTO new_location vz_location_id FROM public.crashes WHERE crash_id = id;
    raise notice 'Location updated from % to %', old_location, new_location;
end;
$$;

CALL vz_update_latlon(1, 30.434043190707328, -97.70021501519273);
CALL vz_update_latlon(1, 30.31860473, -97.62621625);

-- 3. VZ user edits a unit type

UPDATE public.units SET unit_type_id = 6 WHERE unit_id = 1;

create or replace procedure vz_update_unit_type (id integer, unit_type integer) language plpgsql as 
$$
declare old_unit_type text;
declare new_unit_type text;
begin 
    raise notice 'VZ user updating unit type of unit id %', id;
    SELECT INTO old_unit_type unit_type_id FROM public.units WHERE unit_id = id;
    UPDATE public.units SET unit_type_id = unit_type WHERE unit_id = id;
    SELECT INTO new_unit_type unit_type_id FROM public.units WHERE unit_id = id;
    raise notice 'Unit type updated from % to %', old_unit_type, new_unit_type;
end;
$$;

CALL vz_update_unit_type(1, 6);

-- 4. CRIS user updates the crash lat/lon, and road type

create or replace procedure cris_update_latlon (id integer, lat double precision, long double precision, road_type integer) language plpgsql as 
$$
begin 
    raise notice 'CRIS user updating lat/long of crash_id % to %,% and road type to %', id, lat, long, road_type;
    UPDATE public.cris_crashes SET latitude = lat, longitude = long, road_type_id = road_type WHERE crash_id = 2;
end;
$$;

CALL cris_update_latlon(2, 30.47371683, -97.6891157, 4);

-- 5. CRIS user updates a unit type

create or replace procedure cris_update_unit (id integer, unit_type integer) language plpgsql as 
$$
begin 
    raise notice 'CRIS user updating unit type of unit_id % to %', id, unit_type;
    UPDATE public.cris_units set unit_type_id = unit_type WHERE unit_id = id;
end;
$$;

CALL cris_update_unit(2, 1);

-- 6. VZ user adds a custom lookup value and uses it

INSERT INTO public.unit_type_lkp(id, description) values (11111, 'scooter');
UPDATE public.units set unit_type_id = 11111 WHERE unit_id = 2;

-- 7. Create a query that demonstrates the correct source of truth when crashes and units have edits from both CRIS and the VZ user

SELECT * FROM public.cris_units WHERE unit_id = 2;
SELECT * FROM public.units WHERE unit_id = 2;

SELECT * FROM public.cris_crashes WHERE crash_id = 2;
SELECT * FROM public.crashes WHERE crash_id = 2;

-- 8. Query for a single crash by ID

SELECT * FROM public.crashes WHERE crash_id = 100;

-- 9. Query for a large number of crashes

SELECT * FROM public.crashes LIMIT 100;

-- 10. Create a query/view that powers a simplified version of the locations table, for example by calculating total number of units per location (for reference see: locations_with_crash_injury_counts in the DB)

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

-- 11. Create a test case, or simply write out the steps that would be involved if we wanted to add a new editable column to crashes

ALTER TABLE public.crashes ADD COLUMN vz_law_enforcement_num integer;
UPDATE TABLE public.crashes SET vz_law_enforcement_num = 1 WHERE crash_id = 1;

-- 12. [Optional] Create a test case or simply describe the mechanism to support a conflict management system as described in the functional requirements.

