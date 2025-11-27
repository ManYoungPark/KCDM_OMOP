-- ============================================================================
-- Script 02: Create OMOP CDM Tables
-- ============================================================================
-- Purpose: Create all required OMOP CDM v5.x tables
--          - Clinical data tables
--          - Health system data tables
--          - Vocabulary tables (references only)
--          - Metadata tables
-- ============================================================================
-- Prerequisites: Script 01 must be completed
-- Execution: Run this script SECOND
-- ============================================================================

\echo '============================================================================'
\echo 'OMOP CDM Conversion - Step 02: Create Tables'
\echo '============================================================================'

-- Load configuration
\i ../config.sql

-- ----------------------------------------------------------------------------
-- PERSON Table
-- ----------------------------------------------------------------------------
\echo 'Creating PERSON table...'

DROP TABLE IF EXISTS public.person CASCADE;

CREATE TABLE public.person (
    person_id BIGINT NOT NULL,
    gender_concept_id INTEGER NOT NULL,
    year_of_birth INTEGER NOT NULL,
    month_of_birth INTEGER NULL,
    day_of_birth INTEGER NULL,
    birth_datetime TIMESTAMP NULL,
    race_concept_id INTEGER NOT NULL,
    ethnicity_concept_id INTEGER NOT NULL,
    location_id INTEGER NULL,
    provider_id INTEGER NULL,
    care_site_id INTEGER NULL,
    person_source_value VARCHAR(50) NULL,
    gender_source_value VARCHAR(50) NULL,
    gender_source_concept_id INTEGER NULL,
    race_source_value VARCHAR(50) NULL,
    race_source_concept_id INTEGER NULL,
    ethnicity_source_value VARCHAR(50) NULL,
    ethnicity_source_concept_id INTEGER NULL,
    CONSTRAINT pk_person PRIMARY KEY (person_id)
);

COMMENT ON TABLE public.person IS 'OMOP CDM: Demographics and identity information for each person';

-- ----------------------------------------------------------------------------
-- OBSERVATION_PERIOD Table
-- ----------------------------------------------------------------------------
\echo 'Creating OBSERVATION_PERIOD table...'

DROP TABLE IF EXISTS public.observation_period CASCADE;

CREATE TABLE public.observation_period (
    observation_period_id SERIAL PRIMARY KEY,
    person_id BIGINT NOT NULL,
    observation_period_start_date DATE NOT NULL,
    observation_period_end_date DATE NOT NULL,
    period_type_concept_id INTEGER NOT NULL
);

COMMENT ON TABLE public.observation_period IS 'OMOP CDM: Time spans during which a person is expected to have clinical events recorded';

-- ----------------------------------------------------------------------------
-- VISIT_OCCURRENCE Table
-- ----------------------------------------------------------------------------
\echo 'Creating VISIT_OCCURRENCE table...'

DROP TABLE IF EXISTS public.visit_occurrence CASCADE;

CREATE TABLE public.visit_occurrence (
    visit_occurrence_id SERIAL PRIMARY KEY,
    person_id BIGINT NOT NULL,
    visit_concept_id INTEGER NOT NULL,
    visit_start_date DATE NOT NULL,
    visit_start_datetime TIMESTAMP NULL,
    visit_end_date DATE NOT NULL,
    visit_end_datetime TIMESTAMP NULL,
    visit_type_concept_id INTEGER NOT NULL,
    provider_id INTEGER NULL,
    care_site_id INTEGER NULL,
    visit_source_value VARCHAR(50) NULL,
    visit_source_concept_id INTEGER NULL,
    admitting_source_concept_id INTEGER NULL,
    admitting_source_value VARCHAR(50) NULL,
    discharge_to_concept_id INTEGER NULL,
    discharge_to_source_value VARCHAR(50) NULL,
    preceding_visit_occurrence_id BIGINT NULL
);

COMMENT ON TABLE public.visit_occurrence IS 'OMOP CDM: Patient visits to healthcare providers';

-- ----------------------------------------------------------------------------
-- CONDITION_OCCURRENCE Table
-- ----------------------------------------------------------------------------
\echo 'Creating CONDITION_OCCURRENCE table...'

DROP TABLE IF EXISTS public.condition_occurrence CASCADE;

