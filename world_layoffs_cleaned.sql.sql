-- CREATE A STAGING TABLE IN ORDER TO NOT CONTAMINATE THE RAW DATA
CREATE TABLE world_layoffs.layoffs_staging 
LIKE world_layoffs.layoffs;

INSERT layoffs_staging 
SELECT * FROM world_layoffs.layoffs;

-- 1. Remove Duplicates
-- 1.1 CHECKING FOR DUPLICATES
SELECT *
FROM (
	SELECT company, industry, total_laid_off,`date`,
		ROW_NUMBER() OVER (
			PARTITION BY company, industry, total_laid_off,`date`
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;

-- 1.2 CHECK "ODA" TO SEE CONFIRM DUPLICATE
SELECT *
FROM world_layoffs.layoffs_staging
WHERE company = 'Oda'

-- 1.3 "ODA" HAVE MORE THAN 1 ENTRIES SO THERE ARE NOT DUPLICATE, NEED TO RECHECK ON ALL ROW

SELECT *
FROM (
	SELECT company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;
    
    
-- 1.4 IN ORDER TO DELETE DUPLICATE, ADD IN A COLUMN 'ROW_NUM' AND THEN DELETE THE ROWS WHERE ROW_NUM > 2
ALTER TABLE world_layoffs.layoffs_staging ADD row_num INT;


SELECT *
FROM world_layoffs.layoffs_staging
;

CREATE TABLE `world_layoffs`.`layoffs_staging2` (
`company` text,
`location`text,
`industry`text,
`total_laid_off` INT,
`percentage_laid_off` text,
`date` text,
`stage`text,
`country` text,
`funds_raised_millions` int,
row_num INT
);

INSERT INTO `world_layoffs`.`layoffs_staging2`
(`company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
`row_num`)
SELECT `company`,
`location`,
`industry`,
`total_laid_off`,
`percentage_laid_off`,
`date`,
`stage`,
`country`,
`funds_raised_millions`,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off,percentage_laid_off,`date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging;

-- 1.5 DELETE DUPLICATE 
DELETE FROM world_layoffs.layoffs_staging2
WHERE row_num >= 2;

-- 2. Standardize Data
-- 2.1 TAKE A LOOK AT SOME NULL AND BLANK VALUES
SELECT * 
FROM world_layoffs.layoffs_staging2;

SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

SELECT *
FROM world_layoffs.layoffs_staging2
WHERE industry IS NULL 
OR industry = ''
ORDER BY industry;

-- 2.2 TAKE A MORE DETAILED LOOK 
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE company LIKE 'airbnb%';
-- Airbnb have two rows but 1 is emtry in the Industry column - > write a query that if there is another row with the same company name, it will update it to the non-null industry values

-- 2.3 SET THE BLANK TO NULL SO IT'S EASIER TO WORK WITH
UPDATE world_layoffs.layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- 2.4 UPDATE THE NULL WITH VALUE IF THE COMPANY NAME MATCHES BY JOINING THE TABLE TO IT SELF
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

-- 2.5 UPDATE THE INDUSTRY COLUMN DUE TO THE "CRYPTO" HAVE MANY VARIATIONS
SELECT DISTINCT industry
FROM world_layoffs.layoffs_staging2
ORDER BY industry;

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE ('Crypto%');

-- 2.6 UPDATE THE COUNTRY COLUMN DUE TO "UNITED STATES" AND "UNITED STATES."
SELECT DISTINCT country
FROM world_layoffs.layoffs_staging2
ORDER BY country;

UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country);

-- 2.7 UPDATE THE DATE COLUMN DUE TO THE DATE COLUMN IS IN TEXT FORMAT
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

-- CONVERT THE DATA TYPE
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- 3. NULL VALUES
-- DUE TO BOTH 'total_laid_off' and 'percentage_laid_off' is null. DELETE THEM
SELECT *
FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE FROM world_layoffs.layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- 4. DROP COLUMN 
-- 4.1. DROP ROW_NUM COLUMN 
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;


    