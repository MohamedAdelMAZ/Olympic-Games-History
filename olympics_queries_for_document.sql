--------------editions---------

--1--How many olympics games have been held?


CREATE VIEW number_of_olympics_games as
select COUNT(distinct edition) as Total_Olympic_Games
from [dbo].[Season$]


go
select * from number_of_olympics_games



--2-the location of each olympic games
go
create view hosting_of_city AS

select edition , city from [dbo].[Season$]
go
select * from hosting_of_city


--3--number of hosting per city--
go
create proc city_count as 
SELECT city, COUNT(*) AS duplicate_count
FROM [dbo].[Season$]
GROUP BY city
ORDER BY duplicate_count DESC;
 go
city_count

--15-Identify which country won the most medals overall in each olympic games.
go 
create proc country_won_the_most_medals as 
 SELECT
    edition,
    country,
    MAX(overall) AS max_overall
FROM (
    SELECT
        edition,
        FIRST_VALUE(country) OVER (PARTITION BY edition ORDER BY (gold + silver + bronze) DESC) AS country,
        (gold + silver + bronze) AS overall
    FROM Medal$
) AS medal_summary 
GROUP BY
   edition,
   country
   order by  edition

   exec country_won_the_most_medals
 

----- countries participation----

--4-Mention the total no of nations who participated in each olympics game? using procedure
go
create proc Total_Participating_Nations1 as 
SELECT edition AS Olympics_Game,year , COUNT(DISTINCT C.country_noc) AS Total_Participating_Nations
FROM Season$ M
INNER JOIN Edition_Details$ C ON M.edition_id = C.edition_id
GROUP BY edition,year
ORDER BY edition;

go
Total_Participating_Nations1
---
--5-number of countries per edition using inline function
---------
go

CREATE FUNCTION dbo.GetParticipatingCountry(@year INT)
RETURNS TABLE
AS
RETURN
(
  SELECT
    edition AS Olympics_Game,
    year,
    COUNT(DISTINCT C.country_noc) AS Total_Participating_Nations
  FROM
    Season$ M
    INNER JOIN Edition_Details$ C ON M.edition_id = C.edition_id
  WHERE
    M.year = @year
  GROUP BY
    edition, year
);
SELECT * FROM dbo.GetParticipatingCountry(2020);

----

--6-Which year saw the highest  no of countries participating in olympics
go
create view year_of_highest_participations1 as
SELECT top 1 e.[edition_id], s.[edition], COUNT(DISTINCT e.[country_noc]) AS 'number of countries'
FROM [dbo].[Edition_Details$] e
INNER JOIN [dbo].[Season$] s ON s.edition_id = e.edition_id
GROUP BY e.[edition_id], s.[edition]
ORDER BY COUNT(DISTINCT e.[country_noc]) DESC;

go
select * from year_of_highest_participations1

------------medals--------------------------------------------

--7-List down total gold, silver and bronze medals won by each country corresponding to each olympic games. using view
 
create or alter view medals_for_each_country as
select edition ,country ,gold , silver ,bronze,total from Medal$ 

select * from medals_for_each_country

------8-List down total gold, silver and bronze medals won by each country corresponding to each olympic games. using inline function
go
CREATE FUNCTION GetMedalTableByYear(@Year INT)
RETURNS TABLE
AS return 
(
  SELECT m.edition, m.country, gold, silver, bronze, total, year
  FROM Medal$ m
  INNER JOIN Season$ s
  ON m.edition_id = s.edition_id
  WHERE s.year = @Year
)
select * from GetMedalTableByYear(1900)

--9-Identify which country won the most gold, most silver and most bronze medals in each olympic games.
go

create proc most_medals_per_country as

SELECT
    edition,
    gold_country,
    silver_country,
    bronze_country,
    MAX(gold) AS max_gold,
    MAX(silver) AS max_silver,
    MAX(bronze) AS max_bronze
FROM (
    SELECT
        edition,
        FIRST_VALUE(country) OVER (PARTITION BY edition ORDER BY gold DESC) AS gold_country,
        FIRST_VALUE(country) OVER (PARTITION BY edition ORDER BY silver DESC) AS silver_country,
        FIRST_VALUE(country) OVER (PARTITION BY edition ORDER BY bronze DESC) AS bronze_country,
        gold,
        silver,
        bronze
    FROM Medal$
) AS medal_summary
GROUP BY
    edition,
    gold_country,
    silver_country,
    bronze_country

  exec most_medals_per_country
  


 