CREATE TABLE public.condition_occurrence (
    condition_occurrence_id SERIAL PRIMARY KEY,
    person_id BIGINT NOT NULL,
    condition_concept_id INTEGER NOT NULL,
    condition_start_date DATE NOT NULL,
    condition_start_datetime TIMESTAMP NULL,
    condition_end_date DATE NULL,
    condition_end_datetime TIMESTAMP NULL,
    condition_type_concept_id INTEGER NOT NULL,
    stop_reason VARCHAR(20) NULL,
    provider_id INTEGER NULL,
    visit_occurrence_id BIGINT NULL,
    visit_detail_id INTEGER NULL,
    condition_source_value VARCHAR(50) NULL,
    condition_source_concept_id INTEGER NULL,
    condition_status_source_value VARCHAR(50) NULL,
    condition_status_concept_id INTEGER NULL
);

COMMENT ON TABLE public.condition_occurrence IS 'OMOP CDM: Diagnoses and medical conditions';

-- Add working columns for mapping
ALTER TABLE public.condition_occurrence 
ADD COLUMN condition_concept_id_wk VARCHAR(255) NULL,
ADD COLUMN condition_concept_id_prefix VARCHAR(3) NULL,
ADD COLUMN source_domain VARCHAR(50) NULL;

-- ----------------------------------------------------------------------------
-- DRUG_EXPOSURE Table
-- ----------------------------------------------------------------------------
\echo 'Creating DRUG_EXPOSURE table...'

DROP TABLE IF EXISTS public.drug_exposure CASCADE;

CREATE TABLE public.drug_exposure (
    drug_exposure_id SERIAL PRIMARY KEY,
    person_id BIGINT NOT NULL,
    drug_concept_id INTEGER NOT NULL,
    drug_exposure_start_date DATE NOT NULL,
    drug_exposure_start_datetime TIMESTAMP NULL,
    drug_exposure_end_date DATE NULL,
    drug_exposure_end_datetime TIMESTAMP NULL,
    verbatim_end_date DATE NULL,
    drug_type_concept_id INTEGER NOT NULL,
    stop_reason VARCHAR(20) NULL,
    refills INTEGER NULL,
    quantity NUMERIC NULL,
    days_supply INTEGER NULL,
    sig TEXT NULL,
    route_concept_id INTEGER NULL,
    lot_number VARCHAR(50) NULL,
    provider_id INTEGER NULL,
    visit_occurrence_id BIGINT NULL,
    visit_detail_id INTEGER NULL,
    drug_source_value VARCHAR(50) NULL,
    drug_source_concept_id INTEGER NULL,
    route_source_value VARCHAR(50) NULL,
    dose_unit_source_value VARCHAR(50) NULL
);

COMMENT ON TABLE public.drug_exposure IS 'OMOP CDM: Drug exposures and prescriptions';

-- Add working columns
ALTER TABLE public.drug_exposure 
ADD COLUMN drug_concept_id_origin VARCHAR(255) NULL,
ADD COLUMN source_domain VARCHAR(50) NULL,
ADD COLUMN care_site_source_value VARCHAR(50) NULL,
ADD COLUMN total_cost NUMERIC NULL;

-- ----------------------------------------------------------------------------
-- PROCEDURE_OCCURRENCE Table
-- ----------------------------------------------------------------------------
\echo 'Creating PROCEDURE_OCCURRENCE table...'

DROP TABLE IF EXISTS public.procedure_occurrence CASCADE;

CREATE TABLE public.procedure_occurrence (
    procedure_occurrence_id SERIAL PRIMARY KEY,
    person_id BIGINT NOT NULL,
    procedure_concept_id INTEGER NOT NULL,
    procedure_date DATE NOT NULL,
    procedure_datetime TIMESTAMP NULL,
    procedure_type_concept_id INTEGER NOT NULL,
    modifier_concept_id INTEGER NULL,
    quantity INTEGER NULL,
    provider_id INTEGER NULL,
    visit_occurrence_id BIGINT NULL,
    visit_detail_id INTEGER NULL,
    procedure_source_value VARCHAR(50) NULL,
    procedure_source_concept_id INTEGER NULL,
    modifier_source_value VARCHAR(50) NULL
);

