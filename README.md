# OMOP CDM Conversion Toolkit for Korean Traditional Medicine Data

[![OMOP CDM](https://img.shields.io/badge/OMOP%20CDM-v5.x-blue)](https://ohdsi.github.io/CommonDataModel/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-12%2B-blue)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-Apache%202.0-green)](LICENSE)

## 📋 Overview

This toolkit provides a modular, well-documented solution for converting Korean Traditional Medicine (한의학) healthcare data to the **OMOP Common Data Model (CDM) v5.x** format. The conversion process is split into 12 logical, reusable SQL scripts that can be executed sequentially or individually.

### Key Features

- ✅ **Modular Architecture**: 12 separate scripts for different OMOP CDM domains
- ✅ **Configurable**: Centralized configuration file for easy customization
- ✅ **Well-Documented**: Comprehensive inline comments and external documentation
- ✅ **Data Quality Focused**: Built-in validation and quality checks
- ✅ **Korean Traditional Medicine Support**: Custom vocabularies and concepts
- ✅ **Transaction Safe**: Proper error handling and rollback capabilities

## 🎯 Purpose

This toolkit is designed for researchers and data engineers who need to:
- Convert Korean healthcare data to OMOP CDM format
- Integrate Korean Traditional Medicine data with standard OMOP vocabularies
- Perform observational health research using standardized data
- Enable data sharing and collaboration across institutions

## 📁 Directory Structure

```
Achilles_code_insert_str/
├── README.md                          # This file
├── EXECUTION_GUIDE.md                 # Step-by-step execution instructions
├── DATA_MAPPING_REFERENCE.md          # Data mapping documentation
├── config.sql                         # Configuration file
├── LICENSE                            # License information
├── .gitignore                         # Git ignore file
├── make_cdm.sql                       # Original monolithic script (archived)
└── scripts/                           # Modular SQL scripts
    ├── 00_master_script.sql           # Master orchestration script
    ├── 01_setup_and_backup.sql        # Setup and backup procedures
    ├── 02_create_tables.sql           # OMOP CDM table definitions
    ├── 03_person_and_observation_period.sql
    ├── 04_visit_occurrence.sql
    ├── 05_condition_occurrence.sql
    ├── 06_drug_exposure.sql
    ├── 07_procedure_occurrence.sql
    ├── 08_measurement.sql
    ├── 09_observation.sql
    ├── 10_era_tables.sql
    ├── 11_vocabulary.sql
    └── 12_validation.sql
```

## 🚀 Quick Start

### Prerequisites

1. **PostgreSQL 12+** installed and running
2. **Source data tables** loaded into your database:
   - `data_patmst` (patient master)
   - `data_ipdacpt_pmy` (inpatient admissions)
   - `data_opdacpt_pmy` (outpatient visits)
   - `data_dxofpat_pmy` (diagnoses)
   - `data_orderinfos2020_pmy` (orders)
   - `data_resultofnum` (numeric lab results)
3. **Preprocessed tables** (created via R or other tools):
   - `add_condition_new`
   - `add_drug_Data`
   - `add_proc_Data`
   - `add_to_measurement`
4. **OMOP Vocabulary tables** in `voca_sample` schema
5. **Vocabulary mapping tables**:
   - `wk_voca` (working vocabulary)
   - `jo_mapping_table` (concept mapping)

### Basic Execution

#### Option 1: Run All Scripts at Once (Recommended for first-time users)

```bash
psql -h localhost -U your_username -d your_database -f scripts/00_master_script.sql
```

#### Option 2: Run Scripts Individually

```bash
# Step 1: Setup and backup
psql -h localhost -U your_username -d your_database -f scripts/01_setup_and_backup.sql

# Step 2: Create tables
psql -h localhost -U your_username -d your_database -f scripts/02_create_tables.sql

# ... continue with remaining scripts in order
```

### Configuration

Before running the scripts, review and customize `config.sql`:

```sql
-- Example: Change schema names
\set cdm_schema 'my_cdm_schema'
\set vocab_schema 'my_vocab_schema'

-- Example: Adjust concept IDs if needed
\set concept_race_asian 38003585
```

## 📊 What Gets Created

The conversion process creates the following OMOP CDM tables:

### Clinical Data Tables
- **PERSON**: Patient demographics (gender, birth year, race)
- **OBSERVATION_PERIOD**: Time periods of patient observation
- **VISIT_OCCURRENCE**: Inpatient and outpatient visits
- **CONDITION_OCCURRENCE**: Diagnoses and medical conditions
- **DRUG_EXPOSURE**: Medication prescriptions and administrations
- **PROCEDURE_OCCURRENCE**: Medical procedures
- **MEASUREMENT**: Laboratory tests and vital signs
- **OBSERVATION**: Clinical observations and facts

### Derived Tables
- **CONDITION_ERA**: Continuous periods of conditions
- **DRUG_ERA**: Continuous periods of drug exposure

### Supporting Tables
- **DEVICE_EXPOSURE**: Medical devices (placeholder)
- **NOTE**: Clinical notes (placeholder)
- **PROVIDER**: Healthcare providers (placeholder)
- **PAYER_PLAN_PERIOD**: Insurance information (placeholder)

## 🔍 Data Validation

After conversion, the validation script (`12_validation.sql`) provides:

1. **Record Count Summary**: Total records in each table
2. **Required Field Validation**: Checks for NULL values in mandatory fields
3. **Referential Integrity**: Validates foreign key relationships
4. **Data Quality Checks**: Identifies invalid dates, concepts, etc.
5. **Concept Mapping Statistics**: Shows mapping success rates
6. **Patient Coverage**: Unique patients per table
7. **Date Range Summary**: Temporal coverage of data

## 📖 Documentation

- **[EXECUTION_GUIDE.md](EXECUTION_GUIDE.md)**: Detailed step-by-step execution instructions
- **[DATA_MAPPING_REFERENCE.md](DATA_MAPPING_REFERENCE.md)**: Complete data mapping documentation

## ⚠️ Important Notes

### Data Requirements

- Source tables must use **numeric date format (YYYYMMDD)**
- Patient IDs must be consistent across all source tables
- Gender codes: `M` (Male), `F` (Female)
- Korean ID format: First 2 digits represent birth year offset from 1900

### Customization Required

You will need to adapt the following to your environment:

1. **Table Names**: Update source table names in each script
2. **Schema Names**: Modify schema references in `config.sql`
3. **Concept IDs**: Verify OMOP concept IDs match your vocabulary version
4. **Date Formats**: Adjust date transformation logic if needed

### Performance Considerations

- For large datasets (>10M records), consider running scripts individually
- Create indexes after data loading for better query performance
- Use `ANALYZE` and `VACUUM` after conversion
- Monitor disk space during conversion (estimate 2-3x source data size)

## 🔧 Troubleshooting

### Common Issues

**Issue**: "Table does not exist" error
- **Solution**: Verify source table names match your database schema

**Issue**: "Date format error"
- **Solution**: Check that source dates are in YYYYMMDD numeric format

**Issue**: "Concept mapping returns NULL"
- **Solution**: Ensure vocabulary tables are loaded and mapping tables exist

**Issue**: "Out of memory"
- **Solution**: Run scripts individually instead of using master script

## 📝 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes with clear comments
4. Test thoroughly with sample data
5. Submit a pull request with detailed description

## 📧 Support

For questions or issues:

1. Check the [EXECUTION_GUIDE.md](EXECUTION_GUIDE.md) for detailed instructions
2. Review the [DATA_MAPPING_REFERENCE.md](DATA_MAPPING_REFERENCE.md) for mapping details
3. Open an issue on the repository

## 🙏 Acknowledgments

- **OHDSI Community**: For developing and maintaining the OMOP CDM standard
- **Korean Traditional Medicine Researchers**: For domain expertise and vocabulary development

## 📚 Additional Resources

- [OMOP CDM Documentation](https://ohdsi.github.io/CommonDataModel/)
- [OHDSI Community](https://www.ohdsi.org/)
- [ATLAS Data Exploration Tool](https://github.com/OHDSI/Atlas)
- [ACHILLES Data Quality Tool](https://github.com/OHDSI/Achilles)

---

**Version**: 1.0.0  
**Last Updated**: 2025-11-27  
**OMOP CDM Version**: 5.x  
**Database**: PostgreSQL 12+
