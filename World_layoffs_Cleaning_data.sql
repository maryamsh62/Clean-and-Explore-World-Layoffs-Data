-- Cleaning Data

-- 1. Remove Duplicates
-- 2. Standardize The Data
-- 3. Null Values or Blank Values
-- 4. Remove Any Columns or rows


SELECT *
FROM layoffs_raw;


/* When working with large databases, if certain columns are completely blank or irrelevant, and
 no ETL (Extract, Transform, Load) depends on them, you can exclude them to speed up queries.
 In production, raw tables are often fed by automated imports from multiple sources, so dropping columns from
 the raw dataset can break pipelines. Instead, create another table and copy/select only the needed columns
 from the raw table into it. This preserves the original data while keeping your queries lean. */
 
 /* Why: We’re about to make significant changes to the database. If we make a mistake, we need the raw data to
 remain available for recovery and validation. */
 
CREATE TABLE layoffs_1
LIKE layoffs_raw;

-- Test
SELECT *
FROM layoffs_1;

INSERT layoffs_1
SELECT *
FROM layoffs_raw;

-- Test
SELECT *
FROM layoffs_1;



-- 1. Remove Duplicates

/* We want to ensure there are no duplicate records in the database. However, this table lacks
 a clear unique identifier (e.g., a primary key/unique ID), which means de-duplication is not 
 going to be easy. */
 
 /* What we do:
We use ROW_NUMBER() partitioned by all of these columns then we will see if there are
any duplicates. Any row with ROW_NUMBER() > 1 within a partition is a duplicate and can
 be reviewed or removed. */
 
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,`date`,
stage, country, funds_raised_millions) AS row_num
FROM layoffs_1;

WITH duplicate_cte AS
( SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,`date`,
stage, country, funds_raised_millions) AS row_num
FROM layoffs_1
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;  -- Show all duplicates

