# OMOP CDM Data Mapping Reference

## 📋 Table of Contents

1. [Overview](#overview)
2. [Source to Target Table Mappings](#source-to-target-table-mappings)
3. [Concept ID Reference](#concept-id-reference)
4. [Data Transformation Rules](#data-transformation-rules)
5. [Korean Traditional Medicine Mappings](#korean-traditional-medicine-mappings)
6. [Vocabulary Tables](#vocabulary-tables)

---

## Overview

This document provides detailed information about how source data is mapped to OMOP CDM tables, including:

- Source table to OMOP CDM table mappings
- Field-level transformations
- OMOP concept IDs and their meanings
- Custom vocabulary mappings for Korean Traditional Medicine

---

## Source to Target Table Mappings

### PERSON Table

**Source Table:** `backup_data_patmst`

| Source Column | Target Column | Transformation | Notes |
|--------------|---------------|----------------|-------|
| `PATID` | `person_id` | Direct mapping | Unique patient identifier |
| `SEX` | `gender_concept_id` | M→8507, F→8532 | OMOP gender concepts |
| `PRSNIDPRE` | `year_of_birth` | 1900 + LEFT(2 digits) | Korean ID format |
| (constant) | `race_concept_id` | 38003585 | Asian race |
| (constant) | `ethnicity_concept_id` | 38003564 | Not Hispanic/Latino |

**Example Transformation:**
```sql
-- Source: PATID=12345, SEX='M', PRSNIDPRE='850101'
-- Target: person_id=12345, gender_concept_id=8507, year_of_birth=1985
```

---

### OBSERVATION_PERIOD Table

**Source Table:** `data_ipdacpt_pmy`

| Source Column | Target Column | Transformation | Notes |
|--------------|---------------|----------------|-------|
| `PATID` | `person_id` | Direct mapping | Links to PERSON |
| `ADMACPTDATE` | `observation_period_start_date` | TO_DATE(YYYYMMDD) | Admission date |
| `DSCHRGCALCDATE` | `observation_period_end_date` | TO_DATE(YYYYMMDD) | Discharge date |
| (constant) | `period_type_concept_id` | 44814725 | EHR encounter records |

---

### VISIT_OCCURRENCE Table

**Inpatient Visits**

**Source Table:** `data_ipdacpt_pmy`

| Source Column | Target Column | Transformation | Notes |
|--------------|---------------|----------------|-------|
| `PATID` | `person_id` | Direct mapping | |
| `ADMACPTDATE` | `visit_start_date` | TO_DATE(YYYYMMDD) | |
| `DSCHRGCALCDATE` | `visit_end_date` | TO_DATE(YYYYMMDD) | |
| (constant) | `visit_concept_id` | 9201 | Inpatient Visit |
| (constant) | `visit_type_concept_id` | 44818518 | EHR |

**Outpatient Visits**

**Source Table:** `data_opdacpt_pmy`

| Source Column | Target Column | Transformation | Notes |
|--------------|---------------|----------------|-------|
| `PATID` | `person_id` | Direct mapping | |
| `OPDDATE` | `visit_start_date` | TO_DATE(YYYYMMDD) | |
| `OPDDATE` | `visit_end_date` | TO_DATE(YYYYMMDD) | Same day visit |
| (constant) | `visit_concept_id` | 9202 | Outpatient Visit |
| (constant) | `visit_type_concept_id` | 44818518 | EHR |

---

### CONDITION_OCCURRENCE Table

**Source Table:** `add_condition_new` (preprocessed)

| Source Column | Target Column | Transformation | Notes |
|--------------|---------------|----------------|-------|
| `person_id` | `person_id` | Direct mapping | |
| `condition_concept_id` | `condition_concept_id` | Direct mapping | Already mapped |
| `condition_start_date` | `condition_start_date` | Direct mapping | |
| `condition_end_date` | `condition_end_date` | Direct mapping | |
| (constant) | `condition_type_concept_id` | 32817 | EHR |

**Alternative Mapping (from raw diagnosis data):**

**Source Table:** `data_dxofpat_pmy`

| Source Column | Target Column | Transformation | Notes |
|--------------|---------------|----------------|-------|
| `PATID` | `person_id` | Direct mapping | |
| `DXCODE` | `condition_concept_id_wk` | Direct mapping | Working field |
| `ORDERDATE` | `condition_start_date` | TO_DATE(YYYYMMDD) | |
| `ORDERDATE` | `condition_end_date` | TO_DATE(YYYYMMDD) | Same as start |

**Concept Mapping Process:**
1. Extract first 3 characters of `DXCODE` → `condition_concept_id_prefix`
2. Join with `wk_voca` table on `concept_code`
3. Map to `concept_id`

---

### DRUG_EXPOSURE Table

**Source Table:** `add_drug_Data` (preprocessed)

| Source Column | Target Column | Transformation | Notes |
|--------------|---------------|----------------|-------|
| `PATID` | `person_id` | Direct mapping | |
| `concept_id` | `drug_concept_id` | Direct mapping | Already mapped |
| `ORDERDATE` | `drug_exposure_start_date` | TO_DATE(YYYYMMDD) | |
| `ORDERDATE` | `drug_exposure_end_date` | TO_DATE(YYYYMMDD) | Same as start |
| (constant) | `drug_type_concept_id` | 38000177 | EHR prescription |

---

### PROCEDURE_OCCURRENCE Table

**Source Table:** `add_proc_Data` (preprocessed)

| Source Column | Target Column | Transformation | Notes |
|--------------|---------------|----------------|-------|
| `PATID` | `person_id` | Direct mapping | |
| `concept_id` | `procedure_concept_id` | Direct mapping | Already mapped |
| `ORDERDATE` | `procedure_date` | TO_DATE(YYYYMMDD) | |
| (constant) | `procedure_type_concept_id` | 38000275 | EHR |

---

### MEASUREMENT Table

**Source Table:** `data_resultofnum` (joined with `jo_mapping_table`)

| Source Column | Target Column | Transformation | Notes |
|--------------|---------------|----------------|-------|
| `PATID` | `person_id` | Direct mapping | |
| `RESULTITEMCODE` | `measurement_source_value` | Direct mapping | |
| `RESULTDATE` | `measurement_date` | TO_DATE(YYYYMMDD) | |
| `NUMRESULTVAL` | `value_as_number` | Direct mapping | Numeric value |
| (constant) | `measurement_type_concept_id` | 44818701 | Lab result |

**Concept Mapping:**
- Join `RESULTITEMCODE` with `jo_mapping_table.code`
- Map to `concept_id`

---

### OBSERVATION Table

**Source Table:** `data_dxofpat_pmy`

| Source Column | Target Column | Transformation | Notes |
|--------------|---------------|----------------|-------|
| `PATID` | `person_id` | Direct mapping | |
| `DXCODE` | `observation_concept_id_wk` | Direct mapping | Working field |
| `ORDERDATE` | `observation_date` | TO_DATE(YYYYMMDD) | |
| (constant) | `observation_type_concept_id` | 44786627 | EHR |

**Concept Mapping Process:**
1. Extract first 3 characters → `observation_concept_id_prefix`
2. Join with `wk_voca` table
3. Map to `concept_id`
4. Unmapped codes → 4336011 (default)

---

### CONDITION_ERA Table

**Source:** Aggregated from `condition_occurrence`

| Aggregation | Target Column | Logic |
|------------|---------------|-------|
| GROUP BY person_id, condition_concept_id | - | Grouping key |
| MIN(condition_start_date) | `condition_era_start_date` | Earliest occurrence |
| MAX(condition_end_date) | `condition_era_end_date` | Latest occurrence |
| COUNT(*) | `condition_occurrence_count` | Number of occurrences |

---

### DRUG_ERA Table

**Source:** Aggregated from `drug_exposure`

| Aggregation | Target Column | Logic |
|------------|---------------|-------|
| GROUP BY person_id, drug_concept_id | - | Grouping key |
| MIN(drug_exposure_start_date) | `drug_era_start_date` | Earliest exposure |
| MAX(drug_exposure_end_date) | `drug_era_end_date` | Latest exposure |
| COUNT(*) | `drug_exposure_count` | Number of exposures |

---

## Concept ID Reference

### Gender Concepts

| Concept ID | Concept Name | Source Value |
|-----------|-------------|--------------|
| 8507 | MALE | M |
| 8532 | FEMALE | F |
| 0 | Unknown | Other/NULL |

### Race Concepts

| Concept ID | Concept Name | Usage |
|-----------|-------------|-------|
| 38003585 | Asian | Default for Korean patients |

### Ethnicity Concepts

| Concept ID | Concept Name | Usage |
|-----------|-------------|-------|
| 38003564 | Not Hispanic or Latino | Default for Korean patients |

### Visit Type Concepts

| Concept ID | Concept Name | Description |
|-----------|-------------|-------------|
| 9201 | Inpatient Visit | Hospital admission |
| 9202 | Outpatient Visit | Clinic/ambulatory visit |
| 44818518 | EHR | Visit type concept |

### Observation Period Type

| Concept ID | Concept Name | Description |
|-----------|-------------|-------------|
| 44814725 | Period while enrolled in insurance | EHR encounter records |

### Condition Type

| Concept ID | Concept Name | Description |
|-----------|-------------|-------------|
| 32817 | EHR | Condition from EHR |

### Drug Type

| Concept ID | Concept Name | Description |
|-----------|-------------|-------------|
| 38000177 | Prescription written | EHR prescription |

### Procedure Type

| Concept ID | Concept Name | Description |
|-----------|-------------|-------------|
| 38000275 | EHR order list entry | EHR procedure |

### Measurement Type

| Concept ID | Concept Name | Description |
|-----------|-------------|-------------|
| 44818701 | From physical examination | Lab result |

### Observation Type

| Concept ID | Concept Name | Description |
|-----------|-------------|-------------|
| 44786627 | Clinical observation | EHR observation |
| 4336011 | Observation recorded | Default for unmapped |

---

## Data Transformation Rules

### Date Transformations

**Source Format:** Numeric YYYYMMDD (e.g., 20200115)

**Transformation:**
```sql
TO_DATE(CAST(source_column AS VARCHAR), 'YYYYMMDD')
```

**Examples:**
- `20200115` → `2020-01-15`
- `20191231` → `2019-12-31`

### Birth Year Calculation

**Source:** Korean ID number (`PRSNIDPRE`)

**Format:** YYMMDD (first 6 digits)

**Transformation:**
```sql
1900 + CAST(LEFT(CAST("PRSNIDPRE" AS TEXT), 2) AS INTEGER)
```

**Examples:**
- `850101` → 1985
- `920315` → 1992
- `051225` → 2005

### Gender Mapping

**Source Values:**
- `M` → Male
- `F` → Female
- Other → Unknown (concept_id = 0)

**Transformation:**
```sql
CASE "SEX"
    WHEN 'M' THEN 8507
    WHEN 'F' THEN 8532
    ELSE 0
END
```

### Concept Code Prefix Mapping

**Used for:** Diagnosis codes, observation codes

**Process:**
1. Extract first 3 characters of code
2. Use as lookup key in vocabulary table
3. Map to standard OMOP concept

**Example:**
- Source code: `J45001`
- Prefix: `J45`
- Lookup in `wk_voca` where `concept_code = 'J45'`
- Map to `concept_id`

---

## Korean Traditional Medicine Mappings

### Custom Vocabulary IDs

| Vocabulary ID | Vocabulary Name | Description |
|--------------|----------------|-------------|
| KI_* | Korean Traditional Medicine | Custom vocabularies |

### Custom Concept ID Range

**Range:** >= 900000000

**Purpose:** Avoid conflicts with standard OMOP concepts

### Vocabulary Tables

**Source Tables for Custom Vocabularies:**

1. **add_to_vocabulrary_r2**
   - Contains custom vocabulary definitions
   - Inserted into `voca_sample.vocabulary`

2. **add_to_concept**
   - Contains custom concept definitions
   - Inserted into `voca_sample.concept`

3. **addto_concept_synonym**
   - Contains Korean language synonyms
   - Inserted into `voca_sample.concept_synonym`

### Mapping Tables

**wk_voca (Working Vocabulary)**
- Used for prefix-based mapping
- Maps diagnosis/observation code prefixes to concepts

**jo_mapping_table**
- Used for drug/procedure/measurement mapping
- Contains `code` → `concept_id` mappings
- Includes `concept_class_id` for domain classification

---

## Vocabulary Tables

### Standard OMOP Vocabulary Tables

Located in `voca_sample` schema:

1. **vocabulary**
   - Vocabulary metadata
   - Columns: vocabulary_id, vocabulary_name, vocabulary_reference, vocabulary_version

2. **concept**
   - All OMOP concepts
   - Columns: concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code

3. **concept_synonym**
   - Alternative names for concepts
   - Columns: concept_id, concept_synonym_name, language_concept_id

4. **concept_relationship**
   - Relationships between concepts
   - Columns: concept_id_1, concept_id_2, relationship_id

5. **concept_ancestor**
   - Hierarchical relationships
   - Columns: ancestor_concept_id, descendant_concept_id

### Custom Mapping Tables

**wk_voca**
- Purpose: Prefix-based code mapping
- Structure: concept_code (VARCHAR), concept_id (INTEGER)
- Usage: Map first 3 characters of diagnosis codes

**jo_mapping_table**
- Purpose: Comprehensive code mapping
- Structure: code (VARCHAR), concept_id (INTEGER), concept_class_id (VARCHAR)
- Usage: Map drugs, procedures, measurements
- Domains: Drug, Procedure, Measurement

---

## Preprocessing Requirements

### Required Preprocessing Steps

Before running the OMOP CDM conversion, the following preprocessing must be completed (typically in R):

1. **Condition Mapping**
   - Input: `data_dxofpat_pmy`
   - Output: `add_condition_new`
   - Process: Map diagnosis codes to OMOP condition concepts

2. **Drug Mapping**
   - Input: `data_orderinfos2020_pmy`
   - Output: `add_drug_Data`
   - Process: Map drug codes to OMOP drug concepts
   - Filter: Exclude procedures (concept_class_id != 'Procedure')

3. **Procedure Mapping**
   - Input: `data_orderinfos2020_pmy`
   - Output: `add_proc_Data`
   - Process: Map procedure codes to OMOP procedure concepts
   - Filter: Only procedures (concept_class_id = 'Procedure')

4. **Measurement Mapping** (Optional)
   - Input: Various measurement sources
   - Output: `add_to_measurement`
   - Process: Map measurement codes to OMOP measurement concepts

5. **Vocabulary Preparation**
   - Input: Korean Traditional Medicine vocabularies
   - Output: `add_to_vocabulrary_r2`, `add_to_concept`, `addto_concept_synonym`
   - Process: Prepare custom vocabularies for insertion

---

## Data Quality Considerations

### Required Fields

Each OMOP CDM table has required fields that must not be NULL:

- **PERSON**: person_id, gender_concept_id, year_of_birth, race_concept_id, ethnicity_concept_id
- **VISIT_OCCURRENCE**: visit_occurrence_id, person_id, visit_concept_id, visit_start_date, visit_end_date, visit_type_concept_id
- **CONDITION_OCCURRENCE**: condition_occurrence_id, person_id, condition_concept_id, condition_start_date, condition_type_concept_id

### Date Validation

- Start dates must be <= end dates
- Dates must be within reasonable ranges (e.g., 1900-2025)
- Future dates should be flagged for review

### Referential Integrity

- All `person_id` values must exist in PERSON table
- `visit_occurrence_id` should reference valid visits
- Concept IDs should exist in vocabulary tables

---

**For Questions:** Refer to [README.md](README.md) or [EXECUTION_GUIDE.md](EXECUTION_GUIDE.md)
