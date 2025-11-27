-- ============================================================================
-- Script 03: Person and Observation Period
-- ============================================================================
-- Purpose: Populate PERSON and OBSERVATION_PERIOD tables
--          - Extract patient demographics from source
--          - Map gender codes to OMOP concepts
--          - Calculate birth year from Korean ID
--          - Create observation periods from admission data
-- ============================================================================
-- Prerequisites: Scripts 01 and 02 must be completed
-- Execution: Run this script THIRD
-- ============================================================================

\echo '============================================================================'
\echo 'OMOP CDM Conversion - Step 03: Person and Observation Period'
\echo '============================================================================'

-- Load configuration
\i ../config.sql

-- ----------------------------------------------------------------------------
-- PERSON Table Population
-- ----------------------------------------------------------------------------
\echo 'Populating PERSON table...'

INSERT INTO public.person (
    person_id,
    gender_concept_id,
    year_of_birth,
    race_concept_id,
    ethnicity_concept_id
)
SELECT 
    "PATID" AS person_id,
    -- Gender mapping: M -> 8507 (MALE), F -> 8532 (FEMALE)
    CASE "SEX"
        WHEN 'M' THEN 8507  -- MALE
        WHEN 'F' THEN 8532  -- FEMALE
        ELSE 0  -- Unknown gender
    END AS gender_concept_id,
    -- Calculate birth year from Korean ID (PRSNIDPRE first 2 digits + 1900)
    1900 + CAST(LEFT(CAST("PRSNIDPRE" AS TEXT), 2) AS INTEGER) AS year_of_birth,
    -- Race: Asian (Korean population)
    38003585 AS race_concept_id,
    -- Ethnicity: Not Hispanic or Latino
    38003564 AS ethnicity_concept_id
FROM 
    public.backup_data_patmst;

-- Get count of persons inserted
SELECT COUNT(*) AS person_count FROM public.person;

\echo 'PERSON table populated successfully.'

-- ----------------------------------------------------------------------------
-- OBSERVATION_PERIOD Table Population
-- ----------------------------------------------------------------------------
\echo 'Populating OBSERVATION_PERIOD table...'

-- Create observation periods from inpatient admission data
INSERT INTO public.observation_period (
    person_id, 
    observation_period_start_date, 
    observation_period_end_date,
    period_type_concept_id
)
SELECT 
    "PATID" AS person_id,
    TO_DATE(CAST("ADMACPTDATE" AS VARCHAR), 'YYYYMMDD') AS observation_period_start_date,
    TO_DATE(CAST("DSCHRGCALCDATE" AS VARCHAR), 'YYYYMMDD') AS observation_period_end_date,
    44814725 AS period_type_concept_id  -- EHR encounter records
FROM 
    public.data_ipdacpt_pmy
WHERE
    "ADMACPTDATE" IS NOT NULL 
    AND "DSCHRGCALCDATE" IS NOT NULL
    AND "ADMACPTDATE" <= "DSCHRGCALCDATE";  -- Ensure valid date range

-- Get count of observation periods inserted
SELECT COUNT(*) AS observation_period_count FROM public.observation_period;

\echo 'OBSERVATION_PERIOD table populated successfully.'

-- ----------------------------------------------------------------------------
-- Data Quality Checks
-- ----------------------------------------------------------------------------
\echo 'Performing data quality checks...'

-- Check for persons with invalid gender
SELECT COUNT(*) AS invalid_gender_count 
FROM public.person 
WHERE gender_concept_id = 0;

-- Check for persons with invalid birth year
SELECT COUNT(*) AS invalid_birth_year_count 
FROM public.person 
WHERE year_of_birth < 1900 OR year_of_birth > 2025;

-- Check for observation periods with invalid dates
SELECT COUNT(*) AS invalid_period_count 
FROM public.observation_period 
WHERE observation_period_start_date > observation_period_end_date;

\echo '============================================================================'
\echo 'Step 03 Complete: Person and Observation Period Data Loaded'
\echo 'Next Step: Run 04_visit_occurrence.sql'
\echo '============================================================================'
