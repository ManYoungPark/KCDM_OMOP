-- ============================================================================
-- Script 05: Condition Occurrence
-- ============================================================================
-- Purpose: Populate CONDITION_OCCURRENCE table
--          - Load diagnosis data from preprocessed table
--          - Map diagnosis codes to OMOP concepts
--          - Link conditions to visit occurrences
-- ============================================================================
-- Prerequisites: Scripts 01-04 must be completed
--                Preprocessed table 'add_condition_new' must exist
--                Vocabulary mapping table 'wk_voca' must exist
-- Execution: Run this script FIFTH
-- ============================================================================

\echo '============================================================================'
\echo 'OMOP CDM Conversion - Step 05: Condition Occurrence'
\echo '============================================================================'

-- Load configuration
\i ../config.sql

-- ----------------------------------------------------------------------------
-- Load Condition Data from Preprocessed Table
-- ----------------------------------------------------------------------------
\echo 'Loading condition occurrence data...'

-- Note: This assumes the preprocessed table 'add_condition_new' exists
-- and contains the necessary columns
INSERT INTO public.condition_occurrence (
    person_id,
    condition_concept_id,
    condition_start_date,
    condition_end_date,
    condition_type_concept_id
)
SELECT 
    person_id,
    condition_concept_id,
    condition_start_date,
    condition_end_date,
    32817 AS condition_type_concept_id  -- EHR
FROM 
    public.add_condition_new
WHERE
    person_id IS NOT NULL
    AND condition_start_date IS NOT NULL;

\echo 'Condition occurrence data loaded from preprocessed table.'

-- Get initial count
SELECT COUNT(*) AS condition_count FROM public.condition_occurrence;

-- ----------------------------------------------------------------------------
-- Map Diagnosis Codes to Concepts (Alternative Method)
-- ----------------------------------------------------------------------------
-- This section is for cases where diagnosis codes need to be mapped
-- using a prefix-based vocabulary mapping

-- Extract first 3 characters as prefix for mapping
\echo 'Extracting diagnosis code prefixes for mapping...'

UPDATE public.condition_occurrence
SET condition_concept_id_prefix = LEFT(condition_concept_id_wk, 3)
WHERE condition_concept_id_wk IS NOT NULL;

-- Map using vocabulary table
\echo 'Mapping diagnosis codes to OMOP concepts...'

UPDATE public.condition_occurrence co
SET condition_concept_id = v.concept_id
FROM voca_sample.wk_voca v
WHERE co.condition_concept_id_prefix = CAST(v.concept_code AS VARCHAR)
  AND co.condition_concept_id IS NULL;

-- Check mapping results
SELECT 
    COUNT(*) AS total_conditions,
    COUNT(CASE WHEN condition_concept_id IS NOT NULL THEN 1 END) AS mapped_conditions,
    COUNT(CASE WHEN condition_concept_id IS NULL THEN 1 END) AS unmapped_conditions
FROM public.condition_occurrence;

-- ----------------------------------------------------------------------------
-- Link Conditions to Visit Occurrences
-- ----------------------------------------------------------------------------
\echo 'Linking conditions to visit occurrences...'

-- Update visit_occurrence_id by finding the visit that contains the condition date
UPDATE public.condition_occurrence co
SET visit_occurrence_id = (
    SELECT vo.visit_occurrence_id
    FROM public.visit_occurrence vo
    WHERE vo.person_id = co.person_id
      AND vo.visit_start_date <= co.condition_start_date
      AND vo.visit_end_date >= co.condition_start_date
    ORDER BY vo.visit_start_date DESC
    LIMIT 1
)
WHERE EXISTS (
    SELECT 1
    FROM public.visit_occurrence vo
    WHERE vo.person_id = co.person_id
      AND vo.visit_start_date <= co.condition_start_date
      AND vo.visit_end_date >= co.condition_start_date
);

-- Check linkage results
SELECT 
    COUNT(*) AS total_conditions,
    COUNT(CASE WHEN visit_occurrence_id IS NOT NULL THEN 1 END) AS linked_to_visit,
    COUNT(CASE WHEN visit_occurrence_id IS NULL THEN 1 END) AS not_linked
FROM public.condition_occurrence;

\echo '============================================================================'
\echo 'Step 05 Complete: Condition Occurrence Data Loaded'
\echo 'Next Step: Run 06_drug_exposure.sql'
\echo '============================================================================'