/* In MySQL, removing duplicate rows via a CTE is trickier than in systems like Microsoft SQL Server
 or PostgreSQL. In SQL Server, you can assign ROW_NUMBER() in a CTE and DELETE directly from that CTE,
 which updates the underlying table. MySQL doesn’t allow this—attempting to delete from a CTE
 (or other non-updatable target) raises: “The target table 'duplicate_cte' of the DELETE is not
 updatable.” */
 
 -- Create layoffs_2 table and add row_num column into it
 CREATE TABLE `layoffs_2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Test
SELECT *
FROM layoffs_2;

INSERT INTO layoffs_2
 SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off,`date`,
stage, country, funds_raised_millions) AS row_num
FROM layoffs_1;

-- Show all duplicates that need  to be deleted
SELECT *
FROM layoffs_2
WHERE row_num > 1;

-- Removing all duplicates
DELETE
FROM layoffs_2
WHERE row_num > 1;

-- Test
SELECT *
FROM layoffs_2
WHERE row_num > 1;



-- 2. Standardize The Data
 
/* Standardizing means finding issues in data and then fixing it. */  

SELECT DISTINCT (company)
FROM layoffs_2;
 
-- Remove white spaces around company names in company coulmn
SELECT company, TRIM(company)
FROM layoffs_2;

UPDATE layoffs_2
SET company = TRIM(company);

-- looking at industry 
/* These are name variants for the same company; we should standardize them to a single label (e.g., ‘Crypto’). */

SELECT DISTINCT (industry)
FROM layoffs_2
ORDER BY 1;

-- It appears that ‘Crypto,’ ‘Crypto Currency,’ and ‘CryptoCurrency’ refer to the same company.
SELECT *
FROM  layoffs_2
WHERE industry LIKE 'Crypto%';
 
UPDATE  layoffs_2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Test
SELECT DISTINCT (industry)
FROM layoffs_2
ORDER BY 1;

-- Scan through location. It looks fine.
SELECT DISTINCT (location)
FROM layoffs_2
ORDER BY 1;

-- Looking at country
-- Through scrolling down, we found an issue (United States, United States.)
SELECT DISTINCT (country)
FROM layoffs_2
ORDER BY 1;

-- Scrolling through this shows the correct value should be United States.
SELECT *
FROM layoffs_2
WHERE country like 'United States%';

SELECT DISTINCT (country), TRIM(TRAILING '.' FROM country)
FROM layoffs_2
ORDER BY 1;

UPDATE layoffs_2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country like 'United States%';

-- Test
SELECT DISTINCT (country)
FROM layoffs_2
ORDER BY 1;

-- Looking at date
-- Convert the date field from text to a proper date data type.
SELECT `date`,
STR_TO_DATE (`date`, '%m/%d/%Y')
FROM layoffs_2;

UPDATE  layoffs_2
SET `date` = STR_TO_DATE (`date`, '%m/%d/%Y');

ALTER TABLE layoffs_2
MODIFY COLUMN `date` DATE;

-- Test
SELECT *
FROM layoffs_2;



-- 3. Null Values or Blank Values
 
SELECT *
FROM layoffs_2;
 
/* If both total_laid_off and percentage_laid_off are null, the record provides no layoff signal and can
be excluded (or dropped) from analysis. */

SELECT *
FROM layoffs_2
WHERE total_laid_off is NULL
AND percentage_laid_off is NULL;

-- Looking at industry to see if it has any null or missing value
SELECT DISTINCT (industry)
FROM layoffs_2;

SELECT * 
FROM layoffs_2
WHERE industry is NULL 
OR industry = '';
/* Four records are returned. We’re checking whether any of these companies have at least one record with the field (industry) populated;
if they do, we can use it to fill the missing values across their other layoff records. */
 
 
SELECT * 
FROM layoffs_2
WHERE company = 'Airbnb';
/*  For example, reviewing Airbnb shows its industry is ‘Travel’, so we can use that value to populate any missing
 industry entries for Airbnb. */
 
-- Use a self-join to populate the industry field wherever it is NULL or blank.
UPDATE  Layoffs_2
SET industry = Null
WHERE industry = '';

SELECT *
FROM Layoffs_2 t1
JOIN Layoffs_2 t2
    ON t1.company = t2.company
    AND t1.location = t2.location
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL; 

UPDATE Layoffs_2 t1
JOIN Layoffs_2 t2
    ON t1.company = t2.company
    AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- Test
SELECT t1.industry, t2.industry
FROM Layoffs_2 t1
JOIN Layoffs_2 t2
    ON t1.company = t2.company
    AND t1.location = t2.location
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

SELECT * 
FROM layoffs_2
WHERE company = 'Airbnb';

 

-- It shows we still have one company with a null industry value.
SELECT * 
FROM layoffs_2
WHERE industry is NULL 
OR industry = '';

-- Check how many rows this company has
SELECT *
FROM Layoffs_2
WHERE company LIKE 'Bally%';

/* There was only one such company ( Bally's Interactive). Unlike Carvana, Airbnb, and Juul 
which have multiple layoff rows we could use to populate, this company has a single record,
so there’s no non-null industry value to copy and its industry remains null. */
 
 
 
-- 4. Remove Any Columns or rows

/* If both total_laid_off and percentage_laid_off are null, the record provides no layoff signal and can
be excluded (or dropped) from analysis. */ 
/* We’re cautious about deleting data, but our next steps rely heavily on total_laid_off and percentage_laid_off.
Rows where these fields are null add no analytic value, so we’ll exclude (drop) them from analysis. */
SELECT *
FROM layoffs_2
WHERE total_laid_off is NULL
AND percentage_laid_off is NULL;

DELETE
FROM layoffs_2
WHERE total_laid_off is NULL
AND percentage_laid_off is NULL;

-- Test
SELECT *
FROM layoffs_2
WHERE total_laid_off is NULL
AND percentage_laid_off is NULL;

-- We do not need row_num column anymore
ALTER TABLE Layoffs_2
DROP COLUMN row_num;

-- Test
SELECT *
FROM layoffs_2;  -- Here is the finalized clean dataset, ready for analysis

