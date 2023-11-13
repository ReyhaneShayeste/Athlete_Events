

Select *
From Athlete_Events.dbo.athlete_events$

Select * 
From Athlete_Events.dbo.noc_regions$

----------------------------------------------------------------------------
---Identify the sport which was played in all summer olympics.

Drop table If EXISTs #t1
Select count(Distinct Games) as Total_summer_games
INTO #t1
From Athlete_Events.dbo.athlete_events$
Where Season = 'Summer'

Drop table If EXISTs #t2
Select Distinct Sport, Games
INTO #t2
From Athlete_Events.dbo.athlete_events$
Where Season = 'Summer'
Order by Games


Drop table If EXISTs #t3
Select Sport, COUNT(Games) as no_of_games
INTO #t3
From #t2
group by Sport

Select *
From #t3

Select *
From #t3
Join #t1 on #t1.Total_summer_games = #t3.no_of_games;

---------------------------------------------------------------------------
--Fetch the top 5 athletes who have won the most gold medals.


Drop table If EXISTs #t4
Select Name, Count(1) as Total_Medals
INTO #t4
From Athlete_Events.dbo.athlete_events$
Where Medal = 'Gold'
Group by Name
order by count(1) desc;


Drop table If EXISTs #t5
Select *, DENSE_RANK() over (order by Total_Medals desc) as rnk
INTO #t5
From #t4


Select *
From #t5
Where rnk <=5



----------------------------------------------------------------
---List down total gold, silver and bronze medals won by each country.

Select nr.region as Country, Medal, COUNT(1) as total_medals
From Athlete_Events.dbo.athlete_events$ oh
Join Athlete_Events.dbo.noc_regions$ nr 
        on oh.NOC = nr.NOC
Where Medal <> 'NA'
group by nr.region, Medal
order by nr.region, Medal;


Select Country
, coalesce(Gold, 0) as Gold
, coalesce(Silver, 0) as Silver
, coalesce(Bronze, 0) as Bronze
From ( Select nr.region as Country, Medal, COUNT(1) as total_medals
	From Athlete_Events.dbo.athlete_events$ oh
	Join Athlete_Events.dbo.noc_regions$ nr 
			on oh.NOC = nr.NOC
	Where Medal <> 'NA'
	group by nr.region, Medal
	--order by nr.region, Medal
)As Source 
PIVOT (
	SUM(total_medals) FOR Medal IN ([Gold], [Silver], [Bronze])
	) AS PivotTable 
	Order by Gold desc, Silver desc, Bronze desc;


-----------------------------------------------------------------------------------------------------------
-- Identify which country won the most gold, most silver and most bronze medals in each olympic games.


Select SUBSTRING (Gemes_Country,1 , CHARINDEX ('-' , Gemes_Country + '-') -1 ) as Games
	 , SUBSTRING (Gemes_Country, CHARINDEX ('-' , Gemes_Country) +1, LEN(Gemes_Country) ) as Country
, coalesce(Gold, 0) as Gold
, coalesce(Silver, 0) as Silver
, coalesce(Bronze, 0) as Bronze
INTO #temptable
From ( Select (Games + ' - '+ nr.region) as Gemes_Country, Medal, COUNT(1) as total_medals
	From Athlete_Events.dbo.athlete_events$ oh
	Join Athlete_Events.dbo.noc_regions$ nr 
			on oh.NOC = nr.NOC
	Where Medal <> 'NA'
	group by nr.region, Medal,Games
	--order by nr.region, Medal
)As Source 
PIVOT (
	SUM(total_medals) FOR Medal IN ([Gold], [Silver], [Bronze])
	) AS PivotTable 
	Order by Gold desc, Silver desc, Bronze desc;



Select Distinct Games
,CONCAT (first_value(Country) over (partition by Games order by Gold desc) 
	, ' - '
	, FIRST_VALUE (Gold) over (partition by Games order by Gold desc)) as Gold
, CONCAT (first_value(Country) over (partition by Games order by Silver desc) 
	, ' - '
	, FIRST_VALUE (Silver) over (partition by Games order by Silver desc)) as Silver
,CONCAT (first_value(Country) over (partition by Games order by Bronze desc) 
	, ' - '
	, FIRST_VALUE (Bronze) over (partition by Games order by Bronze desc)) as Bronze
From #temptable 


----------------------------------------------------------------------------------
--Which nation has participated in all of the olympic games


select count(distinct Games) as total_games
			INTO tot_games
              from Athlete_Events.dbo.athlete_events$
         
select Games, nr.region as country
			  INTO Countries
              from Athlete_Events.dbo.athlete_events$ oh
              join Athlete_Events.dbo.noc_regions$ nr ON nr.noc=oh.noc
              group by Games, nr.region


select country, count(1) as total_participated_games
			INTO countries_participated 
              from Countries
              group by country

      select cp.*
      from countries_participated cp
      join tot_games tg on tg.total_games = cp.total_participated_games
      order by 1;