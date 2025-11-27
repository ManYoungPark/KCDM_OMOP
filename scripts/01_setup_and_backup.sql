-- ============================================================================
-- Script 01: Setup and Backup
-- ============================================================================
-- Purpose: Prepare the database for OMOP CDM conversion
--          - Create backup of existing tables
--          - Perform safety checks
--          - Set up logging
-- ============================================================================
-- Prerequisites: Source tables must exist
-- Execution: Run this script FIRST before any other conversion scripts
-- ============================================================================

\echo '============================================================================'
\echo 'OMOP CDM Conversion - Step 01: Setup and Backup'
\echo '============================================================================'

-- Load configuration
\i config.sql

-- ----------------------------------------------------------------------------
-- Safety Checks
-- ----------------------------------------------------------------------------
\echo 'Performing safety checks...'

-- Check if source patient table exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'data_patmst'
    ) THEN
        RAISE EXCEPTION 'Source table data_patmst does not exist. Cannot proceed.';
    END IF;
    RAISE NOTICE 'Source table data_patmst found.';
END $$;

-- ----------------------------------------------------------------------------
-- Backup Existing Tables
-- ----------------------------------------------------------------------------
\echo 'Creating backup of source tables...'

-- Backup patient master table
DO $$
BEGIN
    -- Drop backup table if it exists
    DROP TABLE IF EXISTS public.backup_data_patmst;
    
    -- Check if source table exists before renaming
    IF EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'data_patmst'
    ) THEN
        -- Rename original table to backup
        ALTER TABLE public.data_patmst RENAME TO backup_data_patmst;
        RAISE NOTICE 'Backed up data_patmst to backup_data_patmst';
    ELSE
        RAISE NOTICE 'Table data_patmst does not exist, skipping backup';
    END IF;
END $$;

-- ----------------------------------------------------------------------------
-- Create Backup Schema (Optional)
-- ----------------------------------------------------------------------------
\echo 'Setting up backup schema...'

-- Create a dedicated backup schema for safety
CREATE SCHEMA IF NOT EXISTS cdm_backup;

\echo 'Backup schema created: cdm_backup'

-- ----------------------------------------------------------------------------
-- Log Setup Information
-- ----------------------------------------------------------------------------
\echo 'Setup Information:'
\echo '  - Backup schema: cdm_backup'
\echo '  - Patient table backed up: backup_data_patmst'
\echo '  - Ready for OMOP CDM table creation'

\echo '============================================================================'
\echo 'Step 01 Complete: Setup and Backup'
\echo 'Next Step: Run 02_create_tables.sql'
\echo '============================================================================'
