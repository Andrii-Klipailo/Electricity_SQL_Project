# Electricity_SQL_Project
![Electricity_logo](https://github.com/Andrii-Klipailo/Electricity_SQL_Project/blob/main/logo.jpg)
## Overview
This project analyzes global electricity production data, focusing on the growth and share of renewable energy sources over the past decade. The goal is to identify key trends and countries leading the transition to sustainable energy. Using SQL, the project uncovers insights into energy production patterns, highlighting the shift from traditional to renewable sources and the nations driving clean energy adoption.
## Objectives
- Analyze the growth of renewable energy production over the past decade.
- Determine the share of energy sources in total electricity production by country.
- Identify countries with significant shifts towards renewable energy.
- Compare global trends in energy production.
- Highlight leading countries in clean energy transitions.
## Dataset
The data for this project is sourced from the Kaggle dataset:
- **Dataset Link:** <a href="https://www.kaggle.com/datasets/scibearia/electricity-production-by-source" target="_blank">Electricity Dataset</a>
## Schema
```SQL

-- Creating the schema of electricity production by source.

DROP TABLE IF EXISTS energy_data
;

CREATE TABLE energy_data (
    id SERIAL PRIMARY KEY,
    Country TEXT,
    Code TEXT,
    Year INT,
    Coal NUMERIC,
    Gas NUMERIC,
    Nuclear NUMERIC,
    Hydro NUMERIC,
    Solar NUMERIC,
    Oil NUMERIC,
    Wind NUMERIC,
    Bioenergy NUMERIC,
    Other_renewables NUMERIC
)
;



-- Loaging the data into the schema.

COPY energy_data(Country, Code, Year, Coal, Gas, Nuclear, Hydro, Solar, Oil, Wind, Bioenergy, Other_renewables)
FROM 'C:/Users/Andrii/Electricity_project//energy_data.csv'
DELIMITER ','
CSV HEADER
;



-- Updating the schema to avoid NULL values.

UPDATE energy_data
SET
    Coal = COALESCE(Coal, 0),
    Gas = COALESCE(Gas, 0),
    Nuclear = COALESCE(Nuclear, 0),
    Hydro = COALESCE(Hydro, 0),
    Solar = COALESCE(Solar, 0),
    Oil = COALESCE(Oil, 0),
    Wind = COALESCE(Wind, 0),
    Bioenergy = COALESCE(Bioenergy, 0),
    Other_renewables = COALESCE(Other_renewables, 0)
;



-- Checking the data.

SELECT * FROM energy_data
LIMIT 10
;
```
## Business Questions and Solutions
### 1. Which countries have had the highest growth in electricity production from renewable sources over the last 10 years?
```SQL
WITH total_renew_last_year AS (
SELECT country
	,(wind + solar + hydro + bioenergy + other_renewables)	AS total_end
FROM energy_data
WHERE year = (SELECT MAX(year) FROM energy_data)
),

total_renew_10_years_ago AS (
SELECT country
	,(wind + solar + hydro + bioenergy + other_renewables)	AS total_start
FROM energy_data
WHERE year = (SELECT MAX(year) - 10 FROM energy_data)
)

SELECT country
	,ROUND(lst.total_end - ago.total_start, 2) AS energy_diff
	,ROUND(((lst.total_end - ago.total_start)/ago.total_start*100), 2) AS energy_diff_percentage
FROM total_renew_last_year lst
JOIN total_renew_10_years_ago ago
USING (country)
WHERE lst.total_end > 0 AND ago.total_start > 0
ORDER BY energy_diff DESC
;
```
**Fragment of the output:**
![output1](https://github.com/Andrii-Klipailo/Electricity_SQL_Project/blob/main/Output/answer%201.png)

### 2. What is the share of each type of energy source in total electricity production in each country for the last year in the dataset?
```SQL
WITH total_cte AS (
SELECT country
	,year
	,coal
	,gas
	,nuclear
	,hydro
	,solar
	,oil
	,wind
	,bioenergy
	,other_renewables
	,(coal + gas + nuclear + hydro + solar + oil + wind + bioenergy + other_renewables) AS total_energy
FROM energy_data
WHERE year = (SELECT MAX(year) FROM energy_data)
)

SELECT country
	,ROUND(coal/total_energy*100, 2) AS coal_portion
	,ROUND(gas/total_energy*100, 2) AS gas_portion
	,ROUND(nuclear/total_energy*100, 2) AS nuclear_portion
	,ROUND(hydro/total_energy*100, 2) AS hydro_portion
	,ROUND(solar/total_energy*100, 2) AS solar_portion
	,ROUND(oil/total_energy*100, 2) AS oil_portion
	,ROUND(wind/total_energy*100, 2) AS wind_portion
	,ROUND(bioenergy/total_energy*100, 2) AS bioenergy_portion
	,ROUND(other_renewables/total_energy*100, 2) AS other_renewables_portion
	,ROUND(total_energy, 2)
FROM total_cte
WHERE total_energy > 0
ORDER BY total_energy DESC
;
```
**Fragment of the output:**
![output2](https://github.com/Andrii-Klipailo/Electricity_SQL_Project/blob/main/Output/answer%202.png)

### 3. Which year in the dataset was the most productive for global electricity production from nuclear energy?
```SQL
SELECT year
	,SUM(nuclear) as total_nuclear
FROM energy_data
GROUP BY year
ORDER BY total_nuclear DESC
LIMIT 1
;
```
**Fragment of the output:**
![output3](https://github.com/Andrii-Klipailo/Electricity_SQL_Project/blob/main/Output/answer%203.png)

### 4. Which countries experienced a decline in total electricity production over any period, despite the growth in global production?
```SQL
WITH total_world_energy AS ( -- CTE for calculating total energy production at the global level by years.
SELECT year
	,SUM(coal + gas + nuclear + hydro + solar + oil + wind + bioenergy + other_renewables) AS total_energy
FROM energy_data
GROUP BY year
ORDER BY year
),

world_diff_to_prev_year_cte AS ( -- CTE to calculate the difference in energy production between the current and previous year at the global level.
SELECT year
	,total_energy
	,LAG(total_energy) OVER (order by year) AS prev_year_total
	, total_energy - COALESCE((LAG(total_energy) OVER (order by year)),0) as diff_to_prev_year
FROM total_world_energy
),

country_total_energy AS ( -- CTE to calculate total energy production by country and year.
SELECT country
	 ,year
	,coal + gas + nuclear + hydro + solar + oil + wind + bioenergy + other_renewables AS total_energy
FROM energy_data
ORDER BY year
),

country_diff_to_prev_year_cte AS ( -- CTE to calculate the difference in energy production for a country between the current and previous year.
SELECT country
	,year
	,total_energy
	,LAG(total_energy) OVER (order by year) AS prev_year_total
	, total_energy - COALESCE(LAG(total_energy) OVER (order by year),0) as diff_to_prev_year
FROM country_total_energy
)

SELECT country -- Main query answering our business question.
	,year
	,diff_to_prev_year
FROM country_diff_to_prev_year_cte
WHERE diff_to_prev_year < 0
AND year IN (SELECT year 
			FROM world_diff_to_prev_year_cte
			WHERE diff_to_prev_year > 0)
ORDER BY diff_to_prev_year ASC
;
```
**Fragment of the output:**
![output4](https://github.com/Andrii-Klipailo/Electricity_SQL_Project/blob/main/Output/answer%204.png)

### 5. Which 5 countries have the largest difference between the minimum and maximum electricity production from natural gas over the entire period?
```SQL
SELECT country
	,MAX(gas) - MIN(gas) AS gas_diff_max_min
FROM energy_data
GROUP BY country
ORDER BY gas_diff_max_min DESC
;
```
**Fragment of the output:**
![output5](https://github.com/Andrii-Klipailo/Electricity_SQL_Project/blob/main/Output/answer%205.png)

### 6. Which country was the first to start producing electricity from solar energy, and in which year did it happen?
```SQL
WITH first_year_cte AS (
SELECT country
	,AVG(solar)
	,MIN(year) AS first_year
FROM energy_data
WHERE solar <> 0
GROUP BY 1
)
SELECT * FROM first_year_cte
WHERE first_year = (SELECT MIN(first_year) FROM first_year_cte)
;
```
**Fragment of the output:**
![output6](https://github.com/Andrii-Klipailo/Electricity_SQL_Project/blob/main/Output/answer%206.png)

### 7. Which countries in 2023 produced more electricity from renewable sources than from coal?
```SQL
WITH coal_and_renew AS (
SELECT country 
	,coal
	,year
	,(wind + solar + hydro + bioenergy + other_renewables) AS total_renewables
FROM energy_data
)
SELECT country
	,year
	,coal
	,total_renewables
	,total_renewables - coal AS coal_renew_diff
FROM coal_and_renew
WHERE coal < total_renewables AND year = 2023
ORDER BY coal_renew_diff DESC
```
**Fragment of the output:**
![output7](https://github.com/Andrii-Klipailo/Electricity_SQL_Project/blob/main/Output/answer%207.png)

### 8. Which countries over the last 10 years produced more electricity from renewable sources compared to coal by a factor of 2 or more?
```SQL
SELECT country
	,SUM(coal) AS total_coal
	,SUM(wind + solar + hydro + bioenergy + other_renewables) AS total_renewables
FROM energy_data
WHERE year BETWEEN 2014 AND 2023
GROUP BY country
HAVING SUM(coal) > 0 AND (SUM(wind + solar + hydro + bioenergy + other_renewables)/SUM(coal)) > 2
ORDER BY total_renewables DESC
;
```
**Fragment of the output:**
![output8](https://github.com/Andrii-Klipailo/Electricity_SQL_Project/blob/main/Output/answer%208.png)

### 9. Which type of energy (coal or renewable sources) dominated in each country in terms of production volume over the entire period (from 1965 to 2023)?
```SQL
SELECT country
	,CASE WHEN SUM(coal) > SUM(wind + solar + hydro + bioenergy + other_renewables) THEN 'Coal'
	ELSE 'Renewables' END AS dominant_energy_type
FROM energy_data
GROUP BY country
;
```
**Fragment of the output:**
![output9](https://github.com/Andrii-Klipailo/Electricity_SQL_Project/blob/main/Output/answer%209.png)

### 10. Which countries over the last 10 years have produced more than 60% of their electricity from renewable sources?
```SQL
WITH renew_and_total_cte AS (
SELECT country
	,SUM(coal + gas + nuclear + hydro + solar + oil + wind + bioenergy + other_renewables) AS total_energy
	,SUM(wind + solar + hydro + bioenergy + other_renewables) AS total_renewables
	,CASE WHEN SUM(wind + solar + hydro + bioenergy + other_renewables)/SUM(coal + gas + nuclear + hydro + solar + oil + wind + bioenergy + other_renewables) > 0.6
		THEN 'Above 60%'
		ELSE 'Below 60%' END AS renew_total_proportion
FROM energy_data
WHERE year BETWEEN 2014 AND 2023
GROUP BY country
HAVING SUM(coal + gas + nuclear + hydro + solar + oil + wind + bioenergy + other_renewables) > 0
)

SELECT * FROM renew_and_total_cte
WHERE renew_total_proportion = 'Above 60%'
;
```
**Fragment of the output:**
![output10](https://github.com/Andrii-Klipailo/Electricity_SQL_Project/blob/main/Output/answer%2010.png)

## Findings and Conclusion
- **Growth in Renewables:** Many countries have made significant progress in increasing electricity production from renewable sources in the last decade, with some nations leading the way in wind, solar, and hydroelectric power generation.
- **Energy Distribution:** Renewable energy sources such as wind, solar, and bioenergy have become a major component of global electricity production, contributing more in some countries than traditional sources like coal and oil.
- **Challenges & Opportunities:** While many countries are moving towards cleaner energy, some still rely heavily on fossil fuels, presenting both challenges and opportunities for global energy policy and investment in renewables.

#### Thank you for taking the time to explore my SQL project!







