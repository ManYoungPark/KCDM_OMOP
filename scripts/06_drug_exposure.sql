-- ============================================================================
-- Script 06: Drug Exposure
-- ============================================================================
-- Purpose: Populate DRUG_EXPOSURE table
--          - Load drug prescription/order data
--          - Map drug codes to OMOP concepts
--          - Handle date transformations
-- ============================================================================
-- Prerequisites: Scripts 01-05 must be completed
--                Preprocessed table 'add_drug_Data' must exist
-- Execution: Run this script SIXTH
-- ============================================================================

\echo '============================================================================'
\echo 'OMOP CDM Conversion - Step 06: Drug Exposure'
\echo '============================================================================'

-- Load configuration
\i ../config.sql

-- ----------------------------------------------------------------------------
-- Load Drug Exposure Data from Preprocessed Table
-- ----------------------------------------------------------------------------
\echo 'Loading drug exposure data...'

-- Load from preprocessed drug data table
INSERT INTO public.drug_exposure (
    person_id,
    drug_concept_id,
    drug_exposure_start_date,
    drug_exposure_end_date,
    drug_type_concept_id
)
SELECT
    "PATID" AS person_id,
    "concept_id" AS drug_concept_id,
    TO_DATE(CAST("ORDERDATE" AS VARCHAR), 'YYYYMMDD') AS drug_exposure_start_date,
    TO_DATE(CAST("ORDERDATE" AS VARCHAR), 'YYYYMMDD') AS drug_exposure_end_date,
    38000177 AS drug_type_concept_id  -- EHR prescription
FROM 
    public."add_drug_Data"
WHERE
    "PATID" IS NOT NULL
    AND "concept_id" IS NOT NULL
    AND "ORDERDATE" IS NOT NULL;

\echo 'Drug exposure data loaded from preprocessed table.'

-- Get count of drug exposures
SELECT COUNT(*) AS drug_exposure_count FROM public.drug_exposure;

-- ----------------------------------------------------------------------------
-- Summary Statistics
-- ----------------------------------------------------------------------------
\echo 'Drug exposure summary:'

SELECT 
    COUNT(*) AS total_exposures,
    COUNT(DISTINCT person_id) AS unique_patients,
    COUNT(DISTINCT drug_concept_id) AS unique_drugs,
    MIN(drug_exposure_start_date) AS earliest_date,
    MAX(drug_exposure_start_date) AS latest_date
FROM 
    public.drug_exposure;

\echo '============================================================================'
\echo 'Step 06 Complete: Drug Exposure Data Loaded'
\echo 'Next Step: Run 07_procedure_occurrence.sql'
\echo '============================================================================'
