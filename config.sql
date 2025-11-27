-- ============================================================================
-- OMOP CDM Conversion Configuration File
-- ============================================================================
-- This file contains all configurable parameters for the OMOP CDM conversion.
-- Modify these values according to your environment and requirements.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Schema Configuration
-- ----------------------------------------------------------------------------
-- Target schema for OMOP CDM tables (default: public)
\set cdm_schema 'public'

-- Vocabulary schema (if different from CDM schema)
\set vocab_schema 'voca_sample'

-- ----------------------------------------------------------------------------
-- Source Table Names
-- ----------------------------------------------------------------------------
-- Patient master table (after backup)
\set source_patient_table 'backup_data_patmst'

-- Inpatient admission table
\set source_inpatient_table 'data_ipdacpt_pmy'

-- Outpatient admission table
\set source_outpatient_table 'data_opdacpt_pmy'

-- Diagnosis table
\set source_diagnosis_table 'data_dxofpat_pmy'

-- Order information table
\set source_order_table 'data_orderinfos2020_pmy'

-- Numeric result table
\set source_numeric_result_table 'data_resultofnum'

-- Preprocessed tables (created externally, e.g., from R)
\set preprocessed_condition_table 'add_condition_new'
\set preprocessed_drug_table 'add_drug_Data'
\set preprocessed_procedure_table 'add_proc_Data'
\set preprocessed_measurement_table 'add_to_measurement'

-- ----------------------------------------------------------------------------
-- OMOP CDM Concept IDs - Gender
-- ----------------------------------------------------------------------------
-- Gender concept IDs from OMOP standardized vocabularies
\set concept_gender_male 8507
\set concept_gender_female 8532

-- ----------------------------------------------------------------------------
-- OMOP CDM Concept IDs - Race and Ethnicity
-- ----------------------------------------------------------------------------
-- Race: Asian (Korean population)
\set concept_race_asian 38003585

-- Ethnicity: Not Hispanic or Latino (default for Korean population)
\set concept_ethnicity_not_hispanic 38003564

-- ----------------------------------------------------------------------------
-- OMOP CDM Concept IDs - Visit Types
-- ----------------------------------------------------------------------------
-- Visit Concept IDs
\set concept_visit_inpatient 9201
\set concept_visit_outpatient 9202

-- Visit Type Concept ID (default: EHR)
\set concept_visit_type_ehr 44818518

-- ----------------------------------------------------------------------------
-- OMOP CDM Concept IDs - Observation Period
-- ----------------------------------------------------------------------------
-- Period Type Concept ID (default: EHR encounter records)
\set concept_period_type_ehr 44814725

-- ----------------------------------------------------------------------------
-- OMOP CDM Concept IDs - Observation
-- ----------------------------------------------------------------------------
-- Observation Type Concept ID (default: EHR)
\set concept_observation_type_ehr 44786627

-- Default Observation Concept ID (for unmapped observations)
\set concept_observation_default 4336011

-- ----------------------------------------------------------------------------
-- OMOP CDM Concept IDs - Condition
-- ----------------------------------------------------------------------------
-- Condition Type Concept ID (default: EHR)
\set concept_condition_type_ehr 32817

-- ----------------------------------------------------------------------------
-- OMOP CDM Concept IDs - Drug
-- ----------------------------------------------------------------------------
-- Drug Type Concept ID (default: EHR prescription)
\set concept_drug_type_ehr 38000177

-- ----------------------------------------------------------------------------
-- OMOP CDM Concept IDs - Procedure
-- ----------------------------------------------------------------------------
-- Procedure Type Concept ID (default: EHR)
\set concept_procedure_type_ehr 38000275

-- ----------------------------------------------------------------------------
-- OMOP CDM Concept IDs - Measurement
-- ----------------------------------------------------------------------------
-- Measurement Type Concept ID (default: EHR)
\set concept_measurement_type_ehr 44818701

-- ----------------------------------------------------------------------------
-- Date Format Configuration
-- ----------------------------------------------------------------------------
-- Source date format (YYYYMMDD for numeric dates)
\set source_date_format 'YYYYMMDD'

-- ----------------------------------------------------------------------------
-- Custom Vocabulary Configuration
-- ----------------------------------------------------------------------------
-- Custom vocabulary ID prefix for Korean Traditional Medicine
\set custom_vocab_prefix 'KI'

-- Minimum concept_id for custom concepts (to avoid conflicts)
\set custom_concept_id_min 900000000

-- ----------------------------------------------------------------------------
-- Data Quality Configuration
-- ----------------------------------------------------------------------------
-- Maximum allowed gap days for era calculation
\set era_gap_days 30

-- Minimum birth year (for data validation)
\set min_birth_year 1900

-- Maximum birth year (for data validation)
\set max_birth_year 2025

-- ----------------------------------------------------------------------------
-- Backup Configuration
-- ----------------------------------------------------------------------------
-- Backup table prefix
\set backup_prefix 'backup_'

-- ----------------------------------------------------------------------------
-- Vocabulary Mapping Tables
-- ----------------------------------------------------------------------------
-- Working vocabulary mapping table
\set vocab_mapping_table 'wk_voca'

-- Jo mapping table (for drug/procedure mapping)
\set jo_mapping_table 'jo_mapping_table'

-- ----------------------------------------------------------------------------
-- Additional Configuration Notes
-- ----------------------------------------------------------------------------
-- 1. All concept IDs are based on OMOP CDM v5.x standard vocabularies
-- 2. Custom concept IDs (>= 900000000) are for Korean Traditional Medicine
-- 3. Date transformations assume source dates are stored as numeric YYYYMMDD
-- 4. Gender mapping: M -> 8507 (MALE), F -> 8532 (FEMALE)
-- 5. Race is set to Asian (38003585) for all Korean patients
-- 6. Visit types: 9201 (Inpatient), 9202 (Outpatient)
-- ============================================================================
