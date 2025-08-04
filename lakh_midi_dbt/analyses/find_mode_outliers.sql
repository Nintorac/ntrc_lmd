-- Analysis: Find mode outliers from bronze data  
-- Valid modes are 0 (minor) and 1 (major). This finds any invalid values.

SELECT 
    analysis.songs.mode,
    count(*) n_items,
    array_slice(list(metadata.songs.title), 1, 10) as titles
FROM {{ source('bronze_data', 'h5_extract') }}
WHERE analysis.songs.mode < 0
OR analysis.songs.mode > 1
group by 1
