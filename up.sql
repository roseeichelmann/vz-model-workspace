-- ROAD TYPE LOOKUP
CREATE TABLE public.road_type_lkp (
    id integer PRIMARY KEY,
    description text
);

INSERT INTO public.road_type_lkp (id, description) values (1, 'alley');
INSERT INTO public.road_type_lkp (id, description) values (2, 'collector');
INSERT INTO public.road_type_lkp (id, description) values (3, 'arterial');
INSERT INTO public.road_type_lkp (id, description) values (4, 'highway');
INSERT INTO public.road_type_lkp (id, description) values (5, 'other');

-- UNIT TYPE LOOKUP
CREATE TABLE public.unit_type_lkp (
    id integer PRIMARY KEY,
    description text
);

INSERT INTO public.unit_type_lkp (id, description) values (1, 'vehicle');
INSERT INTO public.unit_type_lkp (id, description) values (2, 'pedestrian');
INSERT INTO public.unit_type_lkp (id, description) values (3, 'motorcycle');
INSERT INTO public.unit_type_lkp (id, description) values (4, 'spaceship');
INSERT INTO public.unit_type_lkp (id, description) values (5, 'bicycle');
INSERT INTO public.unit_type_lkp (id, description) values (6, 'other');

-- CRASHES
CREATE TABLE public.cris_crashes (
    crash_id integer PRIMARY KEY,
    latitude double precision,
    longitude double precision,
    primary_address text,
    road_type_id integer REFERENCES public.road_type_lkp ON DELETE RESTRICT ON UPDATE RESTRICT
);
    
CREATE TABLE public.crashes (
    crash_id integer PRIMARY KEY,
    latitude double precision,
    longitude double precision,
    primary_address text,
    road_type_id integer REFERENCES public.road_type_lkp ON DELETE RESTRICT ON UPDATE RESTRICT,
    vz_location_id text,
    vz_unique_unit_types integer ARRAY
);

-- UNITS
CREATE TABLE public.cris_units (
    unit_id SERIAL PRIMARY KEY,
    crash_id integer NOT NULL REFERENCES public.cris_crashes ON DELETE CASCADE ON UPDATE CASCADE,
    unit_type_id integer REFERENCES public.unit_type_lkp ON DELETE RESTRICT ON UPDATE RESTRICT
);

CREATE TABLE public.units (
    unit_id SERIAL PRIMARY KEY,
    crash_id integer NOT NULL REFERENCES public.crashes ON DELETE CASCADE ON UPDATE CASCADE,
    unit_type_id integer REFERENCES public.unit_type_lkp ON DELETE RESTRICT ON UPDATE RESTRICT
);

-- LOCATIONS
CREATE TABLE public.locations (
    location_id character varying PRIMARY KEY,
    description text NOT NULL,
    address text,
    last_update date DEFAULT now() NOT NULL,
    is_retired boolean DEFAULT false NOT NULL,
    is_studylocation boolean DEFAULT false NOT NULL,
    priority_level integer DEFAULT 0 NOT NULL,
    shape public.geometry(MultiPolygon,4326),
    latitude double precision,
    longitude double precision,
    scale_factor double precision,
    geometry public.geometry(MultiPolygon,4326),
    unique_id character varying,
    asmp_street_level integer,
    road integer,
    intersection integer,
    spine public.geometry(MultiLineString,4326),
    overlapping_geometry public.geometry(MultiPolygon,4326),
    intersection_union integer DEFAULT 0,
    broken_out_intersections_union integer DEFAULT 0,
    road_name character varying(512),
    level_1 integer DEFAULT 0,
    level_2 integer DEFAULT 0,
    level_3 integer DEFAULT 0,
    level_4 integer DEFAULT 0,
    level_5 integer DEFAULT 0,
    street_level character varying(16),
    is_intersection integer DEFAULT 0 NOT NULL,
    is_svrd integer DEFAULT 0 NOT NULL,
    council_district integer,
    non_cr3_report_count integer,
    cr3_report_count integer,
    total_crash_count integer,
    total_comprehensive_cost integer,
    total_speed_mgmt_points numeric(6,2) DEFAULT NULL::numeric,
    non_injury_count integer DEFAULT 0 NOT NULL,
    unknown_injury_count integer DEFAULT 0 NOT NULL,
    possible_injury_count integer DEFAULT 0 NOT NULL,
    non_incapacitating_injury_count integer DEFAULT 0 NOT NULL,
    suspected_serious_injury_count integer DEFAULT 0 NOT NULL,
    death_count integer DEFAULT 0 NOT NULL,
    crash_history_score numeric(4,2) DEFAULT NULL::numeric,
    sidewalk_score integer,
    bicycle_score integer,
    transit_score integer,
    community_dest_score integer,
    minority_score integer,
    poverty_score integer,
    community_context_score integer,
    total_cc_and_history_score numeric(4,2) DEFAULT NULL::numeric,
    is_intersecting_district integer DEFAULT 0,
    polygon_id character varying(16),
    signal_engineer_area_id integer,
    development_engineer_area_id integer,
    polygon_hex_id character varying(16),
    location_group smallint DEFAULT 0
);

