-- ============================================================================
-- Script 11: Vocabulary and Concepts
-- ============================================================================
-- Purpose: Load custom vocabulary and concept data
--          - Insert custom Korean Traditional Medicine vocabularies
--          - Load custom concepts
--          - Load concept synonyms
-- ============================================================================
-- Prerequisites: Scripts 01-10 must be completed
--                OMOP vocabulary tables must exist in voca_sample schema
--                Preprocessed tables must exist:
--                  - add_to_vocabulrary_r2
--                  - add_to_concept
--                  - addto_concept_synonym
-- Execution: Run this script ELEVENTH
-- ============================================================================

\echo '============================================================================'
\echo 'OMOP CDM Conversion - Step 11: Vocabulary and Concepts'
\echo '============================================================================'

-- Load configuration
\i ../config.sql

-- ----------------------------------------------------------------------------
-- Insert Custom Vocabularies
-- ----------------------------------------------------------------------------
\echo 'Inserting custom vocabularies...'

-- Check if vocabulary table exists
DO $$
BEGIN
    IF EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'voca_sample' 
        AND tablename = 'vocabulary'
    ) THEN
        -- Insert custom vocabularies from preprocessed table
        INSERT INTO voca_sample.vocabulary (
            vocabulary_id, 
            vocabulary_name, 
            vocabulary_reference, 
            vocabulary_version, 
            vocabulary_concept_id
        )
        SELECT 
            vocabulary_id, 
            vocabulary_name, 
            vocabulary_reference, 
            vocabulary_version, 
            CAST(vocabulary_concept_id AS INTEGER)
        FROM 
            voca_sample.add_to_vocabulrary_r2
        WHERE NOT EXISTS (
            SELECT 1 FROM voca_sample.vocabulary v
            WHERE v.vocabulary_id = add_to_vocabulrary_r2.vocabulary_id
        );
        
        RAISE NOTICE 'Custom vocabularies inserted.';
    ELSE
        RAISE NOTICE 'Vocabulary table does not exist in voca_sample schema.';
    END IF;
END $$;

-- Check Korean Traditional Medicine vocabularies
SELECT 
    vocabulary_id,
    vocabulary_name,
    vocabulary_version
FROM 
    voca_sample.vocabulary 
WHERE 
    vocabulary_id LIKE 'KI%'
ORDER BY 
    vocabulary_id;

-- ----------------------------------------------------------------------------
-- Insert Custom Concepts
-- ----------------------------------------------------------------------------
\echo 'Inserting custom concepts...'

-- Check if concept table exists
DO $$
BEGIN
    IF EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'voca_sample' 
        AND tablename = 'concept'
    ) THEN
        -- Insert custom concepts from preprocessed table
        INSERT INTO voca_sample.concept (
            concept_id, 
            concept_name, 
            domain_id, 
            vocabulary_id, 
            concept_class_id,
            standard_concept, 
            concept_code, 
            valid_start_date, 
            valid_end_date, 
            invalid_reason
        )
        SELECT 
            concept_id, 
            concept_name, 
            domain_id, 
            vocabulary_id, 
            concept_class_id,
            standard_concept, 
            concept_code, 
            TO_DATE(valid_start_date, 'YYYY-MM-DD'),
            TO_DATE(valid_end_date, 'YYYY-MM-DD'),
            invalid_reason
        FROM 
            voca_sample.add_to_concept
        WHERE NOT EXISTS (
            SELECT 1 FROM voca_sample.concept c
            WHERE c.concept_id = add_to_concept.concept_id
        );
        
        RAISE NOTICE 'Custom concepts inserted.';
    ELSE
        RAISE NOTICE 'Concept table does not exist in voca_sample schema.';
    END IF;
END $$;

-- Check custom concepts (concept_id >= 900000000)
SELECT 
    COUNT(*) AS custom_concept_count
FROM 
    voca_sample.concept 
WHERE 
    concept_id >= 900000000;

-- ----------------------------------------------------------------------------
-- Insert Concept Synonyms
-- ----------------------------------------------------------------------------
\echo 'Inserting concept synonyms...'

-- Check if concept_synonym table exists
DO $$
BEGIN
    IF EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'voca_sample' 
        AND tablename = 'concept_synonym'
    ) THEN
        -- Insert concept synonyms from preprocessed table
        INSERT INTO voca_sample.concept_synonym (
            concept_id, 
            concept_synonym_name, 
            language_concept_id
        )
        SELECT 
            concept_id, 
            concept_synonym_name, 
            language_concept_id
        FROM 
            voca_sample.addto_concept_synonym
        WHERE NOT EXISTS (
            SELECT 1 FROM voca_sample.concept_synonym cs
            WHERE cs.concept_id = addto_concept_synonym.concept_id
              AND cs.concept_synonym_name = addto_concept_synonym.concept_synonym_name
        );
        
        RAISE NOTICE 'Concept synonyms inserted.';
    ELSE
        RAISE NOTICE 'Concept synonym table does not exist in voca_sample schema.';
    END IF;
END $$;

-- Check custom concept synonyms
SELECT 
    COUNT(*) AS custom_synonym_count
FROM 
    voca_sample.concept_synonym 
WHERE 
    concept_id >= 900000000;

-- ----------------------------------------------------------------------------
-- Summary Statistics
-- ----------------------------------------------------------------------------
\echo 'Vocabulary and concept summary:'

-- Vocabulary summary
SELECT 
    'VOCABULARY' AS table_name,
    COUNT(*) AS total_count,
    COUNT(CASE WHEN vocabulary_id LIKE 'KI%' THEN 1 END) AS korean_traditional_medicine_count
FROM 
    voca_sample.vocabulary;

-- Concept summary
SELECT 
    'CONCEPT' AS table_name,
    COUNT(*) AS total_count,
    COUNT(CASE WHEN concept_id >= 900000000 THEN 1 END) AS custom_concept_count
FROM 
    voca_sample.concept;

-- Concept synonym summary
SELECT 
    'CONCEPT_SYNONYM' AS table_name,
    COUNT(*) AS total_count,
    COUNT(CASE WHEN concept_id >= 900000000 THEN 1 END) AS custom_synonym_count
FROM 
    voca_sample.concept_synonym;

\echo '============================================================================'
\echo 'Step 11 Complete: Vocabulary and Concepts Loaded'
\echo 'Next Step: Run 12_validation.sql'
\echo '============================================================================'
