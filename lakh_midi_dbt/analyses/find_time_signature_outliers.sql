-- Analysis: Find time_signature = 0 from bronze data  
-- These are invalid values that will be converted to NULL in the silver layer

SELECT 
    analysis.songs.time_signature,
    count(*) n_violations,
    list(metadata.songs.title) as titles,
FROM {{ source('bronze_data', 'h5_extract') }}
WHERE analysis.songs.time_signature < 3
OR analysis.songs.time_signature > 7
group by 1
