
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





