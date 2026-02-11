WITH
-- 1. The Name List
spreadsheet_names (first_name, last_name) AS (
    SELECT * FROM VALUES
        ('melissa', 'hill'),
        ('zara', 'rossi'),
        ('james', 'thirlway'),
        ('ella-jean', 'mcdonald'),
        ('rebecca', 'yates'),
        ('anna', 'lee'),
        ('kuberan', 'jeevakumar'),
        ('david', 'scanlon'),
        ('kyle', 'slattery'),
        ('aaron', 'mcclimonds'),
        ('natalija', 'langton'),
        ('francessca', 'kaminski'),
        ('lauren', 'mcmullan'),
        ('shannon', 'falloon'),
        ('callum', 'tomlinson'),
        ('richenda', 'proctor'),
        ('scott', 'dunseith'),
        ('kevin', 'o''neill'),
        ('brian', 'cush'),
        ('shane', 'quinn'),
        ('yasmin', 'rankin'),
        ('oluwakayode', 'adebayo'),
        ('celine', 'brown'),
        ('carl', 'greaves'),
        ('emma', 'bendall'),
        ('aidan', 'treece'),
        ('daniel', 'taggart'),
        ('peceli', 'bulivou'),
        ('rikki-lee', 'kenny'),
        ('charlotte', 'beaumont'),
        ('molly', 'stacey-jones'),
        ('ahmad', 'hamidi'),
        ('michal', 'majewski'),
        ('daryl', 'cooper'),
        ('anthony', 'bennett'),
        ('valeen', 'mcaneney'),
        ('kelly', 'chilton'),
        ('adrian', 'mccollum'),
        ('jane', 'ashcroft'),
        ('rhonda', 'mcdowell'),
        ('hannah', 'moore'),
        ('eden', 'hoskins'),
        ('walter', 'townsley'),
        ('paige', 'cousins'),
        ('christina', 'mccullough'),
        ('isobel', 'mcgarry'),
        ('jordan', 'harradine'),
        ('lynne', 'corr'),
        ('nicole', 'kerr'),
        ('nicola', 'henderson'),
        ('laura', 'collins'),
        ('zoe', 'milne'),
        ('simon', 'wright'),
        ('natalee', 'mccabe'),
        ('natalie', 'james'),
        ('karen', 'davies'),
        ('amy', 'lumberg'),
        ('lisa', 'topp'),
        ('daniel', 'burden')
),

-- 2. Match names to Motor Applications
lookers_cohort AS (
    SELECT DISTINCT
        prs.application_id,
        prs.origination_risk_grade,
        prs.loan_id,
        fu.FIRSTNAME,
        fu.LASTNAME,
        prs.origination_datetime
    FROM prod.prs_motor.prs__application__motor prs
    INNER JOIN raw_production.motor_uk_lendable.fosuser fu
        ON prs.user_id = fu.id
    INNER JOIN spreadsheet_names sn
        ON LOWER(TRIM(fu.FIRSTNAME)) = sn.first_name
        AND LOWER(TRIM(fu.LASTNAME)) = sn.last_name
    WHERE
        prs.flag_originated = 1

    -- [DEDUPLICATION LOGIC] Keep most recent deal per person
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY LOWER(TRIM(fu.FIRSTNAME)), LOWER(TRIM(fu.LASTNAME))
        ORDER BY prs.origination_datetime DESC
    ) = 1
),

-- 3. Get Status Details
loan_details AS (
    SELECT
        lc.application_id,
        lc.loan_id,
        lc.FIRSTNAME,
        lc.LASTNAME,
        lc.origination_risk_grade,

        -- Actual loan status from HP loan table (e.g. 'live', 'settled', 'charged off', etc.)
        hp.SECONDARYSTATE as loan_status,

        -- A. Arrears Status (Latest Snapshot)
        COALESCE(arr.adjusted_months_in_arrears, 0) as months_in_arrears,

        -- B. Termination Status
        term.terminated_at,

        -- C. Flag 90 by 9
        COALESCE(dq.dq_90_by_9, 0) as flag_90_by_9

    FROM lookers_cohort lc

    -- Join HP Loan Table for actual loan state
    LEFT JOIN PROD.STG_MOTOR_LENDABLE.stg__hirepurchaseloan__motor_lendable hp
        ON lc.loan_id = hp.ID

    -- Join Arrears Table
    LEFT JOIN (
        SELECT loan_id, adjusted_months_in_arrears
        FROM PROD.INT_MOTOR.INT__CONTRACTUAL_PAYMENTARREARS__MOTOR
        QUALIFY ROW_NUMBER() OVER (PARTITION BY loan_id ORDER BY payment_date DESC) = 1
    ) arr ON lc.loan_id = arr.loan_id

    -- Join Termination Ledger
    LEFT JOIN PROD.STG_MOTOR_LENDABLE.STG__RECOVERIES_TERMINATION_LEDGER__MOTOR_LENDABLE term
        ON lc.loan_id = term.loan_id

    -- Join Delinquency Flags
    LEFT JOIN (
        SELECT loan_id, MAX(dq_90_by_9) as dq_90_by_9
        FROM PROD.MRT_MOTOR.MRT__DELINQUENCY_FLAGS_BY_MONTH__MOTOR
        GROUP BY 1
    ) dq ON lc.loan_id = dq.loan_id
)

-- 4. Final Output
SELECT
    application_id,
    INITCAP(FIRSTNAME) as first_name,
    INITCAP(LASTNAME) as surname,
    origination_risk_grade,

    flag_90_by_9,

    -- Column 1: Is it currently in 3m+ Arrears?
    CASE
        WHEN terminated_at IS NULL
             AND loan_status NOT ILIKE '%settled%'
             AND months_in_arrears >= 3.0 THEN 1
        ELSE 0
    END as count_arrears_3m_plus,

    -- Column 2: Is it Terminated or VT'd?
    CASE
        WHEN terminated_at IS NOT NULL THEN 1
        ELSE 0
    END as count_terminated_or_vt,

    -- Column 3: Is it Settled / Complete?
    -- Uses SECONDARYSTATE from the HP loan table (the actual loan status).
    -- Flags 1 only for early repayment or fully completed loans.
    CASE
        WHEN loan_status ILIKE '%settled%' THEN 1
        ELSE 0
    END as count_settled

FROM loan_details
ORDER BY
    surname,
    first_name;