--10-Which countries have never won gold medal but have won silver/bronze medals? using function



CREATE FUNCTION GetCountriesWithNoGoldButOtherMedals()
RETURNS TABLE

As return   (

  SELECT c.Country, SUM(m.gold) AS gold, SUM(m.silver) AS silver, SUM(m.bronze) AS bronze, sum(total) as total
  FROM [dbo].[country$] c
  INNER JOIN [dbo].[Medal$] m ON c.country_noc = m.country_noc
  GROUP BY c.Country
  HAVING SUM(m.gold) = 0 AND (SUM(m.silver) > 0 OR SUM(m.bronze) > 0)
)

select * from GetCountriesWithNoGoldButOtherMedals()


  --11-List down total gold, silver and bronze medals won by each country. using view
  go 

  create view total_medals_per_country as 
   select  country, sum (gold) as total_gold ,sum(silver) as total_silver,sum(bronze) as total_bronze, sum( total)  as total_medal
    FROM Medal$
	group by country

	select * from total_medals_per_country
	order by  total_gold desc
---------------EGYPT in olympics-------------------------------------------------------

--12-Egypt's participation in the Olympics and the medals won
go 
create proc Egypt_medals_in_olympics as 

select [edition_id],[edition],[country],[gold],[silver],[bronze],[total]
from [dbo].[Medal$]
where [country] in ('Egypt','United Arab Republic')
order by total desc

exec Egypt_medals_in_olympics

----
--13-The maximum number of medals won by Egypt in a Olympics
select top 1 [edition_id],[edition],[country],[country_noc],[gold],[silver],[bronze],[total]
from [dbo].[Medal$]
where [country] in ('Egypt','United Arab Republic')
order by total desc
--14-The maximum number of gold medals won by Egypt in a one Olympic game
select top 1 with ties [edition_id],[edition],[country],[country_noc],[gold],[silver],[bronze],[total]
from [dbo].[Medal$]
where [country] in ('Egypt','United Arab Republic')
order by  gold desc


----------------


 
 ----------Athletes-----------

	--14-Fetch the top 10 athletes who have won the most gold medals
	go 
create or alter  view athletes_won_the_most_gold as 
   select a.athlete_id, a.name,d.sport,count(d.medal) as gold_medals,c.Country
   from Olympic_Athlete_Bio$ a inner join Edition_Details$ d 
   on a.athlete_id=d.athlete_id inner join country$ c on c.country_noc=d.country_noc
   where d.medal='gold'
   group by a.athlete_id, a.name,d.sport,c.Country

   select top 10 * from athletes_won_the_most_gold
   order by  gold_medals desc 


   --15-Top 10 Atheltes won Medals
   go
   create proc top_Atheltes_won_Medals as 
   select top 10 a.athlete_id, a.name,d.sport,count(d.medal) as all_medals,c.Country
   from Olympic_Athlete_Bio$ a inner join Edition_Details$ d 
   on a.athlete_id=d.athlete_id inner join country$ c on c.country_noc=d.country_noc
   where d.medal !='NULL'
   group by a.athlete_id, a.name,d.sport,c.Country
   order by count(d.medal) desc 

   exec top_Atheltes_won_Medals
   ----------------------------------triggers-------

--Trigger prevent users from delete from table student 
-- and show massege not allowed for user 
go 
CREATE TRIGGER prevent_from_delete 
ON [dbo].[Medal$]
INSTEAD OF DELETE
AS
  SELECT 'not allowed for user '

DELETE FROM [dbo].[Medal$]
WHERE Medal_Id = 100000

---
-- make table Edition_Details for read only 
go 
CREATE TRIGGER only_for_read
ON [dbo].[Edition_Details$]
INSTEAD OF INSERT , UPDATE , DELETE
AS 
SELECT 'table read only'


SELECT * FROM [dbo].[Edition_Details$]
DELETE FROM [dbo].[Edition_Details$] where edition_id=5
--