COMMENT ON TABLE public.procedure_occurrence IS 'OMOP CDM: Medical procedures and interventions';

-- Add working columns
ALTER TABLE public.procedure_occurrence 
ADD COLUMN care_site_source_value VARCHAR(50) NULL,
ADD COLUMN total_cost NUMERIC NULL;

-- ----------------------------------------------------------------------------
-- MEASUREMENT Table
-- ----------------------------------------------------------------------------
\echo 'Creating MEASUREMENT table...'

DROP TABLE IF EXISTS public.measurement CASCADE;

CREATE TABLE public.measurement (
    measurement_id SERIAL PRIMARY KEY,
    person_id BIGINT NOT NULL,
    measurement_concept_id INTEGER NOT NULL,
    measurement_date DATE NOT NULL,
    measurement_datetime TIMESTAMP NULL,
    measurement_type_concept_id INTEGER NOT NULL,
    operator_concept_id INTEGER NULL,
    value_as_number NUMERIC NULL,
    value_as_concept_id INTEGER NULL,
    unit_concept_id INTEGER NULL,
    range_low NUMERIC NULL,
    range_high NUMERIC NULL,
    provider_id INTEGER NULL,
    visit_occurrence_id BIGINT NULL,
    visit_detail_id INTEGER NULL,
    measurement_source_value VARCHAR(50) NULL,
    measurement_source_concept_id INTEGER NULL,
    unit_source_value VARCHAR(50) NULL,
    value_source_value VARCHAR(50) NULL
);

COMMENT ON TABLE public.measurement IS 'OMOP CDM: Laboratory tests and vital signs';

-- Add working columns
ALTER TABLE public.measurement 
ADD COLUMN care_site_source_value VARCHAR(50) NULL;

-- ----------------------------------------------------------------------------
-- OBSERVATION Table
-- ----------------------------------------------------------------------------
\echo 'Creating OBSERVATION table...'

DROP TABLE IF EXISTS public.observation CASCADE;

CREATE TABLE public.observation (
    observation_id SERIAL PRIMARY KEY,
    person_id BIGINT NOT NULL,
    observation_concept_id INTEGER NOT NULL,
    observation_date DATE NOT NULL,
    observation_datetime TIMESTAMP NULL,
    observation_type_concept_id INTEGER NOT NULL,
    value_as_number NUMERIC NULL,
    value_as_string VARCHAR(60) NULL,
    value_as_concept_id INTEGER NULL,
    qualifier_concept_id INTEGER NULL,
    unit_concept_id INTEGER NULL,
    provider_id INTEGER NULL,
    visit_occurrence_id BIGINT NULL,
    visit_detail_id INTEGER NULL,
    observation_source_value VARCHAR(50) NULL,
    observation_source_concept_id INTEGER NULL,
    unit_source_value VARCHAR(50) NULL,
    qualifier_source_value VARCHAR(50) NULL
);

COMMENT ON TABLE public.observation IS 'OMOP CDM: Clinical observations and facts';

-- Add working columns
ALTER TABLE public.observation 
ADD COLUMN observation_concept_id_wk VARCHAR(255) NULL,
ADD COLUMN observation_concept_id_prefix VARCHAR(3) NULL;

-- ----------------------------------------------------------------------------
-- CONDITION_ERA Table
-- ----------------------------------------------------------------------------
\echo 'Creating CONDITION_ERA table...'

DROP TABLE IF EXISTS public.condition_era CASCADE;

CREATE TABLE public.condition_era (
    condition_era_id SERIAL PRIMARY KEY,
    person_id BIGINT NOT NULL,
    condition_concept_id INTEGER NOT NULL,
    condition_era_start_date DATE NOT NULL,
    condition_era_end_date DATE NOT NULL,
    condition_occurrence_count INTEGER NULL
);

COMMENT ON TABLE public.condition_era IS 'OMOP CDM: Continuous periods of condition occurrence';

-- ----------------------------------------------------------------------------
-- DRUG_ERA Table
-- ----------------------------------------------------------------------------
\echo 'Creating DRUG_ERA table...'

DROP TABLE IF EXISTS public.drug_era CASCADE;

