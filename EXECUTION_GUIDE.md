# OMOP CDM Conversion - Execution Guide

## 📋 Table of Contents

1. [Pre-Execution Checklist](#pre-execution-checklist)
2. [Environment Setup](#environment-setup)
3. [Configuration](#configuration)
4. [Execution Methods](#execution-methods)
5. [Script-by-Script Guide](#script-by-script-guide)
6. [Post-Execution Steps](#post-execution-steps)
7. [Rollback Procedures](#rollback-procedures)
8. [Common Errors and Solutions](#common-errors-and-solutions)

---

## Pre-Execution Checklist

Before running the conversion scripts, ensure you have completed the following:

### ✅ Database Requirements

- [ ] PostgreSQL 12+ installed and running
- [ ] Database created with sufficient storage (estimate 2-3x source data size)
- [ ] User account with CREATE, INSERT, UPDATE, DELETE privileges
- [ ] `psql` command-line tool accessible

### ✅ Source Data Requirements

- [ ] **Patient master table** (`data_patmst`) loaded
  - Required columns: `PATID`, `SEX`, `PRSNIDPRE`
- [ ] **Inpatient admission table** (`data_ipdacpt_pmy`) loaded
  - Required columns: `PATID`, `ADMACPTDATE`, `DSCHRGCALCDATE`
- [ ] **Outpatient visit table** (`data_opdacpt_pmy`) loaded
  - Required columns: `PATID`, `OPDDATE`
- [ ] **Diagnosis table** (`data_dxofpat_pmy`) loaded
  - Required columns: `PATID`, `DXCODE`, `ORDERDATE`
- [ ] **Order table** (`data_orderinfos2020_pmy`) loaded (optional)
  - Required columns: `PATID`, `ORDERCODE`, `ORDERDATE`
- [ ] **Numeric results table** (`data_resultofnum`) loaded (optional)
  - Required columns: `PATID`, `RESULTITEMCODE`, `RESULTDATE`, `NUMRESULTVAL`

### ✅ Preprocessed Data Requirements

These tables should be created via R or other preprocessing tools:

- [ ] `add_condition_new` - Preprocessed condition data with mapped concept IDs
- [ ] `add_drug_Data` - Preprocessed drug data with mapped concept IDs
- [ ] `add_proc_Data` - Preprocessed procedure data with mapped concept IDs
- [ ] `add_to_measurement` - Preprocessed measurement data (optional)

### ✅ Vocabulary Requirements

- [ ] OMOP vocabulary tables loaded in `voca_sample` schema:
  - `vocabulary`
  - `concept`
  - `concept_synonym`
  - `concept_relationship`
  - `concept_ancestor`
- [ ] Custom vocabulary mapping tables:
  - `wk_voca` - Working vocabulary for prefix-based mapping
  - `jo_mapping_table` - Concept mapping table
- [ ] Custom vocabulary preprocessed tables:
  - `add_to_vocabulrary_r2`
  - `add_to_concept`
  - `addto_concept_synonym`

---

## Environment Setup

### 1. Database Connection

Test your database connection:

```bash
psql -h localhost -U your_username -d your_database -c "SELECT version();"
```

### 2. Set Environment Variables (Optional)

For convenience, set environment variables:

```bash
export PGHOST=localhost
export PGPORT=5432
export PGDATABASE=your_database
export PGUSER=your_username
export PGPASSWORD=your_password
```

### 3. Verify Source Tables

Check that all required source tables exist:

```sql
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN (
    'data_patmst',
    'data_ipdacpt_pmy',
    'data_opdacpt_pmy',
    'data_dxofpat_pmy'
  );
```

---

## Configuration

### 1. Review Configuration File

Open `config.sql` and review all settings:

```sql
-- Schema configuration
\set cdm_schema 'public'
\set vocab_schema 'voca_sample'

-- Source table names
\set source_patient_table 'backup_data_patmst'
-- ... etc
```

### 2. Customize for Your Environment

Update the following based on your setup:

- **Schema names**: If using different schemas
- **Table names**: If source tables have different names
- **Concept IDs**: Verify against your vocabulary version
- **Date formats**: Adjust if not using YYYYMMDD

### 3. Validate Configuration

Run a quick validation:

```sql
\i config.sql
\echo :cdm_schema
\echo :vocab_schema
```

---

## Execution Methods

### Method 1: Master Script (Recommended for First-Time Users)

Execute all scripts in one transaction:

```bash
psql -h localhost -U your_username -d your_database -f scripts/00_master_script.sql > conversion_log.txt 2>&1
```

**Pros:**
- Simple one-command execution
- All-or-nothing transaction (automatic rollback on error)
- Progress logging

**Cons:**
- Requires sufficient memory for entire transaction
- Cannot inspect intermediate results
- Longer execution time

**Estimated Time:** 30-60 minutes for moderate datasets (1-10M records)

### Method 2: Individual Scripts (Recommended for Large Datasets)

Execute scripts one at a time:

```bash
# Step 1
psql -h localhost -U your_username -d your_database -f scripts/01_setup_and_backup.sql

# Step 2
psql -h localhost -U your_username -d your_database -f scripts/02_create_tables.sql

# ... continue with remaining scripts
```

**Pros:**
- Can inspect results after each step
- Better for troubleshooting
- Can resume from failure point

**Cons:**
- Requires manual execution of each script
- No automatic rollback across scripts

### Method 3: Interactive Execution

Run scripts interactively in `psql`:

```bash
psql -h localhost -U your_username -d your_database

-- Inside psql:
\i scripts/01_setup_and_backup.sql
-- Review results
\i scripts/02_create_tables.sql
-- Review results
-- ... etc
```

---

## Script-by-Script Guide

### Script 01: Setup and Backup

**Purpose:** Prepare database and backup existing tables

**Expected Output:**
```
Source table data_patmst found.
Backed up data_patmst to backup_data_patmst
Backup schema created: cdm_backup
```

**Verification:**
```sql
SELECT COUNT(*) FROM backup_data_patmst;
```

**Estimated Time:** 1-2 minutes

---

### Script 02: Create Tables

**Purpose:** Create all OMOP CDM table structures

**Expected Output:**
```
Creating PERSON table...
Creating OBSERVATION_PERIOD table...
Creating VISIT_OCCURRENCE table...
... (all tables created)
```

**Verification:**
```sql
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('person', 'visit_occurrence', 'condition_occurrence');
```

**Estimated Time:** 1-2 minutes

---

### Script 03: Person and Observation Period

**Purpose:** Load patient demographics and observation periods

**Expected Output:**
```
PERSON table populated successfully.
person_count: 50000
OBSERVATION_PERIOD table populated successfully.
observation_period_count: 75000
```

**Verification:**
```sql
SELECT COUNT(*) AS person_count FROM person;
SELECT COUNT(*) AS invalid_gender FROM person WHERE gender_concept_id = 0;
```

**Estimated Time:** 2-5 minutes

---

### Script 04: Visit Occurrence

**Purpose:** Load inpatient and outpatient visits

**Expected Output:**
```
Inpatient visits loaded successfully.
inpatient_visit_count: 25000
Outpatient visits loaded successfully.
outpatient_visit_count: 150000
```

**Verification:**
```sql
SELECT visit_concept_id, COUNT(*) 
FROM visit_occurrence 
GROUP BY visit_concept_id;
```

**Estimated Time:** 3-10 minutes

---

### Script 05: Condition Occurrence

**Purpose:** Load diagnosis/condition data

**Expected Output:**
```
Condition occurrence data loaded from preprocessed table.
condition_count: 500000
mapped_conditions: 450000
unmapped_conditions: 50000
```

**Verification:**
```sql
SELECT 
  COUNT(*) AS total,
  COUNT(CASE WHEN condition_concept_id IS NOT NULL THEN 1 END) AS mapped
FROM condition_occurrence;
```

**Estimated Time:** 5-15 minutes

---

### Script 06: Drug Exposure

**Purpose:** Load medication/prescription data

**Expected Output:**
```
Drug exposure data loaded from preprocessed table.
drug_exposure_count: 800000
```

**Verification:**
```sql
SELECT COUNT(*) AS drug_count FROM drug_exposure;
SELECT COUNT(DISTINCT drug_concept_id) AS unique_drugs FROM drug_exposure;
```

**Estimated Time:** 5-15 minutes

---

### Script 07: Procedure Occurrence

**Purpose:** Load medical procedure data

**Expected Output:**
```
Procedure occurrence data loaded from preprocessed table.
procedure_count: 200000
```

**Verification:**
```sql
SELECT COUNT(*) AS procedure_count FROM procedure_occurrence;
```

**Estimated Time:** 3-10 minutes

---

### Script 08: Measurement

**Purpose:** Load laboratory test results

**Expected Output:**
```
Measurement data loaded from numeric results.
measurement_count_from_source: 1000000
mapped_measurements: 950000
```

**Verification:**
```sql
SELECT 
  COUNT(*) AS total,
  COUNT(CASE WHEN value_as_number IS NOT NULL THEN 1 END) AS with_values
FROM measurement;
```

**Estimated Time:** 10-20 minutes

---

### Script 09: Observation

**Purpose:** Load clinical observation data

**Expected Output:**
```
Observation data loaded from diagnosis codes.
observation_count: 300000
mapped_observations: 280000
```

**Verification:**
```sql
SELECT COUNT(*) AS observation_count FROM observation;
```

**Estimated Time:** 5-10 minutes

---

### Script 10: Era Tables

**Purpose:** Generate condition and drug era tables

**Expected Output:**
```
CONDITION_ERA table generated.
condition_era_count: 100000
DRUG_ERA table generated.
drug_era_count: 150000
```

**Verification:**
```sql
SELECT COUNT(*) FROM condition_era;
SELECT COUNT(*) FROM drug_era;
```

**Estimated Time:** 5-10 minutes

---

### Script 11: Vocabulary and Concepts

**Purpose:** Load custom vocabularies and concepts

**Expected Output:**
```
Custom vocabularies inserted.
Custom concepts inserted.
custom_concept_count: 50000
```

**Verification:**
```sql
SELECT COUNT(*) FROM voca_sample.concept WHERE concept_id >= 900000000;
```

**Estimated Time:** 3-5 minutes

---

### Script 12: Data Validation

**Purpose:** Validate data quality and completeness

**Expected Output:**
```
SECTION 1: Record Count Summary
SECTION 2: Required Field Validation
SECTION 3: Referential Integrity Checks
... (detailed validation report)
```

**Action Required:** Review all validation results and address any issues

**Estimated Time:** 2-5 minutes

---

## Post-Execution Steps

### 1. Review Validation Report

Carefully review the output from `12_validation.sql`:

- Check for NULL values in required fields
- Verify referential integrity
- Review concept mapping percentages
- Identify any data quality issues

### 2. Create Indexes

For better query performance, create indexes:

```sql
-- Person indexes
CREATE INDEX idx_person_id ON person(person_id);

-- Visit indexes
CREATE INDEX idx_visit_person ON visit_occurrence(person_id);
CREATE INDEX idx_visit_concept ON visit_occurrence(visit_concept_id);
CREATE INDEX idx_visit_dates ON visit_occurrence(visit_start_date, visit_end_date);

-- Condition indexes
CREATE INDEX idx_condition_person ON condition_occurrence(person_id);
CREATE INDEX idx_condition_concept ON condition_occurrence(condition_concept_id);
CREATE INDEX idx_condition_visit ON condition_occurrence(visit_occurrence_id);

-- Drug indexes
CREATE INDEX idx_drug_person ON drug_exposure(person_id);
CREATE INDEX idx_drug_concept ON drug_exposure(drug_concept_id);

-- Add more indexes as needed for your use case
```

### 3. Run ANALYZE

Update table statistics for query optimization:

```sql
ANALYZE person;
ANALYZE visit_occurrence;
ANALYZE condition_occurrence;
ANALYZE drug_exposure;
ANALYZE procedure_occurrence;
ANALYZE measurement;
ANALYZE observation;
```

### 4. Run ACHILLES (Optional)

For comprehensive data quality assessment:

```bash
# Install ACHILLES if not already installed
# Run ACHILLES analysis
```

---

## Rollback Procedures

### If Using Master Script (Single Transaction)

If an error occurs, the transaction will automatically rollback. No manual intervention needed.

### If Running Individual Scripts

To rollback changes:

```sql
-- Drop all OMOP CDM tables
DROP TABLE IF EXISTS person CASCADE;
DROP TABLE IF EXISTS observation_period CASCADE;
DROP TABLE IF EXISTS visit_occurrence CASCADE;
DROP TABLE IF EXISTS condition_occurrence CASCADE;
DROP TABLE IF EXISTS drug_exposure CASCADE;
DROP TABLE IF EXISTS procedure_occurrence CASCADE;
DROP TABLE IF EXISTS measurement CASCADE;
DROP TABLE IF EXISTS observation CASCADE;
DROP TABLE IF EXISTS condition_era CASCADE;
DROP TABLE IF EXISTS drug_era CASCADE;

-- Restore original patient table
ALTER TABLE backup_data_patmst RENAME TO data_patmst;
```

---

## Common Errors and Solutions

### Error: "relation does not exist"

**Cause:** Source table not found

**Solution:**
1. Verify table name spelling
2. Check schema (add schema prefix if needed)
3. Ensure table is loaded before running script

```sql
-- Check if table exists
SELECT * FROM pg_tables WHERE tablename = 'your_table_name';
```

---

### Error: "invalid input syntax for type date"

**Cause:** Date format mismatch

**Solution:**
1. Verify source dates are in YYYYMMDD numeric format
2. Check for NULL or invalid date values
3. Adjust date transformation logic if needed

```sql
-- Check date format
SELECT "ORDERDATE", TO_DATE(CAST("ORDERDATE" AS VARCHAR), 'YYYYMMDD')
FROM data_dxofpat_pmy
LIMIT 10;
```

---

### Error: "out of memory"

**Cause:** Insufficient memory for large transaction

**Solution:**
1. Run scripts individually instead of master script
2. Increase PostgreSQL memory settings
3. Process data in batches

```sql
-- Increase work_mem temporarily
SET work_mem = '256MB';
```

---

### Error: "duplicate key value violates unique constraint"

**Cause:** Duplicate IDs in source data

**Solution:**
1. Check for duplicate person_ids
2. Use DISTINCT in SELECT statements
3. Add ON CONFLICT clause

```sql
-- Find duplicates
SELECT person_id, COUNT(*) 
FROM person 
GROUP BY person_id 
HAVING COUNT(*) > 1;
```

---

### Warning: Low concept mapping percentage

**Cause:** Vocabulary mapping table incomplete

**Solution:**
1. Verify mapping tables are loaded
2. Check concept code formats match
3. Review unmapped codes

```sql
-- Find unmapped codes
SELECT DISTINCT condition_concept_id_wk
FROM condition_occurrence
WHERE condition_concept_id IS NULL
LIMIT 100;
```

---

## Performance Tips

1. **Disable Indexes During Load**: Drop indexes before loading, recreate after
2. **Use COPY Instead of INSERT**: For very large datasets
3. **Increase Checkpoint Segments**: Adjust PostgreSQL configuration
4. **Monitor Disk Space**: Ensure 2-3x source data size available
5. **Run During Off-Peak Hours**: Minimize impact on other users

---

## Next Steps After Conversion

1. **Data Quality Assessment**: Run ACHILLES
2. **Data Exploration**: Set up ATLAS
3. **Documentation**: Document any customizations made
4. **Backup**: Create full database backup
5. **Share**: Distribute to collaborators

---

**Questions or Issues?** Refer to the main [README.md](README.md) or [DATA_MAPPING_REFERENCE.md](DATA_MAPPING_REFERENCE.md)
