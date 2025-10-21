-- Exploratory Data Analysis (EDA)

SELECT *
FROM Layoffs_2;

SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM Layoffs_2;

-- Looking at date range
-- It covers 2020 through 2023, starting when the COVID-19 pandemic began
SELECT COUNT(*), MIN(`date`) AS min_date, MAX(`date`) AS max_date       
FROM layoffs_2;

-- Percent should be in [0,1]. This finds suspicious values
-- It shows, there is no suspicious values
SELECT *
FROM layoffs_2
WHERE percentage_laid_off < 0 OR percentage_laid_off > 1;

-- Looking at companies with 100% layoffs
SELECT *
FROM Layoffs_2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

SELECT DISTINCT(company)
FROM Layoffs_2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

SELECT *
FROM Layoffs_2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- Looking at all total_laid_off vs company between 2020-2023
SELECT company, SUM(total_laid_off)
FROM Layoffs_2
GROUP BY company
ORDER BY SUM(total_laid_off) DESC;

-- Which industries experienced the most layoffs over this period
SELECT industry, SUM(total_laid_off)
FROM Layoffs_2
GROUP BY industry
ORDER BY SUM(total_laid_off) DESC;

-- Countries
-- United States had by far the most layoffs over this period
SELECT country, SUM(total_laid_off)
FROM Layoffs_2
GROUP BY country
ORDER BY SUM(total_laid_off) DESC;

-- Year
SELECT YEAR(`date`), SUM(total_laid_off)
FROM Layoffs_2
GROUP BY YEAR(`date`)
ORDER BY YEAR(`date`) DESC;

-- Stage
SELECT stage, SUM(total_laid_off)
FROM Layoffs_2
GROUP BY stage
ORDER BY 2 DESC;

-- Monthly
SELECT DATE_FORMAT(`date`, '%Y-%m') AS month, SUM(total_laid_off),
	   COUNT(*) events
FROM Layoffs_2
WHERE DATE_FORMAT(`date`, '%Y-%m') IS NOT NULL
GROUP BY month
ORDER BY month;

-- Rolling monthly total
WITH Rolling_Total AS
(
 SELECT DATE_FORMAT(`date`, '%Y-%m') AS `month`, SUM(total_laid_off) AS total_off
 FROM Layoffs_2
 WHERE DATE_FORMAT(`date`, '%Y-%m') IS NOT NULL
 GROUP BY `month`
 ORDER BY `month`
 )
 SELECT `month`, total_off, SUM(total_off) OVER(ORDER BY `month`) AS rolling_total 
 FROM Rolling_Total;
 
 -- Company vs Year
 SELECT company, YEAR(`date`) AS years, SUM(total_laid_off) AS total_off
 FROM Layoffs_2
 GROUP BY 1,2
 ORDER BY 3 DESC;
 
 -- Rank by sum total_laid_off within each year 
 -- To see which company laid off the most people per year
 WITH Company_Year(company, years, total_off) AS
 (
  SELECT company, YEAR(`date`) AS years, SUM(total_laid_off) AS total_off
  FROM Layoffs_2
  GROUP BY 1,2
  )
 SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_off DESC) AS ranking
 FROM Company_Year
 WHERE years IS NOT NULL
 ORDER BY ranking;
 
 -- Filter the rankings to show only the top five companies per year
  WITH Company_Year(company, years, total_off) AS
 (
  SELECT company, YEAR(`date`) AS years, SUM(total_laid_off) AS total_off
  FROM Layoffs_2
  GROUP BY 1,2
  ), Company_Year_Rank AS
  (
 SELECT *, DENSE_RANK() OVER(PARTITION BY years ORDER BY total_off DESC) AS ranking
 FROM Company_Year
 WHERE years IS NOT NULL
 )
 SELECT *
 FROM Company_Year_Rank
 WHERE ranking <= 5;
  