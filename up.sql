-- CRASHES
CREATE TABLE public.cris_crashes (
    crash_id integer PRIMARY KEY,
    address_confirmed_primary text,
    latitude double precision,
    longitude double precision,
    road_type_id integer
);
    
CREATE TABLE public.crashes (
    crash_id integer PRIMARY KEY,
    address_confirmed_primary text,
    latitude double precision,
    longitude double precision,
    road_type_id integer,
    vz_location_id text,
    vz_unique_unit_types integer ARRAY,
);

-- UNITS
CREATE TABLE public.cris_units (
    crash_id integer NOT NULL REFERENCES public.cris_crashes ON DELETE CASCADE ON UPDATE CASCADE,
    unit_nbr integer NOT NULL,
    unit_desc_id integer,
    PRIMARY KEY(crash_id, unit_nbr)
);

CREATE TABLE public.units (
    crash_id integer NOT NULL REFERENCES public.crashes ON DELETE CASCADE ON UPDATE CASCADE,
    unit_nbr integer NOT NULL,
    unit_desc_id integer,
    PRIMARY KEY(crash_id, unit_nbr)

);

-- LOCATIONS
CREATE TABLE public.locations (
    location_id character varying NOT NULL,
    description text NOT NULL,
    address text,
    metadata json,
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

-- ROAD TYPE LOOKUP
CREATE TABLE public.road_type_lkp (
    road_type_id integer NOT NULL,
    road_type_desc character varying(128),
    eff_beg_date character varying(32),
    eff_end_date character varying(32)
);

-- UNIT LOOKUP
CREATE TABLE public.unit_desc_lkp (
    unit_desc_id integer NOT NULL,
    unit_desc_desc character varying(128),
    eff_beg_date character varying(32),
    eff_end_date character varying(32)
);
