/*The purpose of this project is to determine the best year of the history of video games 
  in terms of critic_reviews and user_reviews*/

--Import dataset from Kaggle, URL: "https://www.kaggle.com/datasets/holmjason2/videogamedata"

--Select dataset "game_sales_data"
	--DROP table IF EXISTS game_sales_data
SELECT *
FROM game_sales_data gsd;

--Create table "game_sales" 
DROP TABLE IF EXISTS game_sales;
CREATE TABLE game_sales AS (
  SELECT 
	  "Name" AS game, platform, publisher, developer, total_shipped AS games_sold, "Year" AS year
  FROM game_sales_data gsd 
);
SELECT * FROM game_sales gs ;

--Create table "reviews"
DROP TABLE IF EXISTS reviews;
CREATE TABLE reviews AS (
  SELECT 
	  "Name" AS game, critic_score, user_score  
  FROM game_sales_data gsd 
);
SELECT * FROM reviews r;

--The ten best-selling video games
SELECT * 
FROM game_sales gs 
ORDER BY games_sold DESC 
LIMIT 10;

--Missing review scores
  --Count records without user_score
SELECT 
  COUNT(*) AS num_empty
FROM game_sales gs 
LEFT JOIN reviews r 
ON gs.game = r.game
WHERE r.critic_score IS NULL
  AND r.user_score IS NULL;

--Years that video game critics loved
  --Average critic score per year
SELECT 
  gs.year,
  ROUND(AVG(CAST(critic_score AS NUMERIC)), 2) AS avg_critic_score
FROM game_sales gs 
LEFT JOIN reviews r 
ON gs.game = r.game
WHERE critic_score IS NOT NULL  --Ignore Null Values 
GROUP BY gs.year
ORDER BY avg_critic_score DESC
LIMIT 15;

--Average critic score per year
	--Filter for years with more than 4 reviews
SELECT 
  gs.year,
  ROUND(AVG(CAST(critic_score AS NUMERIC)), 2) AS avg_critic_score,
  COUNT(r.critic_score) num_games
FROM game_sales gs 
LEFT JOIN reviews r 
ON gs.game = r.game
WHERE critic_score IS NOT NULL  
GROUP BY gs.YEAR
HAVING COUNT(r.critic_score) > 4
ORDER BY avg_critic_score DESC
LIMIT 15;


--Create table "top_critic_years" from previous query
DROP TABLE IF EXISTS top_critic_years;
CREATE TABLE top_critic_years AS (
  SELECT 
	  gs.year AS year,
	  ROUND(AVG(CAST(critic_score AS NUMERIC)), 2) AS avg_critic_score
  FROM game_sales gs 
  LEFT JOIN reviews r 
  ON gs.game = r.game
  WHERE critic_score IS NOT NULL  
  GROUP BY gs.YEAR
  ORDER BY avg_critic_score DESC
  LIMIT 10
); 	
SELECT * FROM top_critic_years;

--Create table "top_critic_years_more_than_four_games" from previous query
DROP TABLE IF EXISTS top_critic_years_more_than_four_games;
CREATE TABLE top_critic_years_more_than_four_games AS (
  SELECT 
	  gs.year AS year,
	  ROUND(AVG(CAST(critic_score AS NUMERIC)), 2) AS avg_critic_score
  FROM game_sales gs 
  LEFT JOIN reviews r 
  ON gs.game = r.game
  WHERE critic_score IS NOT NULL  
  GROUP BY gs.YEAR
  HAVING COUNT(r.critic_score) > 4 
  ORDER BY avg_critic_score DESC
  LIMIT 15
); 	
SELECT * FROM top_critic_years_more_than_four_games;

--Average user score per year
  --Include only years with more than 4 reviewed games
SELECT 
  gs.year,
  ROUND(AVG(CAST(user_score AS NUMERIC)),2) AS avg_user_score,
  COUNT(gs.game) AS num_games
FROM game_sales gs 
LEFT JOIN reviews r 
ON gs.game = r.game
WHERE r.user_score IS NOT NULL
GROUP BY gs.YEAR
HAVING COUNT(gs.game) > 4
ORDER BY avg_user_score DESC
LIMIT 15;

--Create table "top_user_years_more_than_four_games"
DROP TABLE top_user_years_more_than_four_games;
CREATE TABLE top_user_years_more_than_four_games AS (
	SELECT 
		gs.year,
		COUNT(gs.game) AS num_games,
		ROUND(AVG(CAST(user_score AS NUMERIC)),2) AS avg_user_score
	FROM game_sales gs 
	LEFT JOIN reviews r 
	ON gs.game = r.game
	WHERE r.user_score IS NOT NULL
	GROUP BY gs.year
	HAVING COUNT(gs.game) > 4
	ORDER BY avg_user_score DESC
	LIMIT 15  
);
SELECT * FROM top_user_years_more_than_four_games;

--Select years that appear in both tables (users and critic score)
SELECT tpc.YEAR
FROM top_critic_years_more_than_four_games AS tpc
INNER JOIN top_user_years_more_than_four_games AS tpu
ON tpc.year = tpu.YEAR
LIMIT 3;

--See the number of games sold in each year form the previous query
SELECT 
  year,
  ROUND(CAST(SUM(games_sold) AS numeric),2) AS total_games_sold
FROM game_sales
WHERE year IN (
	SELECT tpc.YEAR
	FROM top_critic_years_more_than_four_games AS tpc
	INNER JOIN top_user_years_more_than_four_games AS tpu
	ON tpc.year = tpu.YEAR
	LIMIT 3)
GROUP BY year
ORDER BY total_games_sold DESC;

