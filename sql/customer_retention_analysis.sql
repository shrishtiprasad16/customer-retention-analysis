USE customer_retention;

-- =====================================================
-- 01. DATA VALIDATION
-- =====================================================
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT CustomerID) AS unique_customers,
    COUNT(DISTINCT InvoiceNo) AS unique_invoices,
    COUNT(*) - COUNT(CustomerID) AS missing_customer_ids,
    COUNT(*) - COUNT(InvoiceNo) AS missing_invoice_numbers,
    MIN(InvoiceDate) AS first_transaction,
    MAX(InvoiceDate) AS last_transaction
FROM transactions;

-- =====================================================
-- 02. CUSTOMER PURCHASE BEHAVIOR
-- First-to-Second Purchase Timing
-- =====================================================
WITH customer_invoices AS (
    SELECT
        CustomerID,
        InvoiceNo,
        MIN(InvoiceDate) AS purchase_date
    FROM transactions
    GROUP BY
        CustomerID,
        InvoiceNo
),

ranked_purchases AS (
    SELECT
        CustomerID,
        InvoiceNo,
        purchase_date,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID
            ORDER BY purchase_date,InvoiceNo
        ) AS purchase_number
    FROM customer_invoices
),

first_second_purchase AS (
    SELECT
        CustomerID,
        MAX(
            CASE
                WHEN purchase_number = 1
                THEN purchase_date
            END
        ) AS first_purchase_date,
        MAX(
            CASE
                WHEN purchase_number = 2
                THEN purchase_date
            END
        ) AS second_purchase_date
    FROM ranked_purchases
    GROUP BY CustomerID
) 
SELECT
    COUNT(*) AS repeat_customers,
    ROUND(
        AVG(
            DATEDIFF(
                second_purchase_date,
                first_purchase_date
            )
        ),
        1
    ) AS avg_days_to_second_purchase,
    MIN(
        DATEDIFF(
            second_purchase_date,
            first_purchase_date
        )
    ) AS min_days,
    MAX(
        DATEDIFF(
            second_purchase_date,
            first_purchase_date
        )
    ) AS max_days
FROM first_second_purchase
WHERE second_purchase_date IS NOT NULL;



-- =====================================================
-- 03. SECOND-PURCHASE TIMING DISTRIBUTION
-- =====================================================
WITH customer_invoices AS (
    SELECT
        CustomerID,
        InvoiceNo,
        MIN(InvoiceDate) AS purchase_date
    FROM transactions
    GROUP BY
        CustomerID,
        InvoiceNo
),

ranked_purchases AS (
    SELECT
        CustomerID,
        purchase_date,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID
            ORDER BY purchase_date , InvoiceNo
        ) AS purchase_number
    FROM customer_invoices
),

return_timing AS (
    SELECT
        CustomerID,
        DATEDIFF(
            MAX(CASE WHEN purchase_number = 2 THEN purchase_date END),
            MAX(CASE WHEN purchase_number = 1 THEN purchase_date END)
        ) AS days_to_second_purchase
    FROM ranked_purchases
    GROUP BY CustomerID
),

repeat_customers AS (
    SELECT *
    FROM return_timing
    WHERE days_to_second_purchase IS NOT NULL
)

SELECT
    CASE
        WHEN days_to_second_purchase <= 7 THEN '0-7 days'
        WHEN days_to_second_purchase <= 30 THEN '8-30 days'
        WHEN days_to_second_purchase <= 60 THEN '31-60 days'
        WHEN days_to_second_purchase <= 90 THEN '61-90 days'
        WHEN days_to_second_purchase <= 180 THEN '91-180 days'
        ELSE '181+ days'
    END AS second_purchase_window,
    
    COUNT(*) AS customers,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM repeat_customers),
        2
    ) AS customer_share

FROM repeat_customers

GROUP BY
    CASE
        WHEN days_to_second_purchase <= 7 THEN '0-7 days'
        WHEN days_to_second_purchase <= 30 THEN '8-30 days'
        WHEN days_to_second_purchase <= 60 THEN '31-60 days'
        WHEN days_to_second_purchase <= 90 THEN '61-90 days'
        WHEN days_to_second_purchase <= 180 THEN '91-180 days'
        ELSE '181+ days'
    END

