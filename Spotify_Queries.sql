DROP TABLE IF EXISTS spotify_top50_world;

CREATE TABLE spotify_top50_world (
    date VARCHAR(20),
    "position" INT,
    song VARCHAR(255),
    artist VARCHAR(255),
    popularity INT,
    duration_ms INT,
    album_type VARCHAR(50),
    total_tracks INT,
    release_date VARCHAR(20),
    is_explicit BOOLEAN,
    album_cover_url TEXT
);

select * from spotify_top50_world
limit 10

-- (1) Top 10 Most Popular Songs
SELECT song,
       artist,
       popularity
FROM spotify_top50_world
ORDER BY popularity DESC
LIMIT 10;

-- (2) Top 5 Artists with the Most Songs in Top 50
SELECT artist,
       COUNT(*) AS total_songs
FROM spotify_top50_world
GROUP BY artist
ORDER BY total_songs DESC
LIMIT 5;

-- (3) Average Popularity by Album Type
SELECT album_type,
       ROUND(AVG(popularity),2) AS avg_popularity
FROM spotify_top50_world
GROUP BY album_type
ORDER BY avg_popularity DESC;

-- (4) Count of Explicit vs Non-Explicit Songs
SELECT is_explicit,
       COUNT(*) AS total_songs
FROM spotify_top50_world
GROUP BY is_explicit;

-- (5) Rank Songs by Popularity Using Window Function
SELECT song,
       artist,
       popularity,
       DENSE_RANK() OVER(ORDER BY popularity DESC) AS popularity_rank
FROM spotify_top50_world;

-- (6) Find Artists Having More Than One Song in Top 50
SELECT artist,
       COUNT(*) AS song_count
FROM spotify_top50_world
GROUP BY artist
HAVING COUNT(*) > 1
ORDER BY song_count DESC;

-- (7) Calculate Average Song Duration by Artist
SELECT artist,
       ROUND(AVG(duration_ms)/1000,2) AS avg_duration_seconds
FROM spotify_top50_world
GROUP BY artist
ORDER BY avg_duration_seconds DESC;

-- (8) Find Songs Longer than Overall Average Duration
SELECT song,
       artist,
       duration_ms
FROM spotify_top50_world
WHERE duration_ms >
      (SELECT AVG(duration_ms)
       FROM spotify_top50_world);

-- (9) Show Cumulative Popularity Across Ranked Songs
SELECT song,
       popularity,
       SUM(popularity)
       OVER(ORDER BY popularity DESC) AS cumulative_popularity
FROM spotify_top50_world;

-- (10) Compare Song Popularity with Artist's Average Popularity
SELECT song,
       artist,
       popularity,
       ROUND(AVG(popularity)
             OVER(PARTITION BY artist),2) AS artist_avg_popularity
FROM spotify_top50_world;

-- (11) Find the Most Popular Song for Each Artist
WITH ranked_songs AS (
    SELECT artist,
           song,
           popularity,
           ROW_NUMBER() OVER(PARTITION BY artist
                             ORDER BY popularity DESC) AS rn
    FROM spotify_top50_world
)

SELECT artist,
       song,
       popularity
FROM ranked_songs
WHERE rn = 1;

-- (12) Categorize Songs Based on Popularity
SELECT song,
       artist,
       popularity,

       CASE
           WHEN popularity >= 95 THEN 'Super Hit'
           WHEN popularity >= 85 THEN 'Hit'
           WHEN popularity >= 75 THEN 'Moderate'
           ELSE 'Average'
       END AS popularity_category

FROM spotify_top50_world
ORDER BY popularity DESC;

-- (13) Find Artists Whose Average Popularity is Greater than Overall Average
SELECT artist,
       ROUND(AVG(popularity),2) AS avg_popularity
FROM spotify_top50_world
GROUP BY artist

HAVING AVG(popularity) >
       (SELECT AVG(popularity)
        FROM spotify_top50_world)

ORDER BY avg_popularity DESC;

-- (14) Calculate Percentage Contribution of Each Artist
SELECT artist,
       COUNT(*) AS total_songs,

       ROUND(
           COUNT(*) * 100.0 /
           SUM(COUNT(*)) OVER (),
           2
       ) AS contribution_percentage

FROM spotify_top50_world
GROUP BY artist
ORDER BY contribution_percentage DESC;

-- (15) Identify Songs Performing Better than the Average of Their Album Type
WITH album_avg AS (
    SELECT album_type,
           AVG(popularity) AS avg_popularity
    FROM spotify_top50_world
    GROUP BY album_type
)

SELECT s.song,
       s.artist,
       s.album_type,
       s.popularity,
       ROUND(a.avg_popularity,2) AS album_avg_popularity

FROM spotify_top50_world s
JOIN album_avg a
ON s.album_type = a.album_type

WHERE s.popularity > a.avg_popularity

ORDER BY s.popularity DESC;