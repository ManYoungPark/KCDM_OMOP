-- ============================================================================
-- Script 04: Visit Occurrence
-- ============================================================================
-- Purpose: Populate VISIT_OCCURRENCE table
--          - Load inpatient visits (concept_id: 9201)
--          - Load outpatient visits (concept_id: 9202)
--          - Transform date formats
-- ============================================================================
-- Prerequisites: Scripts 01-03 must be completed
-- Execution: Run this script FOURTH
-- ============================================================================

\echo '============================================================================'
\echo 'OMOP CDM Conversion - Step 04: Visit Occurrence'
\echo '============================================================================'

-- Load configuration
\i ../config.sql

-- ----------------------------------------------------------------------------
-- Inpatient Visits
-- ----------------------------------------------------------------------------
\echo 'Loading inpatient visits...'

INSERT INTO public.visit_occurrence (
    person_id, 
    visit_start_date, 
    visit_end_date,
    visit_concept_id,
    visit_type_concept_id
)
SELECT 
    "PATID" AS person_id,
    TO_DATE(CAST("ADMACPTDATE" AS VARCHAR), 'YYYYMMDD') AS visit_start_date,
    TO_DATE(CAST("DSCHRGCALCDATE" AS VARCHAR), 'YYYYMMDD') AS visit_end_date,
    9201 AS visit_concept_id,  -- Inpatient Visit
    44818518 AS visit_type_concept_id  -- EHR
FROM 
    public.data_ipdacpt_pmy
WHERE
    "ADMACPTDATE" IS NOT NULL 
    AND "DSCHRGCALCDATE" IS NOT NULL;

-- Get count of inpatient visits
SELECT COUNT(*) AS inpatient_visit_count 
FROM public.visit_occurrence 
WHERE visit_concept_id = 9201;

\echo 'Inpatient visits loaded successfully.'

-- ----------------------------------------------------------------------------
-- Outpatient Visits
-- ----------------------------------------------------------------------------
\echo 'Loading outpatient visits...'

INSERT INTO public.visit_occurrence (
    person_id, 
    visit_start_date, 
    visit_end_date,
    visit_concept_id,
    visit_type_concept_id
)
SELECT 
    "PATID" AS person_id,
    TO_DATE(CAST("OPDDATE" AS VARCHAR), 'YYYYMMDD') AS visit_start_date,
    TO_DATE(CAST("OPDDATE" AS VARCHAR), 'YYYYMMDD') AS visit_end_date,
    9202 AS visit_concept_id,  -- Outpatient Visit
    44818518 AS visit_type_concept_id  -- EHR
FROM 
    public.data_opdacpt_pmy
WHERE
    "OPDDATE" IS NOT NULL;

-- Get count of outpatient visits
SELECT COUNT(*) AS outpatient_visit_count 
FROM public.visit_occurrence 
WHERE visit_concept_id = 9202;

\echo 'Outpatient visits loaded successfully.'

-- ----------------------------------------------------------------------------
-- Summary Statistics
-- ----------------------------------------------------------------------------
\echo 'Visit occurrence summary:'

SELECT 
    visit_concept_id,
    CASE visit_concept_id
        WHEN 9201 THEN 'Inpatient Visit'
        WHEN 9202 THEN 'Outpatient Visit'
        ELSE 'Other'
    END AS visit_type,
    COUNT(*) AS visit_count
FROM 
    public.visit_occurrence
GROUP BY 
    visit_concept_id
ORDER BY 
    visit_concept_id;

\echo '============================================================================'
\echo 'Step 04 Complete: Visit Occurrence Data Loaded'
\echo 'Next Step: Run 05_condition_occurrence.sql'
\echo '============================================================================'