ORDER BY
    CASE second_purchase_window
        WHEN '0-7 days' THEN 1
        WHEN '8-30 days' THEN 2
        WHEN '31-60 days' THEN 3
        WHEN '61-90 days' THEN 4
        WHEN '91-180 days' THEN 5
        WHEN '181+ days' THEN 6
    END;
    -- =====================================================
-- 04. PURCHASE SEQUENCE VALUE
-- First Purchase vs Subsequent Purchases
-- =====================================================
WITH customer_invoices AS (
    SELECT
        CustomerID,
        InvoiceNo,
        MIN(InvoiceDate) AS purchase_date,
        SUM(Revenue) AS invoice_revenue
    FROM transactions
    GROUP BY
        CustomerID,
        InvoiceNo
),

ranked_purchases AS (
    SELECT
        CustomerID,
        InvoiceNo,
        purchase_date,
        invoice_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID
            ORDER BY purchase_date, InvoiceNo
        ) AS purchase_number
    FROM customer_invoices
)

SELECT
    CASE
        WHEN purchase_number = 1
            THEN 'First Purchase'
        ELSE 'Subsequent Purchases'
    END AS purchase_stage,

    COUNT(DISTINCT CustomerID) AS customers,
    COUNT(*) AS invoices,
    ROUND(SUM(invoice_revenue), 2) AS revenue,
    ROUND(AVG(invoice_revenue), 2) AS average_invoice_value

FROM ranked_purchases

GROUP BY
    CASE
        WHEN purchase_number = 1
            THEN 'First Purchase'
        ELSE 'Subsequent Purchases'
    END

ORDER BY
    CASE
        WHEN purchase_stage = 'First Purchase' THEN 1
        ELSE 2
    END;
    -- =====================================================
-- 05. PURCHASE SEQUENCE DEPTH
-- Revenue by Purchase Number
-- =====================================================
WITH customer_invoices AS (
    SELECT
        CustomerID,
        InvoiceNo,
        MIN(InvoiceDate) AS purchase_date,
        SUM(Revenue) AS invoice_revenue
    FROM transactions
    GROUP BY
        CustomerID,
        InvoiceNo
),

ranked_purchases AS (
    SELECT
        CustomerID,
        InvoiceNo,
        purchase_date,
        invoice_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY CustomerID
            ORDER BY purchase_date, InvoiceNo
        ) AS purchase_number
    FROM customer_invoices
)

SELECT
    CASE
        WHEN purchase_number = 1 THEN '1st Purchase'
        WHEN purchase_number = 2 THEN '2nd Purchase'
        WHEN purchase_number = 3 THEN '3rd Purchase'
        ELSE '4th+ Purchase'
    END AS purchase_stage,

    COUNT(*) AS invoices,
    COUNT(DISTINCT CustomerID) AS customers,
    ROUND(SUM(invoice_revenue), 2) AS revenue,
    ROUND(AVG(invoice_revenue), 2) AS average_invoice_value

FROM ranked_purchases

GROUP BY
    CASE
        WHEN purchase_number = 1 THEN '1st Purchase'
        WHEN purchase_number = 2 THEN '2nd Purchase'
        WHEN purchase_number = 3 THEN '3rd Purchase'
        ELSE '4th+ Purchase'
    END

ORDER BY
    CASE purchase_stage
        WHEN '1st Purchase' THEN 1
        WHEN '2nd Purchase' THEN 2
        WHEN '3rd Purchase' THEN 3
        ELSE 4
    END;
  -- =====================================================
-- 06. CUSTOMER INACTIVITY & VALUE
-- =====================================================
-- -----------------------------------------------------
-- 06A. INACTIVITY BANDS
-- -----------------------------------------------------

WITH customer_activity AS (
    SELECT
        CustomerID,
        MAX(InvoiceDate) AS last_purchase,
        COUNT(DISTINCT InvoiceNo) AS purchase_count,
        SUM(Revenue) AS total_revenue
    FROM transactions
    GROUP BY CustomerID
),