-- TRIGGERS

-- Trigger on insert to cris table

-- order of these triggers will depend on how cris data is inserted into the db - are crashes first or units?
CREATE OR REPLACE FUNCTION public.copy_crash_on_cris_insert()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$function$
DECLARE uniq_unit_types integer ARRAY;
begin
    SELECT ARRAY(SELECT DISTINCT units.unit_type_id into uniq_unit_types from units where crash_id = NEW.crash_id);
  INSERT INTO public.crashes(
    crash_id,
    latitude,
    longitude,
    primary_address,
    road_type_id,
    vz_unique_unit_types
  )
  VALUES (
    NEW.crash_id,
    NEW.latitude,
    NEW.longitude,
    NEW.primary_address,
    NEW.road_type_id,
    uniq_unit_types
  );
  RETURN NEW;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.copy_unit_on_cris_insert()
    RETURNS TRIGGER
    LANGUAGE plpgsql
AS
$function$
begin
  INSERT INTO public.units(
    unit_id,
    crash_id,
    unit_type_id
  )
  VALUES (
    NEW.unit_id,
    NEW.crash_id,
    NEW.unit_type_id
  );
  RETURN NEW;
end;
$function$
;

CREATE OR REPLACE TRIGGER copy_crash_on_cris_insert
    AFTER INSERT ON public.cris_crashes FOR EACH ROW EXECUTE FUNCTION public.copy_crash_on_cris_insert();

CREATE OR REPLACE TRIGGER copy_unit_on_cris_insert
    AFTER INSERT ON public.cris_units FOR EACH ROW EXECUTE FUNCTION public.copy_unit_on_cris_insert();

-- Trigger for location_id

-- This trigger function updates the location_id of a record in atd_txdot_crashes on insert or update.
CREATE OR REPLACE FUNCTION public.update_crash_location_id()
    RETURNS TRIGGER AS $$
    BEGIN
        -- Return the location id of the crash by finding which location polygon the crash
        -- geographic position resides in
        NEW.vz_location_id = (
            SELECT location_id 
            FROM locations 
            WHERE (geometry && ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326))
            AND ST_Contains(geometry, ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326))
            LIMIT 1 --TODO: This should be temporary until we get our polygons in order
        );
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_crash_location_id
    BEFORE INSERT OR UPDATE ON public.crashes FOR EACH ROW EXECUTE FUNCTION public.update_crash_location_id();

-- Trigger for vz_unique_unit_types

CREATE OR REPLACE FUNCTION public.update_unique_unit_types()
    RETURNS TRIGGER AS $$
    DECLARE uniq_unit_types integer ARRAY;
    BEGIN
        SELECT ARRAY(SELECT DISTINCT units.unit_type_id from units where crash_id = NEW.crash_id) into uniq_unit_types;
        UPDATE public.crashes SET vz_unique_unit_types = uniq_unit_types where crash_id = NEW.crash_id;
        RETURN NEW;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_unique_unit_types
    AFTER INSERT OR UPDATE ON public.units FOR EACH ROW EXECUTE FUNCTION public.update_unique_unit_types();
