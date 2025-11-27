-- ============================================================================
-- Master Script: OMOP CDM Conversion Orchestrator
-- ============================================================================
-- Purpose: Execute all OMOP CDM conversion scripts in the correct order
--          - Provides transaction management
--          - Logs progress
--          - Handles errors gracefully
-- ============================================================================
-- Usage: psql -h hostname -U username -d database_name -f 00_master_script.sql
-- ============================================================================

\echo '============================================================================'
\echo 'OMOP CDM Conversion - Master Script'
\echo '============================================================================'
\echo 'This script will execute all conversion steps in sequence.'
\echo 'Estimated time: 30-60 minutes depending on data volume'
\echo '============================================================================'
\echo ''

-- Set error handling
\set ON_ERROR_STOP on

-- Set timing on to track execution time
\timing on

-- ----------------------------------------------------------------------------
-- Pre-execution Checks
-- ----------------------------------------------------------------------------
\echo 'Performing pre-execution checks...'

-- Check PostgreSQL version
SELECT version();

-- Check current database
SELECT current_database();

-- Check current user
SELECT current_user;

\echo ''
\echo 'Pre-execution checks complete.'
\echo ''

-- ----------------------------------------------------------------------------
-- Begin Transaction
-- ----------------------------------------------------------------------------
\echo '============================================================================'
\echo 'Starting OMOP CDM Conversion Process'
\echo '============================================================================'
\echo ''

-- Note: For large datasets, you may want to run scripts individually
-- rather than in a single transaction. Comment out BEGIN/COMMIT if needed.

BEGIN;

-- ----------------------------------------------------------------------------
-- Step 01: Setup and Backup
-- ----------------------------------------------------------------------------
\echo 'Executing Step 01: Setup and Backup...'
\i scripts/01_setup_and_backup.sql
\echo ''

-- ----------------------------------------------------------------------------
-- Step 02: Create Tables
-- ----------------------------------------------------------------------------
\echo 'Executing Step 02: Create Tables...'
\i scripts/02_create_tables.sql
\echo ''

-- ----------------------------------------------------------------------------
-- Step 03: Person and Observation Period
-- ----------------------------------------------------------------------------
\echo 'Executing Step 03: Person and Observation Period...'
\i scripts/03_person_and_observation_period.sql
\echo ''

-- ----------------------------------------------------------------------------
-- Step 04: Visit Occurrence
-- ----------------------------------------------------------------------------
\echo 'Executing Step 04: Visit Occurrence...'
\i scripts/04_visit_occurrence.sql
\echo ''

-- ----------------------------------------------------------------------------
-- Step 05: Condition Occurrence
-- ----------------------------------------------------------------------------
\echo 'Executing Step 05: Condition Occurrence...'
\i scripts/05_condition_occurrence.sql
\echo ''

-- ----------------------------------------------------------------------------
-- Step 06: Drug Exposure
-- ----------------------------------------------------------------------------
\echo 'Executing Step 06: Drug Exposure...'
\i scripts/06_drug_exposure.sql
\echo ''

-- ----------------------------------------------------------------------------
-- Step 07: Procedure Occurrence
-- ----------------------------------------------------------------------------
\echo 'Executing Step 07: Procedure Occurrence...'
\i scripts/07_procedure_occurrence.sql
\echo ''

-- ----------------------------------------------------------------------------
-- Step 08: Measurement
-- ----------------------------------------------------------------------------
\echo 'Executing Step 08: Measurement...'
\i scripts/08_measurement.sql
\echo ''

-- ----------------------------------------------------------------------------
-- Step 09: Observation
-- ----------------------------------------------------------------------------
\echo 'Executing Step 09: Observation...'
\i scripts/09_observation.sql
\echo ''

-- ----------------------------------------------------------------------------
-- Step 10: Era Tables
-- ----------------------------------------------------------------------------
\echo 'Executing Step 10: Era Tables...'
\i scripts/10_era_tables.sql
\echo ''

-- ----------------------------------------------------------------------------
-- Step 11: Vocabulary and Concepts
-- ----------------------------------------------------------------------------
\echo 'Executing Step 11: Vocabulary and Concepts...'
\i scripts/11_vocabulary.sql
\echo ''

-- ----------------------------------------------------------------------------
-- Step 12: Data Validation
-- ----------------------------------------------------------------------------
\echo 'Executing Step 12: Data Validation...'
\i scripts/12_validation.sql
\echo ''

-- ----------------------------------------------------------------------------
-- Commit Transaction
-- ----------------------------------------------------------------------------
COMMIT;

\echo ''
\echo '============================================================================'
\echo 'OMOP CDM Conversion Complete!'
\echo '============================================================================'
\echo ''
\echo 'All scripts executed successfully.'
\echo 'Please review the validation results above.'
\echo ''
\echo 'Next steps:'
\echo '  1. Review validation report for any data quality issues'
\echo '  2. Create indexes for performance optimization'
\echo '  3. Run ACHILLES for data quality assessment'
\echo '  4. Configure ATLAS for data exploration'
\echo ''
\echo '============================================================================'

-- Turn timing off
\timing off