CREATE TABLE public.drug_era (
    drug_era_id SERIAL PRIMARY KEY,
    person_id BIGINT NOT NULL,
    drug_concept_id INTEGER NOT NULL,
    drug_era_start_date DATE NOT NULL,
    drug_era_end_date DATE NOT NULL,
    drug_exposure_count INTEGER NULL,
    gap_days INTEGER NULL
);

COMMENT ON TABLE public.drug_era IS 'OMOP CDM: Continuous periods of drug exposure';

-- ----------------------------------------------------------------------------
-- Additional OMOP CDM Tables (Placeholders)
-- ----------------------------------------------------------------------------
\echo 'Creating additional OMOP CDM tables...'

-- DEVICE_EXPOSURE
DROP TABLE IF EXISTS public.device_exposure CASCADE;

CREATE TABLE public.device_exposure (
    device_exposure_id BIGINT NOT NULL,
    person_id BIGINT NOT NULL,
    device_concept_id INTEGER NOT NULL,
    device_exposure_start_date DATE NOT NULL,
    device_exposure_start_datetime TIMESTAMP NULL,
    device_exposure_end_date DATE NULL,
    device_exposure_end_datetime TIMESTAMP NULL,
    device_type_concept_id INTEGER NOT NULL,
    unique_device_id VARCHAR(50) NULL,
    quantity INTEGER NULL,
    provider_id INTEGER NULL,
    visit_occurrence_id BIGINT NULL,
    visit_detail_id INTEGER NULL,
    device_source_value VARCHAR(50) NULL,
    device_source_concept_id INTEGER NULL
);

-- NOTE
DROP TABLE IF EXISTS public.note CASCADE;

CREATE TABLE public.note (
    note_id INTEGER NOT NULL,
    person_id BIGINT NOT NULL,
    note_date DATE NOT NULL,
    note_datetime TIMESTAMP NULL,
    note_type_concept_id INTEGER NOT NULL,
    note_class_concept_id INTEGER NOT NULL,
    note_title VARCHAR(250) NULL,
    note_text TEXT NULL,
    encoding_concept_id INTEGER NOT NULL,
    language_concept_id INTEGER NOT NULL,
    provider_id INTEGER NULL,
    visit_occurrence_id BIGINT NULL,
    visit_detail_id INTEGER NULL,
    note_source_value VARCHAR(50) NULL
);

-- PROVIDER
DROP TABLE IF EXISTS public.provider CASCADE;

CREATE TABLE public.provider (
    provider_id INTEGER NOT NULL,
    provider_name VARCHAR(255) NULL,
    npi VARCHAR(20) NULL,
    dea VARCHAR(20) NULL,
    specialty_concept_id INTEGER NULL,
    care_site_id INTEGER NULL,
    year_of_birth INTEGER NULL,
    gender_concept_id INTEGER NULL,
    provider_source_value VARCHAR(50) NULL,
    specialty_source_value VARCHAR(50) NULL,
    specialty_source_concept_id INTEGER NULL,
    gender_source_value VARCHAR(50) NULL,
    gender_source_concept_id INTEGER NULL
);

-- PAYER_PLAN_PERIOD
DROP TABLE IF EXISTS public.payer_plan_period CASCADE;

CREATE TABLE public.payer_plan_period (
    payer_plan_period_id INTEGER NOT NULL,
    person_id BIGINT NOT NULL,
    payer_plan_period_start_date DATE NOT NULL,
    payer_plan_period_end_date DATE NOT NULL,
    payer_concept_id INTEGER NULL,
    payer_source_value VARCHAR(50) NULL,
    payer_source_concept_id INTEGER NULL,
    plan_concept_id INTEGER NULL,
    plan_source_value VARCHAR(50) NULL,
    plan_source_concept_id INTEGER NULL,
    sponsor_concept_id INTEGER NULL,
    sponsor_source_value VARCHAR(50) NULL,
    sponsor_source_concept_id INTEGER NULL,
    family_source_value VARCHAR(50) NULL,
    stop_reason_concept_id INTEGER NULL,
    stop_reason_source_value VARCHAR(50) NULL,
    stop_reason_source_concept_id INTEGER NULL
);

\echo '============================================================================'
\echo 'Step 02 Complete: OMOP CDM Tables Created'
\echo 'Next Step: Run 03_person_and_observation_period.sql'
\echo '============================================================================'
