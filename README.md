# Global Layoffs (2020–2023)

This project analyzes global layoff events from 2020–2023 using SQL (MySQL) for data cleaning and exploratory analysis, and Tableau for interactive visualization. The goal is to understand how layoffs were distributed globally during this period and to surface insights such as:


1) How many people were laid off worldwide


2) Which countries, cities/locations, and industries were most affected


3) Which companies had the largest layoffs each year


4) How layoffs evolved over time (monthly trends and rolling totals)


5) At which funding stages (e.g., early-stage vs. late-stage) companies were laying off staff


The final Tableau dashboard summarizes the answers to these questions.

**The work is organized around three main components:**

- Data Cleaning Pipeline – Transforms the raw layoff dataset into an analysis-ready table.
- SQL EDA Queries – Answer key business questions about layoffs by country, industry, year, and company.
- Tableau Dashboard – Visually tells the story of ~400K layoffs across more than 50 countries.



## Project Files

- `layoffs_raw.csv`
- `World_layoffs_Cleaning_data.sql`: Contains all SQL queries used to clean the dataset  
- `World_layoffs_Exploratory_data_analysis.sql`: Contains all SQL queries used to explore, and analyze the dataset
- `Global Layoffs Dashboard (2020-2013).png`: The picture of the Tableau Visualization Dashboard


  
##  Cleaning Data `( World_layoffs_Cleaning_data.sql )`

- The script creates a clean, analysis-ready table layoffs_2 from the raw layoff data.
- It first selects only relevant columns (via layoffs_1) and removes unused/blank ones.
- Duplicates are identified with ROW_NUMBER() over key fields and removed, keeping just one copy.
- Text fields (company, industry, country) are standardized and the date column is converted from text to a proper DATE type.
- Rows with no layoff information and empty key fields are dropped, leaving layoffs_2 ready for all EDA queries and the Tableau dashboard.


## Exploratory Data Analysis `( World_layoffs_Exploratory_data_analysis.sql )`

This script uses the cleaned layoffs_2 table to perform core exploratory analysis on global layoffs. It runs basic quality checks on maximum layoffs and validates that percentage_laid_off stays within the [0, 1] range. It confirms time coverage (2020–2023) and identifies 100% layoff events, ranking them by total layoffs and funds raised. It then aggregates layoffs by company, industry, country, year, and funding stage to power the “Top 10” and stage views in the dashboard. The script also computes monthly totals and rolling cumulative layoffs, which drive the monthly trend line chart. Finally, it ranks companies by total layoffs per year and returns the top five, used in the “Top 5 Companies by Layoffs — Yearly View.


## Tableau Dashboard
The Tableau workbook (not included in this repo) connects to the cleaned table layoffs_2 and uses the EDA outputs to drive visualizations.

Key dashboard elements:

1) Filters:
- Month (dropdown + calendar)
- Stage (funding/operational stage)

2) KPI summary for Events, Countries, Companies, and Total Laid Off 

3) Line chart of Monthly Average Total Laid Off

4) World map colored by total layoffs per country

5) Bar charts for:

- Top 10 locations by total layoffs
- Top 10 industries by total layoffs
- Top 5 companies per year (2021, 2022, 2023)



## Visualization

![Global Layoffs Dashboard (2020-2013)](https://github.com/maryamsh62/Clean-and-Explore-World-Layoffs-Data/blob/main/Global%20Layoffs%20Dashboard%20(2020-2013).png)


[TableauPublic](https://public.tableau.com/app/profile/maryamsadat.shakeri/viz/GlobalLayoffsOverview2020-2023/GlobaLayoffsOverview2020-2023) 


