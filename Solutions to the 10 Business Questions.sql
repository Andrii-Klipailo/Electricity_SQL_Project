
-- Electricity Data Analysis using SQL.
-- Solution of 10 Business Questions.


-- 1. Which countries have had the highest growth in electricity production from renewable sources over the last 10 years?

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



-- 2. What is the share of each type of energy source in total electricity production in each country for the last year in the dataset?

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



-- 3. Which year in the dataset was the most productive for global electricity production from nuclear energy?

SELECT year
	,SUM(nuclear) as total_nuclear
FROM energy_data
GROUP BY year
ORDER BY total_nuclear DESC
LIMIT 1
;



-- 4. Which countries experienced a decline in total electricity production over any period, despite the growth in global production?

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



-- 5. Which 5 countries have the largest difference between the minimum and maximum electricity production from natural gas over the entire period?

SELECT country
	,MAX(gas) - MIN(gas) AS gas_diff_max_min
FROM energy_data
GROUP BY country
ORDER BY gas_diff_max_min DESC
;



-- 6. Which country was the first to start producing electricity from solar energy, and in which year did it happen?

WITH first_year_cte AS (
SELECT country
	,MIN(year) AS first_year
FROM energy_data
WHERE solar <> 0
GROUP BY 1
)
SELECT * FROM first_year_cte
WHERE first_year = (SELECT MIN(first_year) FROM first_year_cte)
;



-- 7. Which countries in 2023 produced more electricity from renewable sources than from coal?

SELECT country
FROM	(SELECT country 
			,coal
			,year
			,(wind + solar + hydro + bioenergy + other_renewables) AS total_renewables
		FROM energy_data) AS coal_and_renew
WHERE coal < total_renewables AND year = 2023
;



-- 8. Which countries over the last 10 years produced more electricity from renewable sources compared to coal by a factor of 2 or more?

SELECT country
	,SUM(coal) AS total_coal
	,SUM(wind + solar + hydro + bioenergy + other_renewables) AS total_renewables
FROM energy_data
WHERE year BETWEEN 2014 AND 2023
GROUP BY country
HAVING SUM(coal) > 0 AND (SUM(wind + solar + hydro + bioenergy + other_renewables)/SUM(coal)) > 2
;



-- 9. Which type of energy (coal or renewable sources) dominated in each country in terms of production volume over the entire period (from 1965 to 2023)?

SELECT country
	,CASE WHEN SUM(coal) > SUM(wind + solar + hydro + bioenergy + other_renewables) THEN 'Coal'
	ELSE 'Renewables' END AS dominant_energy_type
FROM energy_data
GROUP BY country
;



-- 10. Which countries over the last 10 years have produced more than 60% of their electricity from renewable sources?

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








