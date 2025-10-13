# Data Warehouse Design & Process Documentation

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture Design](#architecture-design)
3. [Data Pipeline Process](#data-pipeline-process)
4. [Database Design](#database-design)
5. [Installation & Setup](#installation--setup)
6. [Running the Pipeline](#running-the-pipeline)
7. [Maintenance & Troubleshooting](#maintenance--troubleshooting)

---

## System Overview

### Project Purpose

This data warehouse aggregates occupational data from the O*NET 29.3 database to enable comprehensive analysis of job skills, technical competencies, and labor market trends. The system extracts data from O*NET's public APIs, transforms it into a structured analytical schema, and loads it into a SQLite data warehouse optimized for skill-based career analysis.

### Key Objectives

- Centralize occupational data from authoritative O*NET sources
- Enable skill analysis across 900+ job classifications
- Support workforce development and career planning initiatives
- Provide queryable access to job requirements and skill assessments
- Track data lineage and maintain data quality standards

### Data Scope

- **Occupations Covered:** 1,016 unique job classifications (O*NET SOC codes)
- **Core Skills:** 35 general skills across foundational and cross-functional categories
- **Technical Skills:** 32,681 technology-specific skill records
- **Skill Ratings:** 62,580+ skill importance and proficiency assessments
- **Update Frequency:** O*NET 29.3 (quarterly updates available from source)

---

## Architecture Design

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Data Sources                             │
│              (O*NET Public Database v29.3)                   │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│           Extract Phase (get_files.ipynb)                    │
│  • Downloads raw O*NET text files from public endpoints     │
│  • Stores data in CSV format for processing                 │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│         Transform Phase (transform_data.ipynb)               │
│  • Validates data against schema                            │
│  • Removes nulls, duplicates, and irrelevant records       │
│  • Renames columns to match warehouse schema               │
│  • Outputs cleaned data for loading                        │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│          Load Phase (insert_data.ipynb)                      │
│  • Connects to SQLite database                              │
│  • Inserts dimension table data                             │
│  • Populates fact table with UNION queries                 │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────────────┐
│          SQLite Data Warehouse                               │
│    (occupationData.db)                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ factJobSkills│──│ dimJobInfo   │  │ dimTechSkills│     │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                                    │               │
│         └────────────┬─────────────────────┘                │
│                      ▼                                       │
│          ┌──────────────────────┐                           │
│          │   dimSkills          │                           │
│          └──────────────────────┘                           │
└─────────────────────────────────────────────────────────────┘
```

### Technology Stack

| Component | Technology | Version | Purpose |
|---|---|---|---|
| ETL Orchestration | Python | 3.x | Primary automation language |
| Data Processing | Pandas | 2.3.3 | Dataframe manipulation and transformation |
| Data Validation | Pandera | 0.26.1 | Schema validation and quality checks |
| Notebooks | Jupyter/IPython | Latest | Interactive data processing workflows |
| Database | SQLite | 3 | Lightweight, file-based data warehouse |
| Query Language | SQL | Standard | Database queries and analytics |

### Architecture Principles

**Separation of Concerns:** Each pipeline stage (extract, transform, load) is isolated in separate notebooks, enabling independent testing and modification.

**Schema Validation:** Pandera schemas enforce data quality and consistency before loading into the warehouse, preventing invalid data from corrupting the analytical environment.

**Dimension Tables:** Multiple dimension tables (Job Info, Skills, Tech Skills) provide flexible joining and filtering for various analytical queries.

**Fact Table Consolidation:** The central fact table combines skill and technical skill relationships through a UNION operation, enabling unified querying across both skill types.

---

## Data Pipeline Process

### Phase 1: Extract (get_files.ipynb)

**Purpose:** Download raw data from O*NET public sources and stage it for processing.

**Inputs:**
- O*NET Database v29.3 public endpoints
- Domain: `https://www.onetcenter.org/dl_files/database/db_30_0_text/`

**Process:**

The extraction phase retrieves four primary O*NET data files:

1. **Occupation Data** (`jobTitleInfo.csv`)
   - Contains job titles and descriptions
   - One record per O*NET SOC code
   - Provides the reference frame for all other data

2. **Technology Skills** (`jobTechSkills.csv`)
   - Lists technology tools and software used in occupations
   - Includes demand indicators (Hot Technology, In Demand flags)
   - 32,681+ total records

3. **Skills** (`jobSkills.csv`)
   - Core competencies and abilities required for jobs
   - Includes proficiency and importance ratings
   - 62,580+ records with assessment scales

4. **Alternate Titles** (`jobAltTitles.csv`)
   - Currently commented out (available for future implementation)
   - Would provide synonym job titles for fuzzy matching

**Key Operations:**

```python
# Retrieve file from O*NET and save as CSV
url = f'{url_domain}{file_name}'
df = pd.read_table(url, sep='\t', dtype=str)
df.to_csv(f'../data/data_source_files/{save_as}', 
          index=False, header=True, na_rep='missing')
```

**Outputs:**
- Raw CSV files in `/data/data_source_files/` directory
- Data retained as strings for validation in next phase

---

### Phase 2: Transform (transform_data.ipynb)

**Purpose:** Validate, clean, and normalize data according to warehouse schema requirements.

**Key Validation Rules:**

Each dataset undergoes schema validation using Pandera to enforce:

- No 'missing' placeholder values in critical fields
- All required columns present and properly typed
- Data types match expected formats

**Dataset-Specific Transformations:**

**Skills Data Validation:**
- Filters out records with 'Not Relevant' field containing 'Y' or 'missing'
- Removes duplicate records
- Validates 5 core columns: O*NET-SOC Code, Element ID, Element Name, Scale ID, Data Value
- Output: 34,673 validated skill records

**Job Title Data Validation:**
- Simple validation of 3 required fields (Code, Title, Description)
- Drops null values and duplicates
- Output: 1,016 unique job classifications

**Tech Skills Data Validation:**
- Validates 6 columns including demand indicators
- Enforces integer type for Commodity Code
- Output: 32,681 validated technology records

**Transformation Operations:**
- Remove null values and duplicates
- Strip whitespace from column names
- Validate data types and value ranges
- Output cleaned data to `/data/validated_files/` directory

**Data Quality Metrics (Post-Transform):**
- Skills records: 62,579 → 34,673 (after filtering not-relevant)
- Job titles: 1,016 → 1,016 (no changes)
- Tech skills: 32,681 → 32,681 (no changes)
- All records pass schema validation

---

### Phase 3: Load (insert_data.ipynb)

**Purpose:** Insert validated data into SQLite dimension and fact tables.

**Process:**

**Dimension Table Loading:**

Three dimension tables are populated sequentially from validated CSV files:

1. **dimTechSkills** (32,681 records)
   ```
   Maps: O*NET-SOC Code → Technology Commodity
   Columns: ONET_SOC_Code, Example, Commodity_Code, 
            Commodity_Title, Hot_Tech, In_Demand, created_at
   ```

2. **dimJobInfo** (1,016 records)
   ```
   Maps: O*NET-SOC Code → Job Title + Description
   Columns: ONET_SOC_Code, Title, Description, created_at
   ```

3. **dimSkills** (34,673 records)
   ```
   Maps: O*NET-SOC Code + Skill → Proficiency Rating
   Columns: ONET_SOC_Code, Element_ID, Skill, Scale_ID, 
            Data_Value, created_at
   ```

**Fact Table Population:**

The central fact table (`factJobSkills`) is populated using a UNION of two SELECT queries:

```sql
-- Query 1: General Skills
SELECT
    s.ONET_SOC_Code,
    s.Element_ID as Skill_Element,
    s.Skill as Skill_Name,
    111111 as Tech_Skill_Key,           -- Placeholder for type distinction
    "NA" as Tech_Skill_Name,
    j.Title as Job_Title,
    CURRENT_TIMESTAMP as created_at
FROM dimSkills s
LEFT JOIN dimJobInfo j ON s.ONET_SOC_Code = j.ONET_SOC_Code

UNION

-- Query 2: Technical Skills
SELECT
    t.ONET_SOC_Code,
    222222 as Skill_Element,            -- Placeholder for type distinction
    "NA" as Skill_Name,
    t.Commodity_Code as Tech_Skill_Key,
    t.Commodity_Title as Tech_Skill_Name,
    j.Title as Job_Title,
    CURRENT_TIMESTAMP as created_at
FROM dimTechSkills t
LEFT JOIN dimJobInfo j ON t.ONET_SOC_Code = j.ONET_SOC_Code
```

**Key Design Decisions:**

- **Type Indicator Fields:** Placeholder IDs (111111 for skills, 222222 for tech skills) allow downstream queries to distinguish between skill types.
- **Left Joins:** Preserves all skill records even if job info is missing.
- **Timestamp Capture:** created_at field records load time for auditing and lineage.

**Load Execution:**

```python
# Pandas to_sql handles table creation and type mapping
df.to_sql(table_name, conn, if_exists='replace', index=False)

# SQL script execution for fact table
cursor.executescript(open('../SQL/factTable_populate.sql').read())
conn.commit()
```

**Error Handling:**

- Try-except blocks capture file not found errors
- Schema validation errors surface during transform phase
- Connection errors are logged with context

---

## Database Design

### Schema Architecture

The warehouse implements a **Dimensional Star Schema** with a central fact table surrounded by specialized dimension tables:

```
                dimJobInfo
                    ▲
                    │
                    │
    dimSkills ◄─────┼─────► dimTechSkills
        ▲           │           ▲
        │           │           │
        └───────────┴───────────┘
                    │
                    │
              factJobSkills
         (Central Fact Table)
```

### Table Specifications

**factJobSkills** (Central Fact Table)

Contains consolidated skill-to-job relationships, combining both general and technical skills.

| Column | Type | Constraints | Purpose |
|---|---|---|---|
| ID | INTEGER | PRIMARY KEY | Unique record identifier |
| ONET_SOC_CODE | TEXT | NOT NULL | Join key to dimension tables |
| Skill_Element | INTEGER | Nullable | For general skills: Element ID; for tech skills: placeholder (222222) |
| Skill_Name | TEXT | Nullable | For general skills: skill name; for tech skills: "NA" |
| Tech_Skill_Key | INTEGER | Nullable | For tech skills: Commodity Code; for general skills: placeholder (111111) |
| Tech_Skill_Name | TEXT | Nullable | For tech skills: Commodity Title; for general skills: "NA" |
| Job_Title | INTEGER | Nullable | Job title from joined dimJobInfo |
| created_at | TIMESTAMP | DEFAULT CURRENT_TIMESTAMP | Audit timestamp |

**Cardinality:** Many-to-many (1 job → many skills, 1 skill → many jobs)

---

**dimJobInfo** (Job Information Dimension)

Reference table for job classifications and descriptions.

| Column | Type | Constraints | Purpose |
|---|---|---|---|
| ONET_SOC_Code | TEXT | Unique | O*NET Standard Occupational Classification code |
| Title | TEXT | Nullable | Job title (e.g., "Software Developer") |
| Description | TEXT | Nullable | Detailed job description |
| created_at | TIMESTAMP | Nullable | Load timestamp |

**Cardinality:** 1 job code = 1 row (1,016 total)

---

**dimSkills** (General Skills Dimension)

Core competencies and abilities required across occupations.

| Column | Type | Constraints | Purpose |
|---|---|---|---|
| ONET_SOC_Code | TEXT | Nullable | Links to job classification |
| Element_ID | TEXT | Nullable | Unique skill element identifier |
| Skill | TEXT | Nullable | Skill name (e.g., "Problem Solving", "Communication") |
| Scale_ID | TEXT | Nullable | Rating scale identifier (1-7, low-to-high, etc.) |
| Data_Value | REAL | Nullable | Numerical rating on specified scale |
| created_at | TIMESTAMP | Nullable | Load timestamp |

**Cardinality:** Many-to-many (1 job → multiple skills, ratings vary by scale)

**Aggregates:** 34,673 total records; ~34 unique skills × 1,016 jobs

---

**dimTechSkills** (Technical Skills Dimension)

Technology tools, programming languages, and software used in occupations.

| Column | Type | Constraints | Purpose |
|---|---|---|---|
| ONET_SOC_Code | TEXT | Nullable | Links to job classification |
| Example | TEXT | Nullable | Example tool or software (e.g., "Python", "Tableau") |
| Commodity_Code | INTEGER | Nullable | Industry classification code |
| Commodity_Title | TEXT | Nullable | Commodity category name |
| Hot_Tech | TEXT | Nullable | Emerging technology indicator ("yes"/"no") |
| In_Demand | TEXT | Nullable | Current market demand indicator ("yes"/"no") |
| created_at | TIMESTAMP | Nullable | Load timestamp |

**Cardinality:** Many-to-many (1 job → multiple technologies)

**Aggregates:** 32,681 total records; ~32 unique tech skills × 1,016 jobs

---

### Indexing Strategy

**Current State:** No explicit indexes defined in schema (SQLite default behavior).

**Recommended Indexes for Performance:**

```sql
-- Primary access path: Find skills for a job
CREATE INDEX idx_skills_onet ON dimSkills(ONET_SOC_Code);
CREATE INDEX idx_tech_skills_onet ON dimTechSkills(ONET_SOC_Code);

-- Query consolidation: Filter by demand indicators
CREATE INDEX idx_tech_in_demand ON dimTechSkills(In_Demand);
CREATE INDEX idx_tech_hot ON dimTechSkills(Hot_Tech);

-- Fact table performance: ONET code lookups
CREATE INDEX idx_fact_onet ON factJobSkills(ONET_SOC_CODE);

-- Reverse lookups: Find jobs by skill
CREATE INDEX idx_skills_element ON dimSkills(Element_ID);
CREATE INDEX idx_tech_commodity ON dimTechSkills(Commodity_Code);
```

---

### Referential Integrity

**Current Implementation:** No explicit foreign keys defined in schema.

**Recommended Constraints (for future implementation):**

```sql
-- Enforce referential integrity
ALTER TABLE dimSkills 
ADD FOREIGN KEY (ONET_SOC_Code) REFERENCES dimJobInfo(ONET_SOC_Code);

ALTER TABLE dimTechSkills 
ADD FOREIGN KEY (ONET_SOC_Code) REFERENCES dimJobInfo(ONET_SOC_Code);

ALTER TABLE factJobSkills 
ADD FOREIGN KEY (ONET_SOC_CODE) REFERENCES dimJobInfo(ONET_SOC_Code);
```

**Note:** Currently enforced at application layer in Python scripts.

---

## Installation & Setup

### System Requirements

- **Python:** 3.8 or higher
- **SQLite:** 3.x (typically pre-installed on Linux/macOS; download for Windows)
- **Disk Space:** ~200MB (raw data + processed warehouse)
- **Memory:** 4GB minimum (for Pandas operations)
- **Network:** Internet access to download O*NET data

### Step 1: Clone Repository

```bash
git clone https://github.com/hesske/tfu-de-project_updated.git
cd tfu-de-project_updated
```

### Step 2: Create Virtual Environment

```bash
# Create Python virtual environment
python3 -m venv venv

# Activate environment
# On Linux/macOS:
source venv/bin/activate

# On Windows:
venv\Scripts\activate
```

### Step 3: Install Dependencies

```bash
# Install required Python packages
pip install -r requirements.txt
```

**Package Breakdown:**

| Package | Version | Purpose |
|---|---|---|
| pandas | 2.3.3 | Dataframe operations and data transformation |
| pandera | 0.26.1 | Data validation and schema checking |
| nbformat | 5.10.4 | Jupyter notebook format support |
| nbconvert | 7.16.6 | Notebook execution and conversion |
| ipykernel | 7.0.0 | IPython kernel for Jupyter |
| pipdeptree | 2.29.0 | Dependency visualization (optional) |
| tinycss2 | 1.4.0 | CSS parsing for nbconvert |

### Step 4: Verify Installation

```bash
# Check Python version
python --version

# Verify packages installed
pip list | grep -E "pandas|pandera|nbconvert"

# Test SQLite availability
python -c "import sqlite3; print(sqlite3.sqlite_version)"
```

### Step 5: Create Project Directories

```bash
# Ensure data directories exist
mkdir -p data/data_source_files
mkdir -p data/validated_files
mkdir -p SQL
mkdir -p python
```

### Step 6: Database Initialization

The database is created automatically during the load phase. Optionally pre-create with schema:

```bash
# Optional: Pre-create database with schema
sqlite3 data/occupationData.db < SQL/dw_schema.sql
```

---

## Running the Pipeline

### Full Automated Pipeline

Execute the complete ETL process in one command:

```bash
python python/main_pipeline.py
```

**Execution Flow:**

1. **get_files.ipynb** (2-5 minutes)
   - Downloads O*NET files from public endpoints
   - Saves raw data to `data/data_source_files/`
   - Output: 4 CSV files (~50MB combined)

2. **transform_data.ipynb** (1-2 minutes)
   - Validates data against Pandera schemas
   - Removes nulls and duplicates
   - Saves cleaned data to `data/validated_files/`
   - Output: 3 validated CSV files

3. **insert_data.ipynb** (2-3 minutes)
   - Connects to SQLite database
   - Inserts dimension table data
   - Populates fact table via SQL UNION
   - Output: occupationData.db with 4 tables, ~130K total records

**Total Estimated Runtime:** 5-10 minutes

---

### Individual Phase Execution

Run specific pipeline phases independently:

**Extract Phase Only:**

```python
from nbconvert.preprocessors import ExecutePreprocessor
import nbformat

notebook_path = "./python/get_files.ipynb"
with open(notebook_path, 'r') as f:
    notebook = nbformat.read(f, as_version=4)

ep = ExecutePreprocessor(timeout=600, kernel_name='python3')
ep.preprocess(notebook, {'metadata': {'path': './python/'}})
print("Data extracted successfully")
```

**Transform Phase Only:**

```bash
# Assumes raw data already exists in data/data_source_files/
jupyter nbconvert --to notebook --execute python/transform_data.ipynb
```

**Load Phase Only:**

```bash
# Assumes validated data exists in data/validated_files/
jupyter nbconvert --to notebook --execute python/insert_data.ipynb
```

---

### Monitoring Execution

The pipeline provides console output indicating progress:

```
Executing notebook: ./python/get_files.ipynb...
Notebook execution complete.
Executed notebook saved to: ./get_files_output.ipynb

Inserted 32681 records into dimTechSkills
Inserted 1016 records into dimJobInfo
Inserted 34673 records into dimSkills
Fact table populated successfully.
```

### Verifying Data Load

Query the database to confirm successful load:

```bash
sqlite3 data/occupationData.db

# View table row counts
SELECT 'dimJobInfo' as table_name, COUNT(*) as row_count FROM dimJobInfo
UNION ALL
SELECT 'dimSkills', COUNT(*) FROM dimSkills
UNION ALL
SELECT 'dimTechSkills', COUNT(*) FROM dimTechSkills
UNION ALL
SELECT 'factJobSkills', COUNT(*) FROM factJobSkills;

# Sample fact table data
SELECT ONET_SOC_CODE, Skill_Name, Tech_Skill_Name, Job_Title 
FROM factJobSkills 
LIMIT 5;
```

---

## Maintenance & Troubleshooting

### Common Issues & Solutions

**Issue 1: Download Timeout (get_files.ipynb)**

**Symptom:** Pipeline fails during O*NET file download; connection timeout error.

**Cause:** Network latency or O*NET endpoint temporary unavailability.

**Solution:**

```python
# Modify get_file function with retry logic
import time

def get_file_with_retry(file_name, save_as, max_retries=3):
    for attempt in range(max_retries):
        try:
            url = f'{url_domain}{file_name}'
            df = pd.read_table(url, sep='\t', dtype=str, timeout=30)
            df.to_csv(f'../data/data_source_files/{save_as}', 
                     index=False, header=True, na_rep='missing')
            return True
        except Exception as e:
            if attempt < max_retries - 1:
                time.sleep(5)  # Wait 5 seconds before retry
                continue
            else:
                print(f"Failed to download {file_name}: {e}")
                return False
```

---

**Issue 2: Schema Validation Failures (transform_data.ipynb)**

**Symptom:** Pandera validation error; "Check failed: column X contains invalid values"

**Cause:** O*NET source data format changed or includes unexpected values.

**Solution:**

```python
# Inspect failing records
failed_records = skills[~scheme.validate(skills)]
print(failed_records[['O*NET-SOC Code', 'Element ID']].head(10))

# Update schema to be more permissive or investigate root cause
# Option 1: Allow more null values
# Option 2: Add custom validation checks
```

---

**Issue 3: Database Locking (insert_data.ipynb)**

**Symptom:** SQLite "database is locked" error during insert.

**Cause:** Another process holding database connection; or SQLite journal files corrupted.

**Solution:**

```python
# Increase SQLite timeout
conn = sqlite3.connect('../data/occupationData.db', timeout=30.0)

# Or: Remove lock files if present
import os
if os.path.exists('../data/occupationData.db-shm'):
    os.remove('../data/occupationData.db-shm')
if os.path.exists('../data/occupationData.db-wal'):
    os.remove('../data/occupationData.db-wal')
```

---

**Issue 4: Memory Error (Large Dataframe Operations)**

**Symptom:** MemoryError when reading large CSV files in transform phase.

**Cause:** Insufficient RAM for full dataframe load; typical with 4GB systems.

**Solution:**

```python
# Process data in chunks instead of loading entire file
chunk_size = 5000
chunks = []

for chunk in pd.read_csv(file_path, chunksize=chunk_size):
    # Apply validation to chunk
    validated_chunk = scheme.validate(chunk)
    chunks.append(validated_chunk)

# Concatenate processed chunks
validated_data = pd.concat(chunks, ignore_index=True)
```

---

### Data Refresh Procedures

**Quarterly Update (When O*NET releases new version):**

```bash
# Step 1: Backup current database
cp data/occupationData.db data/occupationData.db.backup

# Step 2: Clear existing data (optional; pipeline can overwrite)
sqlite3 data/occupationData.db < SQL/delete\ from\ factJobSkills.sql

# Step 3: Re-run pipeline with updated URLs
# Update url_domain in get_files.ipynb to new O*NET version
# E.g., 'https://www.onetcenter.org/dl_files/database/db_31_0_text/'

python python/main_pipeline.py
```

---

### Performance Optimization

**For Faster Queries, add these indexes:**

```sql
-- Execute after initial load
CREATE INDEX idx_skills_onet ON dimSkills(ONET_SOC_Code);
CREATE INDEX idx_tech_onet ON dimTechSkills(ONET_SOC_Code);
CREATE INDEX idx_fact_onet ON factJobSkills(ONET_SOC_CODE);
CREATE INDEX idx_tech_demand ON dimTechSkills(In_Demand);
```

**For Reduced Load Time, use batched inserts:**

```python
# Instead of to_sql (which uses individual INSERTs), use executemany
chunk_size = 1000
for i in range(0, len(df), chunk_size):
    chunk = df.iloc[i:i+chunk_size]
    chunk.to_sql(table_name, conn, if_exists='append', index=False)
```

---

### Data Quality Monitoring

**Monthly Validation Queries:**

```sql
-- Check for missing job information
SELECT COUNT(*) as jobs_missing_description
FROM dimJobInfo
WHERE Description IS NULL OR Description = '';

-- Verify fact table integrity
SELECT COUNT(*) as orphaned_skills
FROM factJobSkills f
WHERE NOT EXISTS (
    SELECT 1 FROM dimJobInfo j 
    WHERE j.ONET_SOC_Code = f.ONET_SOC_CODE
);

-- Monitor in-demand vs hot tech balance
SELECT 
    In_Demand, Hot_Tech, COUNT(*) as count
FROM dimTechSkills
GROUP BY In_Demand, Hot_Tech;
```

---

### Backup & Recovery

**Automated Backup Script:**

```bash
#!/bin/bash
# backup_dw.sh - Daily database backup

BACKUP_DIR="./backups"
DB_PATH="./data/occupationData.db"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

mkdir -p $BACKUP_DIR
cp $DB_PATH $BACKUP_DIR/occupationData_$TIMESTAMP.db

# Keep only last 30 days of backups
find $BACKUP_DIR -name "*.db" -mtime +30 -delete

echo "Backup completed: $BACKUP_DIR/occupationData_$TIMESTAMP.db"
```

---

### Support & Contact

For issues or questions:

1. Check logs in output notebooks (get_files_output.ipynb, etc.)
2. Verify O*NET database availability: https://www.onetcenter.org/database.html
3. Review data quality reports from transform phase
4. Open GitHub issue: https://github.com/hesske/tfu-de-project_updated/issues

---

## Appendix: Key Formulas & Queries

### Common Analytics Queries

**Find In-Demand Tech Skills by Job Category:**

```sql
SELECT DISTINCT 
    j.Title as JobTitle,
    t.Commodity_Title as TechSkill,
    t.Example as ToolExample,
    CASE WHEN t.Hot_Tech = 'yes' THEN 'Emerging' 
         WHEN t.In_Demand = 'yes' THEN 'High Demand'
         ELSE 'Standard' END as SkillStatus
FROM factJobSkills f
JOIN dimJobInfo j ON f.ONET_SOC_CODE = j.ONET_SOC_Code
JOIN dimTechSkills t ON f.ONET_SOC_CODE = t.ONET_SOC_Code
WHERE t.In_Demand = 'yes'
ORDER BY j.Title, t.Commodity_Title;
```

**Skill Gap Analysis:**

```sql
SELECT 
    j.Title as JobTitle,
    s.Skill,
    AVG(CAST(s.Data_Value AS FLOAT)) as AvgImportance,
    COUNT(*) as FrequencyAcrossOccupations
FROM dimSkills s
JOIN dimJobInfo j ON s.ONET_SOC_Code = j.ONET_SOC_Code
WHERE s.Scale_ID = 'IM'  -- Importance scale
GROUP BY j.Title, s.Skill
HAVING AVG(CAST(s.Data_Value AS FLOAT)) > 3.5
ORDER BY AvgImportance DESC;
```

---

**Last Updated:** October 2025  
**Database Version:** O*NET 29.3  
**Document Version:** 1.0