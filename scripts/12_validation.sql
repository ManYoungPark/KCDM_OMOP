-- ============================================================================
-- Script 12: Data Validation
-- ============================================================================
-- Purpose: Validate OMOP CDM data quality and completeness
--          - Check record counts for all tables
--          - Validate required fields
--          - Check referential integrity
--          - Generate data quality report
-- ============================================================================
-- Prerequisites: Scripts 01-11 must be completed
-- Execution: Run this script LAST for validation
-- ============================================================================

\echo '============================================================================'
\echo 'OMOP CDM Conversion - Step 12: Data Validation'
\echo '============================================================================'

-- Load configuration
\i ../config.sql

\echo ''
\echo '============================================================================'
\echo 'SECTION 1: Record Count Summary'
\echo '============================================================================'

-- Record counts for all OMOP CDM tables
SELECT 'PERSON' AS table_name, COUNT(*) AS record_count FROM public.person
UNION ALL
SELECT 'OBSERVATION_PERIOD', COUNT(*) FROM public.observation_period
UNION ALL
SELECT 'VISIT_OCCURRENCE', COUNT(*) FROM public.visit_occurrence
UNION ALL
SELECT 'CONDITION_OCCURRENCE', COUNT(*) FROM public.condition_occurrence
UNION ALL
SELECT 'DRUG_EXPOSURE', COUNT(*) FROM public.drug_exposure
UNION ALL
SELECT 'PROCEDURE_OCCURRENCE', COUNT(*) FROM public.procedure_occurrence
UNION ALL
SELECT 'MEASUREMENT', COUNT(*) FROM public.measurement
UNION ALL
SELECT 'OBSERVATION', COUNT(*) FROM public.observation
UNION ALL
SELECT 'CONDITION_ERA', COUNT(*) FROM public.condition_era
UNION ALL
SELECT 'DRUG_ERA', COUNT(*) FROM public.drug_era
ORDER BY table_name;

\echo ''
\echo '============================================================================'
\echo 'SECTION 2: Required Field Validation'
\echo '============================================================================'

-- Check for NULL values in required fields

\echo 'Checking PERSON table required fields...'
SELECT 
    'PERSON' AS table_name,
    COUNT(CASE WHEN person_id IS NULL THEN 1 END) AS null_person_id,
    COUNT(CASE WHEN gender_concept_id IS NULL THEN 1 END) AS null_gender,
    COUNT(CASE WHEN year_of_birth IS NULL THEN 1 END) AS null_birth_year,
    COUNT(CASE WHEN race_concept_id IS NULL THEN 1 END) AS null_race
FROM public.person;

\echo 'Checking VISIT_OCCURRENCE table required fields...'
SELECT 
    'VISIT_OCCURRENCE' AS table_name,
    COUNT(CASE WHEN visit_occurrence_id IS NULL THEN 1 END) AS null_visit_id,
    COUNT(CASE WHEN person_id IS NULL THEN 1 END) AS null_person_id,
    COUNT(CASE WHEN visit_concept_id IS NULL THEN 1 END) AS null_visit_concept,
    COUNT(CASE WHEN visit_start_date IS NULL THEN 1 END) AS null_start_date
FROM public.visit_occurrence;

\echo 'Checking CONDITION_OCCURRENCE table required fields...'
SELECT 
    'CONDITION_OCCURRENCE' AS table_name,
    COUNT(CASE WHEN condition_occurrence_id IS NULL THEN 1 END) AS null_condition_id,
    COUNT(CASE WHEN person_id IS NULL THEN 1 END) AS null_person_id,
    COUNT(CASE WHEN condition_concept_id IS NULL THEN 1 END) AS null_concept_id,
    COUNT(CASE WHEN condition_start_date IS NULL THEN 1 END) AS null_start_date
FROM public.condition_occurrence;

