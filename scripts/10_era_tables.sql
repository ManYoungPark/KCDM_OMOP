-- ============================================================================
-- Script 10: Era Tables
-- ============================================================================
-- Purpose: Generate CONDITION_ERA and DRUG_ERA tables
--          - Aggregate condition occurrences into eras
--          - Aggregate drug exposures into eras
--          - Calculate occurrence counts
-- ============================================================================
-- Prerequisites: Scripts 01-09 must be completed
-- Execution: Run this script TENTH
-- ============================================================================

\echo '============================================================================'
\echo 'OMOP CDM Conversion - Step 10: Era Tables'
\echo '============================================================================'

-- Load configuration
\i ../config.sql

-- ----------------------------------------------------------------------------
-- CONDITION_ERA Table
-- ----------------------------------------------------------------------------
\echo 'Generating CONDITION_ERA table...'

-- Aggregate condition occurrences by person and concept
INSERT INTO public.condition_era (
    person_id,
    condition_concept_id,
    condition_era_start_date,
    condition_era_end_date,
    condition_occurrence_count
)
SELECT
    person_id,
    condition_concept_id,
    MIN(condition_start_date) AS condition_era_start_date,
    MAX(condition_end_date) AS condition_era_end_date,
    COUNT(*) AS condition_occurrence_count
FROM
    public.condition_occurrence
WHERE 
    condition_concept_id IS NOT NULL
    AND condition_start_date IS NOT NULL
GROUP BY
    person_id,
    condition_concept_id;

\echo 'CONDITION_ERA table generated.'

-- Get count of condition eras
SELECT COUNT(*) AS condition_era_count FROM public.condition_era;

-- ----------------------------------------------------------------------------
-- DRUG_ERA Table
-- ----------------------------------------------------------------------------
\echo 'Generating DRUG_ERA table...'

-- Aggregate drug exposures by person and concept
INSERT INTO public.drug_era (
    person_id,
    drug_concept_id,
    drug_era_start_date,
    drug_era_end_date,
    drug_exposure_count
)
SELECT
    person_id,
    drug_concept_id,
    MIN(drug_exposure_start_date) AS drug_era_start_date,
    MAX(drug_exposure_end_date) AS drug_era_end_date,
    COUNT(*) AS drug_exposure_count
FROM
    public.drug_exposure
WHERE 
    drug_concept_id IS NOT NULL
    AND drug_exposure_start_date IS NOT NULL
GROUP BY
    person_id,
    drug_concept_id;

\echo 'DRUG_ERA table generated.'

-- Get count of drug eras
SELECT COUNT(*) AS drug_era_count FROM public.drug_era;

-- ----------------------------------------------------------------------------
-- Summary Statistics
-- ----------------------------------------------------------------------------
\echo 'Era tables summary:'

-- Condition era summary
SELECT 
    'CONDITION_ERA' AS table_name,
    COUNT(*) AS total_eras,
    COUNT(DISTINCT person_id) AS unique_patients,
    COUNT(DISTINCT condition_concept_id) AS unique_concepts,
    AVG(condition_occurrence_count) AS avg_occurrences_per_era
FROM 
    public.condition_era;

-- Drug era summary
SELECT 
    'DRUG_ERA' AS table_name,
    COUNT(*) AS total_eras,
    COUNT(DISTINCT person_id) AS unique_patients,
    COUNT(DISTINCT drug_concept_id) AS unique_concepts,
    AVG(drug_exposure_count) AS avg_exposures_per_era
FROM 
    public.drug_era;

\echo '============================================================================'
\echo 'Step 10 Complete: Era Tables Generated'
\echo 'Next Step: Run 11_vocabulary.sql'
\echo '============================================================================'
