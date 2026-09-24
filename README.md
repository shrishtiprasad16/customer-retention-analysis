# Customer Retention & Value Analysis

## Business Problem

A business can generate strong overall revenue while still losing valuable customers or failing to retain them.

This project analyzes customer purchasing behavior to identify high-value customers, repeat-purchase patterns, retention trends, and reactivation opportunities.

## Key Business Question

> Which customers are most valuable, which customers are at risk of being lost, and what actions can the business take to improve customer retention and lifetime value?

---

## Analysis Objectives

- Understand customer purchase frequency and repeat behavior
- Measure the time between first and second purchases
- Compare first-purchase and subsequent-purchase value
- Identify high-value and inactive customer groups
- Analyze customer retention across acquisition cohorts
- Identify customer groups that should receive retention or reactivation attention

---

## Dataset

**Online Retail Dataset — UCI Machine Learning Repository**

The dataset contains transactions from a UK-based online retailer between December 2010 and December 2011.

After data cleaning:

- **392,692** customer transaction records
- **4,338** unique customers
- **18,532** unique invoices
- **£8.89M** customer revenue

---

## Key Findings

### 1. Customer value is highly concentrated

The highest-value customer segment represents a relatively small share of customers while contributing a disproportionately large share of revenue.

This makes customer value an important dimension when prioritizing retention activity.

### 2. Repeat purchasing is widespread but not universal

- **65.6%** of customers made more than one purchase.
- **34.4%** of customers purchased only once.

This indicates a substantial opportunity to improve repeat purchasing.

### 3. Frequent customers contribute disproportionately to revenue

Only **7.8%** of customers fall into the Frequent purchase group, but they generate approximately **49.3% of customer revenue**.

### 4. The second purchase takes time

Repeat customers took an average of **76.7 days** to make their second purchase.

The median was **50.1 days**, indicating that some longer return intervals increase the overall average.

### 5. High-value inactivity represents a retention priority

High Value – At Risk customers account for approximately **£851.9K in historical revenue**.

Historical revenue represents past customer value and should not be interpreted as guaranteed recoverable revenue.

### 6. Customer engagement varies across cohorts

Cohort activity retention differs across acquisition months, providing a way to compare repeat engagement patterns over time.

---

## Analytical Approach

### Customer Behavior
- Purchase frequency
- One-time vs repeat customers
- First-to-second purchase timing
- Purchase sequence analysis

### Customer Value
- Revenue concentration
- RFM-based customer segmentation
- Customer value groups

### Retention
- Inactivity analysis
- Cohort retention
- High-value inactive customers
- Reactivation priorities

---

## Tools & Technologies

| Tool | Purpose |
|---|---|
| Python | Data cleaning, customer analysis, RFM segmentation, cohort analysis |
| SQL | Customer behavior, purchase sequence, inactivity and retention analysis |
| Power BI | Interactive dashboard and business insights |

---

## Project Structure

```text
customer-retention-analysis/
│
├── python/
│   └── Customer_Retention_Analysis.ipynb
│
├── sql/
│   └── customer_retention_analysis.sql
│
├── powerbi/
│   └── Customer_Retention_Analysis.pbix
│
└── images/
    ├── dashboard.png
    ├── cohort_retention.png
    └── retention_priorities.png
