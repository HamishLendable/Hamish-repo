# How to Run SQL Queries

## Running the First Query: Average Interest Rate Monitor

### Query Structure Explanation

The first query follows this pattern:

```sql
SELECT
    [Columns to display]
FROM
    [Table name]
WHERE
    [Filter conditions]
GROUP BY
    [Grouping columns]
ORDER BY
    [Sorting columns]
```

### Step-by-Step Breakdown:

1. **SELECT clause**: Defines what columns to return
   - `INTRODUCER_CATEGORY AS CHANNEL` - Renames the column for clarity
   - `ORIGINATION_SIMPLIFIED_RISK_GRADE AS RISK_GRADE` - Risk grade grouping
   - `ROUND(AVG(FINAL_INTEREST_RATE), 2)` - Calculates average interest rate, rounded to 2 decimals
   - `COUNT(*) AS TOTAL_LOANS` - Counts total loans in each group

2. **FROM clause**: Specifies the source table
   - `PROD.PRS_MOTOR.PRS__APPLICATION__MOTOR` - Full table path (Database.Schema.Table)

3. **WHERE clause**: Filters the data
   - `FLAG_ORIGINATED = 1` - Only include loans that were actually funded
   - `ORIGINATION_DATETIME >= '2024-01-01'` - Only loans from 2024 onwards

4. **GROUP BY**: Groups results by Channel and Risk Grade
   - `1, 2` refers to the 1st and 2nd columns in SELECT (CHANNEL and RISK_GRADE)

5. **ORDER BY**: Sorts results by Channel, then Risk Grade

### How to Run This Query:

#### Option 1: Snowflake Web UI
1. Log into your Snowflake account
2. Navigate to Worksheets
3. Create a new worksheet
4. Copy and paste the query from `query_1_avg_interest_rate.sql`
5. Click "Run" (or press Ctrl+Enter)

#### Option 2: Using SnowSQL CLI
```bash
snowsql -c your_connection_name -f query_1_avg_interest_rate.sql
```

#### Option 3: Using Python with snowflake-connector-python
```python
import snowflake.connector

conn = snowflake.connector.connect(
    user='your_username',
    password='your_password',
    account='your_account',
    warehouse='your_warehouse',
    database='PROD',
    schema='PRS_MOTOR'
)

cursor = conn.cursor()
with open('query_1_avg_interest_rate.sql', 'r') as f:
    cursor.execute(f.read())
    
results = cursor.fetchall()
for row in results:
    print(row)
```

### Running the Other Queries:

All other queries in `starter_analysis` follow the same pattern:

1. **Extract the query**: Each query is between `/* */` comment blocks
2. **Copy the SQL**: Get everything from the `SELECT` to the final `;`
3. **Run in your SQL client**: Use the same method as above

### Query Categories in starter_analysis:

1. **PRICING DATA** (Lines 4-295)
   - Average Interest Rate Monitor
   - Interest Rate Spread
   - Average Loan Amount & Volume Share
   - Price Elasticity queries

2. **CREDIT STRATEGY DATA** (Lines 304-475)
   - Approval Rate queries
   - Average Credit Score
   - Default Rate by Grade

3. **ORIGINATION FUNNEL METRIC** (Lines 484-708)
   - Application Volume
   - Conversion Rates
   - Time to Process
   - Asset Profile
   - Funnel Drop-off Analysis

4. **CREDIT PERFORMANCE DATA** (Lines 713-834)
   - Delinquency by Vintage & Seasoning
   - Multi-dimensional Risk Analysis

### Tips for Running Queries:

- **Date filters**: Most queries use `>= '2024-01-01'` - adjust if needed
- **CTEs (WITH clauses)**: Some queries use Common Table Expressions - these must be run as complete blocks
- **Multiple queries**: If a query has multiple SELECT statements, run them separately
- **Results**: Export results to CSV if needed for further analysis

