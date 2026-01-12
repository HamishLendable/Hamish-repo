#!/usr/bin/env python3
"""
Script to run the Average Interest Rate Monitor query.

Usage:
    python run_query_1.py

Requirements:
    pip install snowflake-connector-python

Environment Variables (or modify the connection parameters below):
    SNOWFLAKE_USER
    SNOWFLAKE_PASSWORD
    SNOWFLAKE_ACCOUNT
    SNOWFLAKE_WAREHOUSE
    SNOWFLAKE_DATABASE
    SNOWFLAKE_SCHEMA
"""

import os
import sys

try:
    import snowflake.connector
except ImportError:
    print("Error: snowflake-connector-python not installed.")
    print("Install it with: pip install snowflake-connector-python")
    sys.exit(1)

# Connection parameters - modify these or use environment variables
conn_params = {
    'user': os.getenv('SNOWFLAKE_USER', 'your_username'),
    'password': os.getenv('SNOWFLAKE_PASSWORD', 'your_password'),
    'account': os.getenv('SNOWFLAKE_ACCOUNT', 'your_account'),
    'warehouse': os.getenv('SNOWFLAKE_WAREHOUSE', 'your_warehouse'),
    'database': os.getenv('SNOWFLAKE_DATABASE', 'PROD'),
    'schema': os.getenv('SNOWFLAKE_SCHEMA', 'PRS_MOTOR')
}

# The query
query = """
SELECT
    INTRODUCER_CATEGORY AS CHANNEL,
    ORIGINATION_SIMPLIFIED_RISK_GRADE AS RISK_GRADE,
    
    ROUND(AVG(FINAL_INTEREST_RATE), 2) AS AVG_INTEREST_RATE,
    COUNT(*) AS TOTAL_LOANS

FROM
    PROD.PRS_MOTOR.PRS__APPLICATION__MOTOR
WHERE
    FLAG_ORIGINATED = 1
    AND ORIGINATION_DATETIME >= '2024-01-01'
GROUP BY
    1, 2
ORDER BY
    1, 2;
"""

def main():
    print("=" * 80)
    print("AVERAGE INTEREST RATE MONITOR")
    print("=" * 80)
    print("\nQuery:")
    print(query)
    print("\n" + "=" * 80)
    
    try:
        # Connect to Snowflake
        print("\nConnecting to Snowflake...")
        conn = snowflake.connector.connect(**conn_params)
        cursor = conn.cursor()
        
        # Execute query
        print("Executing query...")
        cursor.execute(query)
        
        # Fetch results
        results = cursor.fetchall()
        columns = [desc[0] for desc in cursor.description]
        
        # Display results
        print(f"\nResults ({len(results)} rows):\n")
        
        # Print header
        header = " | ".join(f"{col:20}" for col in columns)
        print(header)
        print("-" * len(header))
        
        # Print rows
        for row in results:
            row_str = " | ".join(f"{str(val):20}" for val in row)
            print(row_str)
        
        # Close connection
        cursor.close()
        conn.close()
        
        print(f"\n\nQuery completed successfully. Returned {len(results)} rows.")
        
    except snowflake.connector.errors.ProgrammingError as e:
        print(f"\nError executing query: {e}")
        sys.exit(1)
    except snowflake.connector.errors.DatabaseError as e:
        print(f"\nDatabase error: {e}")
        print("\nPlease check your connection parameters.")
        sys.exit(1)
    except Exception as e:
        print(f"\nUnexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()

