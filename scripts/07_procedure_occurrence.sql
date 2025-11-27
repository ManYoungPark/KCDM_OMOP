-- ============================================================================
-- Script 07: Procedure Occurrence
-- ============================================================================
-- Purpose: Populate PROCEDURE_OCCURRENCE table
--          - Load procedure data from preprocessed table
--          - Map procedure codes to OMOP concepts
--          - Handle date transformations
-- ============================================================================
-- Prerequisites: Scripts 01-06 must be completed
--                Preprocessed table 'add_proc_Data' must exist
-- Execution: Run this script SEVENTH
-- ============================================================================

\echo '============================================================================'
\echo 'OMOP CDM Conversion - Step 07: Procedure Occurrence'
\echo '============================================================================'

-- Load configuration
\i ../config.sql

-- ----------------------------------------------------------------------------
-- Load Procedure Occurrence Data
-- ----------------------------------------------------------------------------
\echo 'Loading procedure occurrence data...'

INSERT INTO public.procedure_occurrence (
    person_id,
    procedure_concept_id,
    procedure_date,
    procedure_type_concept_id
)
SELECT
    "PATID" AS person_id,
    "concept_id" AS procedure_concept_id,
    TO_DATE(CAST("ORDERDATE" AS VARCHAR), 'YYYYMMDD') AS procedure_date,
    38000275 AS procedure_type_concept_id  -- EHR
FROM 
    public."add_proc_Data"
WHERE
    "PATID" IS NOT NULL
    AND "concept_id" IS NOT NULL
    AND "ORDERDATE" IS NOT NULL;

\echo 'Procedure occurrence data loaded from preprocessed table.'

-- Get count of procedures
SELECT COUNT(*) AS procedure_count FROM public.procedure_occurrence;

-- ----------------------------------------------------------------------------
-- Summary Statistics
-- ----------------------------------------------------------------------------
\echo 'Procedure occurrence summary:'

SELECT 
    COUNT(*) AS total_procedures,
    COUNT(DISTINCT person_id) AS unique_patients,
    COUNT(DISTINCT procedure_concept_id) AS unique_procedures,
    MIN(procedure_date) AS earliest_date,
    MAX(procedure_date) AS latest_date
FROM 
    public.procedure_occurrence;

\echo '============================================================================'
\echo 'Step 07 Complete: Procedure Occurrence Data Loaded'
\echo 'Next Step: Run 08_measurement.sql'
\echo '============================================================================'