repeat_customers AS (
    SELECT
        CustomerID,
        last_purchase,
        purchase_count,
        total_revenue,
        DATEDIFF(
            (SELECT MAX(InvoiceDate) FROM transactions),
            last_purchase
        ) AS days_since_last_purchase
    FROM customer_activity
    WHERE purchase_count >= 2
)

SELECT
    CASE
        WHEN days_since_last_purchase <= 30
            THEN '0-30 days'
        WHEN days_since_last_purchase <= 60
            THEN '31-60 days'
        WHEN days_since_last_purchase <= 90
            THEN '61-90 days'
        WHEN days_since_last_purchase <= 180
            THEN '91-180 days'
        ELSE '181+ days'
    END AS inactivity_band,

    COUNT(*) AS customers,

    ROUND(
        SUM(total_revenue), 2
    ) AS historical_revenue,

    ROUND(
        AVG(total_revenue), 2
    ) AS average_customer_revenue

FROM repeat_customers

GROUP BY
    CASE
        WHEN days_since_last_purchase <= 30
            THEN '0-30 days'
        WHEN days_since_last_purchase <= 60
            THEN '31-60 days'
        WHEN days_since_last_purchase <= 90
            THEN '61-90 days'
        WHEN days_since_last_purchase <= 180
            THEN '91-180 days'
        ELSE '181+ days'
    END

ORDER BY
    CASE inactivity_band
        WHEN '0-30 days' THEN 1
        WHEN '31-60 days' THEN 2
        WHEN '61-90 days' THEN 3
        WHEN '91-180 days' THEN 4
        WHEN '181+ days' THEN 5
    END;


-- -----------------------------------------------------
-- 06B. INACTIVITY × CUSTOMER VALUE
-- -----------------------------------------------------

WITH customer_activity AS (
    SELECT
        CustomerID,
        MAX(InvoiceDate) AS last_purchase,
        COUNT(DISTINCT InvoiceNo) AS purchase_count,
        SUM(Revenue) AS total_revenue
    FROM transactions
    GROUP BY CustomerID
),

repeat_customers AS (
    SELECT
        CustomerID,
        last_purchase,
        purchase_count,
        total_revenue,
        DATEDIFF(
            (SELECT MAX(InvoiceDate) FROM transactions),
            last_purchase
        ) AS days_since_last_purchase
    FROM customer_activity
    WHERE purchase_count >= 2
),

ranked_customers AS (
    SELECT
        *,
        NTILE(4) OVER (
            ORDER BY total_revenue DESC
        ) AS value_quartile
    FROM repeat_customers
)

SELECT
    CASE
        WHEN days_since_last_purchase <= 30
            THEN '0-30 days'
        WHEN days_since_last_purchase <= 60
            THEN '31-60 days'
        WHEN days_since_last_purchase <= 90
            THEN '61-90 days'
        WHEN days_since_last_purchase <= 180
            THEN '91-180 days'
        ELSE '181+ days'
    END AS inactivity_band,

    CASE
        WHEN value_quartile = 1
            THEN 'Highest Value'
        WHEN value_quartile = 2
            THEN 'High Value'
        WHEN value_quartile = 3
            THEN 'Medium Value'
        ELSE 'Lower Value'
    END AS customer_value_group,

    COUNT(*) AS customers,

    ROUND(
        SUM(total_revenue), 2
    ) AS historical_revenue,

    ROUND(
        AVG(total_revenue), 2
    ) AS average_customer_revenue

FROM ranked_customers

GROUP BY
    CASE
        WHEN days_since_last_purchase <= 30
            THEN '0-30 days'
        WHEN days_since_last_purchase <= 60
            THEN '31-60 days'
        WHEN days_since_last_purchase <= 90
            THEN '61-90 days'
        WHEN days_since_last_purchase <= 180
            THEN '91-180 days'
        ELSE '181+ days'
    END,

    CASE
        WHEN value_quartile = 1
            THEN 'Highest Value'
        WHEN value_quartile = 2
            THEN 'High Value'
        WHEN value_quartile = 3
            THEN 'Medium Value'
        ELSE 'Lower Value'
    END

ORDER BY
    CASE inactivity_band
        WHEN '0-30 days' THEN 1
        WHEN '31-60 days' THEN 2
        WHEN '61-90 days' THEN 3
        WHEN '91-180 days' THEN 4
        WHEN '181+ days' THEN 5
    END,
    historical_revenue DESC;
