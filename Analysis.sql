-- QUEST:
/* 
A client is a real estate co-investment company. 
They provide funds to purchase a home in exchange for an equity stake in the property. 
When you sell, they share in the profits or loss. 
The client is currently operating in all major California metro areas and is looking to expand to a new market. 
Which metro area should they consider and why?
*/

-- This query provides the average home value trends over different months for each region.
-- Slide 8: TOP 15 most expensives
WITH tbl_avg_home AS (
    SELECT
        metro,
        ROUND(AVG(VALUE),0) AS avg_home_value
    FROM
        testing_zillow.zillow.home_values
    WHERE
         date_part('year', try_to_date(month, 'yyyy-mm')) = 2020 AND state = 'CA'
    GROUP BY
        metro
    ORDER BY
        avg_home_value DESC
    LIMIT 15
)

SELECT *,
    CASE
        WHEN avg_home_value >= 1000000000 THEN CONCAT(TO_VARCHAR(ROUND(avg_home_value / 1000000000, 2)), 'B')
        WHEN avg_home_value >= 1000000 THEN CONCAT(TO_VARCHAR(ROUND(avg_home_value / 1000000, 2)), 'M')
        WHEN avg_home_value >= 100000 THEN CONCAT(TO_VARCHAR(ROUND(avg_home_value / 100000, 2)), 'K')
        ELSE TO_VARCHAR(ROUND(avg_home_value, 2))
    END AS formatted_number
FROM tbl_avg_home;

-- Slide 9: TOP 15 cheapest metro
SELECT
    metro,
    ROUND(AVG(VALUE),0) AS avg_home_value
FROM
    testing_zillow.zillow.home_values
WHERE
     date_part('year', try_to_date(month, 'yyyy-mm')) = 2020 AND state = 'CA'
GROUP BY
    metro
ORDER BY
    avg_home_value ASC
LIMIT 15;

-- Let's look at fastest growing metro, Fastest Growing Metros
-- Slide 10: Top 15 Fastest Growing Metros (2015-2020)

WITH home_values_year AS (
    SELECT *,
    date_part('year', try_to_date(month, 'yyyy-mm')) as year
    FROM home_values
),
metro_growth AS (
    SELECT
        METRO,
        AVG(VALUE) AS avg_value,
        MAX(CASE WHEN year = 2015 THEN VALUE END) AS value_2015,
        MAX(CASE WHEN year = 2020 THEN VALUE END) AS value_2019,
        (value_2019 - value_2015) / value_2015 * 100 AS growth_percentage
    FROM home_values_year
    WHERE year IN (2015, 2020) and State = 'CA'
    GROUP BY METRO
),
aggresive_metros_growth AS (
    SELECT METRO, ROUND(growth_percentage, 0) AS growth_percentage
    FROM metro_growth
    ORDER BY growth_percentage DESC
    LIMIT 15
)

SELECT * FROM aggresive_metros_growth;

SELECT
    AVG(value) as avg_home_value,
    date_part('year', try_to_date(month, 'yyyy-mm')) as year,
    home_values.metro
FROM testing_zillow.zillow.home_values
    INNER JOIN aggresive_metros_growth ON aggresive_metros_growth.metro = home_values.metro
WHERE state = 'CA' and year >= 2015
GROUP BY 2,3
ORDER BY 3,2;

-- Percent growth from 2015-2020

WITH home_values_year AS (
    SELECT *,
    date_part('year', try_to_date(month, 'yyyy-mm')) as year
    FROM home_values
),
metro_growth AS (
    SELECT
        METRO,
        AVG(VALUE) AS avg_value,
        MAX(CASE WHEN year = 2015 THEN VALUE END) AS value_2015,
        MAX(CASE WHEN year = 2020 THEN VALUE END) AS value_2019,
        (value_2019 - value_2015) / value_2015 * 100 AS growth_percentage
    FROM home_values_year
    WHERE year IN (2015, 2020) and State = 'CA'
    GROUP BY METRO
),
aggresive_metros_growth AS (
    SELECT METRO, growth_percentage
    FROM metro_growth
    ORDER BY growth_percentage DESC
    LIMIT 5
),
tbl_all AS (
    SELECT
        AVG(value) as avg_home_value,
        date_part('year', try_to_date(month, 'yyyy-mm')) as year,
        home_values.metro
    FROM testing_zillow.zillow.home_values
        INNER JOIN aggresive_metros_growth ON aggresive_metros_growth.metro = home_values.metro
    WHERE state = 'CA' and year >= 2015
    GROUP BY 2,3
)
SELECT metro, year, avg_home_value,
FIRST_VALUE(avg_home_value) OVER (PARTITION BY metro ORDER BY year ASC) as prev_year_value,
(avg_home_value - prev_year_value) / prev_year_value * 100 as percent_growth
FROM tbl_all
ORDER BY 1, 2;