\echo 'Checking DRUG_EXPOSURE table required fields...'
SELECT 
    'DRUG_EXPOSURE' AS table_name,
    COUNT(CASE WHEN drug_exposure_id IS NULL THEN 1 END) AS null_drug_id,
    COUNT(CASE WHEN person_id IS NULL THEN 1 END) AS null_person_id,
    COUNT(CASE WHEN drug_concept_id IS NULL THEN 1 END) AS null_concept_id,
    COUNT(CASE WHEN drug_exposure_start_date IS NULL THEN 1 END) AS null_start_date
FROM public.drug_exposure;

\echo ''
\echo '============================================================================'
\echo 'SECTION 3: Referential Integrity Checks'
\echo '============================================================================'

-- Check for orphaned records (records referencing non-existent persons)

\echo 'Checking for orphaned VISIT_OCCURRENCE records...'
SELECT 
    COUNT(*) AS orphaned_visits
FROM public.visit_occurrence vo
WHERE NOT EXISTS (
    SELECT 1 FROM public.person p WHERE p.person_id = vo.person_id
);

\echo 'Checking for orphaned CONDITION_OCCURRENCE records...'
SELECT 
    COUNT(*) AS orphaned_conditions
FROM public.condition_occurrence co
WHERE NOT EXISTS (
    SELECT 1 FROM public.person p WHERE p.person_id = co.person_id
);

\echo 'Checking for orphaned DRUG_EXPOSURE records...'
SELECT 
    COUNT(*) AS orphaned_drugs
FROM public.drug_exposure de
WHERE NOT EXISTS (
    SELECT 1 FROM public.person p WHERE p.person_id = de.person_id
);

\echo ''
\echo '============================================================================'
\echo 'SECTION 4: Data Quality Checks'
\echo '============================================================================'

-- Check for data quality issues

\echo 'Checking for invalid birth years...'
SELECT 
    COUNT(*) AS invalid_birth_year_count,
    MIN(year_of_birth) AS min_year,
    MAX(year_of_birth) AS max_year
FROM public.person
WHERE year_of_birth < 1900 OR year_of_birth > 2025;

\echo 'Checking for invalid gender concepts...'
SELECT 
    gender_concept_id,
    COUNT(*) AS count
FROM public.person
WHERE gender_concept_id NOT IN (8507, 8532)
GROUP BY gender_concept_id;

\echo 'Checking for invalid visit date ranges...'
SELECT 
    COUNT(*) AS invalid_visit_dates
FROM public.visit_occurrence
WHERE visit_start_date > visit_end_date;

\echo 'Checking for invalid observation period date ranges...'
SELECT 
    COUNT(*) AS invalid_period_dates
FROM public.observation_period
WHERE observation_period_start_date > observation_period_end_date;

\echo 'Checking for conditions without visit linkage...'
SELECT 
    COUNT(*) AS conditions_without_visit,
    ROUND(100.0 * COUNT(*) / NULLIF((SELECT COUNT(*) FROM public.condition_occurrence), 0), 2) AS percentage
FROM public.condition_occurrence
WHERE visit_occurrence_id IS NULL;

\echo ''
\echo '============================================================================'
\echo 'SECTION 5: Concept Mapping Statistics'
\echo '============================================================================'

-- Check concept mapping completeness

\echo 'Condition concept mapping statistics:'
SELECT 
    COUNT(*) AS total_conditions,
    COUNT(CASE WHEN condition_concept_id IS NOT NULL AND condition_concept_id != 0 THEN 1 END) AS mapped_conditions,
    COUNT(CASE WHEN condition_concept_id IS NULL OR condition_concept_id = 0 THEN 1 END) AS unmapped_conditions,
    ROUND(100.0 * COUNT(CASE WHEN condition_concept_id IS NOT NULL AND condition_concept_id != 0 THEN 1 END) / 
          NULLIF(COUNT(*), 0), 2) AS mapping_percentage
FROM public.condition_occurrence;