-- =====================================================
-- 07. COHORT RETENTION
-- =====================================================
WITH customer_monthly_purchases AS (
    SELECT DISTINCT
        CustomerID,
        DATE_FORMAT(InvoiceDate, '%Y-%m-01') AS purchase_month
    FROM transactions
),

customer_cohort AS (
    SELECT
        CustomerID,
        MIN(purchase_month) AS cohort_month
    FROM customer_monthly_purchases
    GROUP BY CustomerID
),

cohort_activity AS (
    SELECT
        p.CustomerID,
        c.cohort_month,
        p.purchase_month,
        TIMESTAMPDIFF(
            MONTH,
            c.cohort_month,
            p.purchase_month
        ) AS months_since_cohort
    FROM customer_monthly_purchases p
    JOIN customer_cohort c
        ON p.CustomerID = c.CustomerID
),

cohort_counts AS (
    SELECT
        cohort_month,
        months_since_cohort,
        COUNT(DISTINCT CustomerID) AS active_customers
    FROM cohort_activity
    GROUP BY
        cohort_month,
        months_since_cohort
),

cohort_sizes AS (
    SELECT
        cohort_month,
        MAX(
            CASE
                WHEN months_since_cohort = 0
                THEN active_customers
            END
        ) AS cohort_size
    FROM cohort_counts
    GROUP BY cohort_month
)

SELECT
    c.cohort_month,
    c.months_since_cohort,
    c.active_customers,
    s.cohort_size,
    ROUND(
        c.active_customers * 100.0 / s.cohort_size,
        2
    ) AS retention_rate
FROM cohort_counts c
JOIN cohort_sizes s
    ON c.cohort_month = s.cohort_month
ORDER BY
    c.cohort_month,
    c.months_since_cohort;
    
    -- =====================================================
-- 08. RETENTION OPPORTUNITIES
-- Retention Priority Summary
-- =====================================================

WITH customer_activity AS (
    SELECT
        CustomerID,
        MIN(InvoiceDate) AS first_purchase,
        MAX(InvoiceDate) AS last_purchase,
        COUNT(DISTINCT InvoiceNo) AS purchase_count,
        ROUND(SUM(Revenue), 2) AS total_revenue
    FROM transactions
    GROUP BY CustomerID
),

repeat_customers AS (
    SELECT
        *,
        DATEDIFF(
            (SELECT MAX(InvoiceDate) FROM transactions),
            last_purchase
        ) AS days_since_last_purchase
    FROM customer_activity
    WHERE purchase_count >= 2
),

ranked_customers AS (
    SELECT
        *,
        NTILE(4) OVER (
            ORDER BY total_revenue DESC
        ) AS value_quartile
    FROM repeat_customers
),

customer_priorities AS (
    SELECT
        CustomerID,
        total_revenue,
        days_since_last_purchase,

        CASE
            WHEN value_quartile = 1 THEN 'Highest Value'
            WHEN value_quartile = 2 THEN 'High Value'
            WHEN value_quartile = 3 THEN 'Medium Value'
            ELSE 'Lower Value'
        END AS customer_value_group,

        CASE
            WHEN days_since_last_purchase > 90
                 AND value_quartile <= 2
                THEN 'High Reactivation Priority'

            WHEN days_since_last_purchase > 60
                 AND value_quartile <= 2
                THEN 'Reactivation Priority'

            WHEN days_since_last_purchase > 90
                THEN 'Long Inactive'

            ELSE 'Active / Recently Active'
        END AS retention_priority

    FROM ranked_customers
)

SELECT
    retention_priority,
    COUNT(*) AS customers,
    ROUND(
        SUM(total_revenue), 2
    ) AS historical_revenue,
    ROUND(
        AVG(total_revenue), 2
    ) AS average_customer_revenue

FROM customer_priorities

GROUP BY retention_priority

ORDER BY
    CASE retention_priority
        WHEN 'High Reactivation Priority' THEN 1
        WHEN 'Reactivation Priority' THEN 2
        WHEN 'Long Inactive' THEN 3
        WHEN 'Active / Recently Active' THEN 4
    END;