WITH metro_growth AS (
    SELECT
        METRO,
        AVG(VALUE) AS avg_value,
        MAX(CASE WHEN MONTH = '2018-01' THEN VALUE END) AS value_2018,
        MAX(CASE WHEN MONTH = '2019-12' THEN VALUE END) AS value_2019,
        (value_2019 - value_2018) / value_2018 * 100 AS growth_percentage
    FROM testing_zillow.zillow.home_values
    WHERE MONTH IN ('2018-01', '2019-12') and State = 'CA'
    GROUP BY METRO
)
SELECT METRO, growth_percentage
FROM metro_growth
ORDER BY growth_percentage DESC;

-- SLIDE 10: Top 15 metros with the most zip codes

SELECT
    metro,
    COUNT(DISTINCT regionname) AS total_zip_code
FROM
    testing_zillow.zillow.home_values
WHERE
    metro IS NOT NULL and state = 'CA'
GROUP BY
    metro
ORDER BY
    total_zip_code DESC
LIMIT 15;

-- Which metro in the US west coast (CA) had the largest percent difference between the average and median home values in March 2020?
SELECT
    metro,
    AVG(value) AS avg_value,
    MEDIAN(value) AS median_value,
    (avg_value - median_value) / avg_value * 100 AS percent_difference
FROM
    testing_zillow.zillow.home_values
WHERE
    state IN ('CA')
    AND month = '2020-03'
GROUP BY
    metro;

--SLIDE 11: Metros with Higher Avg. than Median (Mar 2020)

WITH median_home_value_per_metro AS (
    SELECT MEDIAN(value) AS median_value, metro
    
    FROM testing_zillow.zillow.home_values
    WHERE state IN ('CA')
        AND date_part('year', try_to_date(month, 'yyyy-mm')) = 2020
    GROUP BY metro
),
-- Calculate the average home value and the total number of distinct zip codes per metro
-- for the specified states in March 2020, ordered by the number of zip codes in descending order.
avg_home_per_metro AS (
    SELECT
        metro,
        COUNT(DISTINCT regionname) AS total_zip_code,
        AVG(value) AS average_value
    FROM
        testing_zillow.zillow.home_values
    WHERE
        state IN ('CA')
        AND  date_part('year', try_to_date(month, 'yyyy-mm')) = 2020
    GROUP BY
        metro
    ORDER BY
        total_zip_code DESC
)
-- Retrieve the metro with the highest number of distinct zip codes where the average
-- home value is greater than the calculated median home value for the specified metro.
SELECT
    avg_home_per_metro.metro, 
    ROUND(avg_home_per_metro.average_value - median_value, 0) as difference,
    total_zip_code
FROM
    avg_home_per_metro
JOIN
    median_home_value_per_metro ON avg_home_per_metro.metro = median_home_value_per_metro.metro
WHERE
    avg_home_per_metro.average_value > median_value
ORDER BY
    difference DESC--, total_zip_code DESC
LIMIT 10;


---Slide 12: Number of Homes for Sale per 1000 People

WITH metro_regionname AS (
    SELECT DISTINCT metro, regionname
        FROM home_values
    WHERE month = '2020-03'
        AND state = 'CA'
),
home_for_sale AS (
    SELECT
        metro,
        SUM(value) AS total_homes_for_sale
    FROM
        testing_zillow.zillow.for_sale_inventory 
        INNER JOIN metro_regionname ON metro_regionname.regionname = for_sale_inventory.regionname
    WHERE
        month = '2020-03' AND statename = 'CA'
    GROUP BY
        metro
),
-- CTE calculates the total population for each state based on the 2010 census.
population_2010 AS (
    SELECT
        metro,
        SUM(pop_2010) AS total_population_2010
    FROM
        testing_zillow.census.census_demographics
    INNER JOIN metro_regionname ON metro_regionname.regionname =  lpad(zcta, 5, '0')
    WHERE
        state = 'CA'
    GROUP BY
        metro
)
-- Calculate the homes for sale per 1000 people for each state. 
-- It then orders the result in descending order of homes per 1000 and limits the result to the top state.

SELECT
    hf.metro,
   -- hf.total_homes_for_sale,
    -- p2010.total_population_2010,
    ROUND((hf.total_homes_for_sale / p2010.total_population_2010 * 1000),0) AS homes_per_1000
FROM
    home_for_sale hf
JOIN
    population_2010 p2010 ON hf.metro = p2010.metro
ORDER BY
    homes_per_1000 DESC
LIMIT 1;

--Slide_13: Top Metro with Highest Projected Population Growth (10 Years)
--Whats the population growth trends
WITH metro_regionname AS (
    SELECT DISTINCT metro, regionname
        FROM home_values
    WHERE month = '2020-03'
        AND state = 'CA'
),
-- CTE calculates the total population for each state based on the 2010 census.
population_growth AS (
    SELECT
        metro,
        SUM(FIVE_YEAR_PROJ - POP_2010) AS projected_growth,
        SUM(TEN_YEAR_PROJ - POP_2010) AS projected_growth_10_years
    FROM
        testing_zillow.census.census_demographics
    INNER JOIN metro_regionname ON metro_regionname.regionname =  lpad(zcta, 5, '0')
    WHERE
        state = 'CA'
    GROUP BY
        metro
)

-- Identify the metro with the highest population growth rate
SELECT
    metro,
    projected_growth_10_years
FROM
    population_growth
ORDER BY
    projected_growth_10_years DESC
LIMIT 20