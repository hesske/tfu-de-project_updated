# Data Warehouse with Occupation Data Project

A data warehouse implementation using SQLite with a Python-based ETL pipeline for job skill analysis using O*NET occupational data.

## Overview

This project builds a comprehensive data warehouse from the [O*NET Database](https://www.onetcenter.org/database.html) specifically designed for analyzing job skills and their relationships to occupations. The pipeline extracts, transforms, and loads detailed skill data for over 900 occupations in the U.S. economy, enabling in-depth analysis of skill requirements, skill gaps, and workforce trends.

## Features

- **Automated ETL Pipeline**: Python scripts to download, process, and load O*NET skill data
- **SQLite Data Warehouse**: Structured database optimized for skill analysis and querying
- **Comprehensive Skill Coverage**: 
  - **35 Core Skills** across basic and cross-functional categories
  - **33 Knowledge Areas** representing different domains of expertise
  - **52 Abilities** including cognitive, physical, and sensory capabilities
  - **Technology Skills** with "Hot" and "In Demand" designations
  - Skill importance and level ratings for each occupation
- **Skill Relationship Analysis**: Links between skills, work activities, and work context
- **Job Zone Integration**: Occupations grouped by required experience and education levels

## Technology Stack

- **Python** (82%): Core ETL logic and data processing
- **Jupyter Notebook** (18%): Data exploration and analysis
- **SQLite**: Lightweight, file-based data warehouse
- **SQL**: Data modeling and query optimization

## Project Structure

```
tfu-de-project_updated/
├── .vscode/              # VSCode configuration
├── SQL/                  # SQL scripts for database schema and queries
├── data/                 # Raw and processed data files
├── python/               # Python ETL scripts
├── .gitignore           # Git ignore rules
├── README.md            # This file
├── git-filter-repo      # Git repository filtering tool
└── sqlite3.def          # SQLite definition file
```

## Data Source

This project uses data from the **O*NET 29.3 Database**, which is maintained by the U.S. Department of Labor, Employment and Training Administration (USDOL/ETA). The database is available under a [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/).

**Key O*NET Data Files Processed:**
- Occupation Data and Classifications
- Knowledge, Skills, and Abilities
- Work Activities (Generalized, Intermediate, and Detailed)
- Task Statements and Ratings
- Technology Skills and Tools Used
- Education, Training, and Experience Requirements
- Work Context and Work Styles
- Job Zones and Related Occupations

## Getting Started

### Prerequisites

- Python 3.x
- SQLite3
- Required Python packages (see `requirements.txt` if available)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/hesske/tfu-de-project_updated.git
cd tfu-de-project_updated
```

2. Install dependencies:
```bash
pip install -r requirements.txt
```

3. Run the ETL pipeline:
```bash
python python/main_pipeline.py
```

## Usage

### Running the ETL Pipeline

The pipeline downloads the latest O*NET data files, transforms them into a structured format, and loads them into the SQLite data warehouse.

### Querying the Database

Use SQL queries to analyze occupational data:
```sql
-- Example: Find occupations requiring high levels of Python programming
SELECT js.Job_Title, ts.Commodity_Title, ts.Example
FROM factJobSkills js
JOIN dimTechSkills ts ON js.ONET_SOC_Code = ts.ONET_SOC_Code
WHERE ts.Example LIKE '%Python%'
ORDER BY ts.Commodity_Code DESC;
```

### Data Analysis

Jupyter notebooks in the project can be used for exploratory data analysis and visualization of occupational trends.

## Database Schema

The SQLite data warehouse follows a star/snowflake schema optimized for analytical queries:

- **Fact Tables**: Occupation-level skills
- **Dimension Tables**: Skills, Job Info


## Use Cases

- **Career Planning**: Identify skills and knowledge required for different occupations
- **Workforce Development**: Analyze training needs and skill gaps
- **Labor Market Analysis**: Study occupational trends and requirements
- **Education Planning**: Align curricula with industry skill requirements
- **Job Matching**: Match candidates to occupations based on skills and interests

## Data Attribution

This project includes information from the [O*NET 29.3 Database](https://www.onetcenter.org/database.html) by the U.S. Department of Labor, Employment and Training Administration (USDOL/ETA). Used under the [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) license. O*NET® is a trademark of USDOL/ETA.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or open issues for bugs and feature requests.

## License

This project is available for use under appropriate licensing. The O*NET data is licensed under CC BY 4.0 as noted above.

## Acknowledgments

- O*NET Resource Center for providing comprehensive occupational data
- U.S. Department of Labor, Employment and Training Administration

## Contact

For questions or feedback, please open an issue in the GitHub repository.

---

**Last Updated**: October 2025  
**O*NET Database Version**: 29.3
