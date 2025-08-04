-- Analysis: Find key signature outliers from bronze data  
-- Valid keys are 0-11 (C through B). This finds any invalid values.

SELECT 
    analysis.songs.key,
    count(*) n_items,
    array_slice(list(metadata.songs.title), 1, 10) as titles
FROM {{ source('bronze_data', 'h5_extract') }}
WHERE analysis.songs.key < 0
OR analysis.songs.key > 11
group by 1