\echo 'Drug concept mapping statistics:'
SELECT 
    COUNT(*) AS total_drugs,
    COUNT(CASE WHEN drug_concept_id IS NOT NULL AND drug_concept_id != 0 THEN 1 END) AS mapped_drugs,
    COUNT(CASE WHEN drug_concept_id IS NULL OR drug_concept_id = 0 THEN 1 END) AS unmapped_drugs,
    ROUND(100.0 * COUNT(CASE WHEN drug_concept_id IS NOT NULL AND drug_concept_id != 0 THEN 1 END) / 
          NULLIF(COUNT(*), 0), 2) AS mapping_percentage
FROM public.drug_exposure;

\echo 'Measurement concept mapping statistics:'
SELECT 
    COUNT(*) AS total_measurements,
    COUNT(CASE WHEN measurement_concept_id IS NOT NULL AND measurement_concept_id != 0 THEN 1 END) AS mapped_measurements,
    COUNT(CASE WHEN measurement_concept_id IS NULL OR measurement_concept_id = 0 THEN 1 END) AS unmapped_measurements,
    ROUND(100.0 * COUNT(CASE WHEN measurement_concept_id IS NOT NULL AND measurement_concept_id != 0 THEN 1 END) / 
          NULLIF(COUNT(*), 0), 2) AS mapping_percentage
FROM public.measurement;

\echo ''
\echo '============================================================================'
\echo 'SECTION 6: Patient Coverage Statistics'
\echo '============================================================================'

-- Check how many patients have data in each table

SELECT 
    'PERSON' AS table_name,
    COUNT(DISTINCT person_id) AS unique_patients
FROM public.person
UNION ALL
SELECT 'OBSERVATION_PERIOD', COUNT(DISTINCT person_id) FROM public.observation_period
UNION ALL
SELECT 'VISIT_OCCURRENCE', COUNT(DISTINCT person_id) FROM public.visit_occurrence
UNION ALL
SELECT 'CONDITION_OCCURRENCE', COUNT(DISTINCT person_id) FROM public.condition_occurrence
UNION ALL
SELECT 'DRUG_EXPOSURE', COUNT(DISTINCT person_id) FROM public.drug_exposure
UNION ALL
SELECT 'PROCEDURE_OCCURRENCE', COUNT(DISTINCT person_id) FROM public.procedure_occurrence
UNION ALL
SELECT 'MEASUREMENT', COUNT(DISTINCT person_id) FROM public.measurement
UNION ALL
SELECT 'OBSERVATION', COUNT(DISTINCT person_id) FROM public.observation
ORDER BY table_name;

\echo ''
\echo '============================================================================'
\echo 'SECTION 7: Date Range Summary'
\echo '============================================================================'

-- Check date ranges for temporal tables

\echo 'Visit occurrence date range:'
SELECT 
    MIN(visit_start_date) AS earliest_visit,
    MAX(visit_end_date) AS latest_visit,
    MAX(visit_end_date) - MIN(visit_start_date) AS date_span_days
FROM public.visit_occurrence;

\echo 'Condition occurrence date range:'
SELECT 
    MIN(condition_start_date) AS earliest_condition,
    MAX(condition_start_date) AS latest_condition,
    MAX(condition_start_date) - MIN(condition_start_date) AS date_span_days
FROM public.condition_occurrence;

\echo 'Drug exposure date range:'
SELECT 
    MIN(drug_exposure_start_date) AS earliest_drug,
    MAX(drug_exposure_start_date) AS latest_drug,
    MAX(drug_exposure_start_date) - MIN(drug_exposure_start_date) AS date_span_days
FROM public.drug_exposure;

\echo ''
\echo '============================================================================'
\echo 'Data Validation Complete'
\echo '============================================================================'
\echo ''
\echo 'Please review the validation results above.'
\echo 'Address any data quality issues before using the OMOP CDM data.'
\echo ''
\echo '============================================================================'
