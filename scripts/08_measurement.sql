-- ============================================================================
-- Script 08: Measurement
-- ============================================================================
-- Purpose: Populate MEASUREMENT table
--          - Load laboratory test results
--          - Map measurement codes to OMOP concepts
--          - Handle numeric values and units
-- ============================================================================
-- Prerequisites: Scripts 01-07 must be completed
--                Source table 'data_resultofnum' must exist
--                Vocabulary mapping table 'jo_mapping_table' must exist
--                Preprocessed table 'add_to_measurement' may exist
-- Execution: Run this script EIGHTH
-- ============================================================================

\echo '============================================================================'
\echo 'OMOP CDM Conversion - Step 08: Measurement'
\echo '============================================================================'

-- Load configuration
\i ../config.sql

-- ----------------------------------------------------------------------------
-- Load Measurement Data from Source
-- ----------------------------------------------------------------------------
\echo 'Loading measurement data from numeric results...'

-- Load from numeric result table with vocabulary mapping
INSERT INTO public.measurement (
    person_id,
    measurement_source_value,
    measurement_date,
    value_as_number,
    measurement_type_concept_id
)
SELECT 
    a."PATID" AS person_id,
    a."RESULTITEMCODE" AS measurement_source_value,
    TO_DATE(CAST(a."RESULTDATE" AS VARCHAR), 'YYYYMMDD') AS measurement_date,
    a."NUMRESULTVAL" AS value_as_number,
    44818701 AS measurement_type_concept_id  -- Lab result
FROM 
    public.data_resultofnum a
INNER JOIN 
    voca_sample.jo_mapping_table b 
    ON a."RESULTITEMCODE" = b.code
WHERE
    a."PATID" IS NOT NULL
    AND a."RESULTDATE" IS NOT NULL;

\echo 'Measurement data loaded from numeric results.'

-- Get initial count
SELECT COUNT(*) AS measurement_count_from_source FROM public.measurement;

-- ----------------------------------------------------------------------------
-- Map Measurement Codes to Concepts
-- ----------------------------------------------------------------------------
\echo 'Mapping measurement codes to OMOP concepts...'

UPDATE public.measurement m
SET measurement_concept_id = jmt.concept_id
FROM voca_sample.jo_mapping_table jmt
WHERE m.measurement_source_value = jmt.code
  AND m.measurement_concept_id IS NULL;

-- Check mapping results
SELECT 
    COUNT(*) AS total_measurements,
    COUNT(CASE WHEN measurement_concept_id IS NOT NULL THEN 1 END) AS mapped_measurements,
    COUNT(CASE WHEN measurement_concept_id IS NULL THEN 1 END) AS unmapped_measurements
FROM public.measurement;

-- ----------------------------------------------------------------------------
-- Load Additional Measurement Data from Preprocessed Table
-- ----------------------------------------------------------------------------
\echo 'Loading additional measurement data from preprocessed table...'

-- Check if preprocessed table exists
DO $$
BEGIN
    IF EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'add_to_measurement'
    ) THEN
        INSERT INTO public.measurement (
            person_id,
            measurement_concept_id,
            measurement_date,
            value_as_number,
            measurement_type_concept_id
        )
        SELECT 
            person_id,
            measurement_concept_id,
            measurement_date,
            value_as_number,
            44818701 AS measurement_type_concept_id
        FROM 
            public.add_to_measurement
        WHERE
            person_id IS NOT NULL
            AND measurement_date IS NOT NULL;
        
        RAISE NOTICE 'Additional measurement data loaded from add_to_measurement.';
    ELSE
        RAISE NOTICE 'Table add_to_measurement does not exist, skipping.';
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- Summary Statistics
-- ----------------------------------------------------------------------------
\echo 'Measurement summary:'

SELECT 
    COUNT(*) AS total_measurements,
    COUNT(DISTINCT person_id) AS unique_patients,
    COUNT(DISTINCT measurement_concept_id) AS unique_measurements,
    COUNT(CASE WHEN value_as_number IS NOT NULL THEN 1 END) AS with_numeric_value,
    MIN(measurement_date) AS earliest_date,
    MAX(measurement_date) AS latest_date
FROM 
    public.measurement;

\echo '============================================================================'
\echo 'Step 08 Complete: Measurement Data Loaded'
\echo 'Next Step: Run 09_observation.sql'
\echo '============================================================================'
