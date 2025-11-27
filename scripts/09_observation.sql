-- ============================================================================
-- Script 09: Observation
-- ============================================================================
-- Purpose: Populate OBSERVATION table
--          - Load observation data from diagnosis codes
--          - Map observation codes to OMOP concepts
--          - Handle prefix-based concept mapping
-- ============================================================================
-- Prerequisites: Scripts 01-08 must be completed
--                Source table 'data_dxofpat_pmy' must exist
--                Vocabulary mapping table 'wk_voca' must exist
-- Execution: Run this script NINTH
-- ============================================================================

\echo '============================================================================'
\echo 'OMOP CDM Conversion - Step 09: Observation'
\echo '============================================================================'

-- Load configuration
\i ../config.sql

-- ----------------------------------------------------------------------------
-- Load Observation Data from Diagnosis Codes
-- ----------------------------------------------------------------------------
\echo 'Loading observation data from diagnosis codes...'

INSERT INTO public.observation (
    person_id,
    observation_concept_id_wk,
    observation_date,
    observation_type_concept_id
)
SELECT 
    "PATID" AS person_id,
    "DXCODE" AS observation_concept_id_wk,
    TO_DATE(CAST("ORDERDATE" AS VARCHAR), 'YYYYMMDD') AS observation_date,
    44786627 AS observation_type_concept_id  -- EHR
FROM 
    public.data_dxofpat_pmy
WHERE
    "PATID" IS NOT NULL
    AND "DXCODE" IS NOT NULL
    AND "ORDERDATE" IS NOT NULL;

\echo 'Observation data loaded from diagnosis codes.'

-- Get initial count
SELECT COUNT(*) AS observation_count FROM public.observation;

-- ----------------------------------------------------------------------------
-- Extract Prefix for Concept Mapping
-- ----------------------------------------------------------------------------
\echo 'Extracting observation code prefixes for mapping...'

UPDATE public.observation
SET observation_concept_id_prefix = LEFT(observation_concept_id_wk, 3)
WHERE observation_concept_id_wk IS NOT NULL;

-- ----------------------------------------------------------------------------
-- Map Observation Codes to Concepts
-- ----------------------------------------------------------------------------
\echo 'Mapping observation codes to OMOP concepts...'

UPDATE public.observation o
SET observation_concept_id = v.concept_id
FROM voca_sample.wk_voca v
WHERE o.observation_concept_id_prefix = CAST(v.concept_code AS VARCHAR)
  AND o.observation_concept_id IS NULL;

-- Check mapping results
SELECT 
    COUNT(*) AS total_observations,
    COUNT(CASE WHEN observation_concept_id IS NOT NULL THEN 1 END) AS mapped_observations,
    COUNT(CASE WHEN observation_concept_id IS NULL THEN 1 END) AS unmapped_observations
FROM public.observation;

-- ----------------------------------------------------------------------------
-- Set Default Concept for Unmapped Observations (Optional)
-- ----------------------------------------------------------------------------
\echo 'Setting default concept for unmapped observations...'

-- Note: This sets all unmapped observations to a default concept
-- Comment out this section if you prefer to keep unmapped observations as NULL
UPDATE public.observation
SET observation_concept_id = 4336011  -- Default observation concept
WHERE observation_concept_id IS NULL;

-- ----------------------------------------------------------------------------
-- Summary Statistics
-- ----------------------------------------------------------------------------
\echo 'Observation summary:'

SELECT 
    COUNT(*) AS total_observations,
    COUNT(DISTINCT person_id) AS unique_patients,
    COUNT(DISTINCT observation_concept_id) AS unique_concepts,
    MIN(observation_date) AS earliest_date,
    MAX(observation_date) AS latest_date
FROM 
    public.observation;

\echo '============================================================================'
\echo 'Step 09 Complete: Observation Data Loaded'
\echo 'Next Step: Run 10_era_tables.sql'
\echo '============================================================================'
