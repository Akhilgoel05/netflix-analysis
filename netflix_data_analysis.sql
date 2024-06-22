-- Dataset loaded with use of python

Select * from df_netflix_raw

-- Checking title containing values like '?'
Select * from df_netflix_raw where title like '%?%'

-- Since this dataset contains foreign character which is not readable, hence droping this table
drop table df_netflix_raw

-- creating new table structure
create table netflix_raw
(
	[show_id] [varchar](10) primary key,
	[type] [varchar](10) NULL,
	[title] [nvarchar](200) NULL,
	[director] [varchar](250) NULL,
	[cast] [varchar](1000) NULL,
	[country] [varchar](150) NULL,
	[date_added] [varchar](20) NULL,
	[release_year] [int] NULL,
	[rating] [varchar](10) NULL,
	[duration] [varchar](10) NULL,
	[listed_in] [varchar](100) NULL,
	[description] [varchar](500) NULL
)

Select * from netfix_raw

-- checking show which contains foreign characters
Select * from netflix_raw where show_id = 's5023'

-- Removing duplicates

Select show_id, Count(*)
from netflix_raw
group by show_id
having count(*)>1	-- Show Ids are unique

select *
from netflix_raw
where CONCAT(title,type) in (
Select concat(title, type)
from netflix_raw
group by title,type
having count(*)>1
)
order by title

-- Deleting duplicates having same title and type
delete from netflix_raw 
where show_id in (
			Select max(show_id)
			from netfix_raw
			group by title,type
			having count(*)>1
)


-- fixing null values of column duration
Select *
from netflix_raw
where duration is null

update netflix_raw
set duration = rating
where duration is null

-- Assigning null values to rating which contains duration value
update netflix_raw
set rating = null
where rating like '%min%'



-- Creating new tables for columns containing multiple values
Select show_id, trim(value) as director
into netflix_director
from netflix_raw
cross apply string_split(director, ',')

-- creating table for cast members
Select show_id, trim(value) as cast
into netflix_cast
from netflix_raw
cross apply string_split(cast, ',')

-- creating table for country
Select show_id, trim(value) as country
into netflix_country
from netflix_raw
cross apply string_split(country, ',')

-- creating table for genre
Select show_id, trim(value) as genre
into netflix_genre
from netflix_raw
cross apply string_split(listed_in, ',')

-- Filling some null values in country 

select *
from netflix_raw
where country is null -- showing 831 records

Select *
from netflix_raw
where director = 'Ahishor Solomon'

Select * from netflix_country
Select * from netflix_raw
Select * from netflix_director

insert into netflix_country
Select show_id, mapping.country
from netflix_raw raw
JOIN (
	select director, country
	from netflix_country c
	JOIN netflix_director dir
		ON dir.show_id = c.show_id
	group by director, country
) mapping
	ON mapping.director = raw.director
where raw.country is Null


-- Accessing required columns from netflix_raw table to loading into new netflix table
Select show_id, type,title, cast(date_added as date) as date_added, release_year, rating, duration, description
into netflix
from netflix_raw


--netflix data analysis
select * from netflix_raw
select * from netflix_director
select * from netflix_cast
select * from netflix_country
select * from netflix_genre

/*1  for each director count the no of movies and tv shows created by them in separate columns 
for directors who have created tv shows and movies both */

Select dir director, Movie_Count, Show_Count
from
(
	Select dir.director dir, Sum(case when type='Movie' then 1 end) as Movie_Count, 
						 Sum(case when type='TV Show' then 1 end) as Show_Count
	from netflix n
	JOIN netflix_director dir
		ON n.show_id = dir.show_id
	--where type in ('Movie' , 'TV Show')
	group by dir.director
)x
where Movie_Count>0 and Show_Count>0



--2 which country has highest number of comedy movies

Select top 1 coun.country, count(*) as cnt
from netflix n
JOIN netflix_genre g
	ON n.show_id = g.show_id
JOIN netflix_country coun
	ON g.show_id = coun.show_id
where g.genre like 'Comedies' and n.type='Movie'
group by coun.country
order by cnt DESC


--3 for each year (as per date added to netflix), which director has maximum number of movies released

Select * from netflix
Select * from netflix_director

with cte as
(
	Select year(date_added) yr, dir.director dir_name, count(*) as cnt, Row_number() over(partition by year(date_added) order by count(*) DESC) as rn
	from netflix n
	JOIN netflix_director dir
		ON n.show_id = dir.show_id
	where n.type='Movie'
	group by year(date_added), dir.director 
	
)
Select yr year, dir_name, cnt no_of_movies
from cte
where rn=1
order by yr, cnt DESC, dir_name


--4 Each director find year with max movies
Select * from netflix_raw
Select * from netflix_director

with cte as
(
	Select dir.director dir_name, YEAR(date_added) year, Count(*) cnt, ROW_NUMBER() over(partition by dir.director order by Count(*) DESC, YEAR(date_added) DESC) as rn
	from netflix n
	join netflix_director dir
		ON n.show_id = dir.show_id
	where n.type = 'Movie'
	Group by dir.director, YEAR(date_added)
)
Select dir_name, year, cnt movies_count
from cte
where rn=1


--4 what is average duration of movies in each genre
Select * from netflix_raw
Select * from netflix_genre

Select g.genre, AVG(cast(replace(duration,' min','') as int)) as avg_duration_genre
from netflix n
join netflix_genre g
	ON n.show_id = g.show_id
where n.type = 'Movie'
group by g.genre
order by g.genre


--5  find the list of directors who have created horror and comedy movies both.
-- display director names along with number of comedy and horror movies directed by them

select * from netflix_director
select * from netflix_genre
select * from netflix

select distinct genre from netflix_genre -- We have to select only ('Comedies', 'Horror Movies') category

Select 
		dir.director, 
		count(case when g.genre='Comedies' then 1 end) as count_comedies,
		count(case when g.genre='Horror Movies' then 1 end) as count_horror
from netflix n
JOIN netflix_genre g
	ON n.show_id = g.show_id
JOIN netflix_director dir
	ON dir.show_id = n.show_id
where n.type='Movie' and g.genre in ('Comedies', 'Horror Movies')
group by dir.director
having count(distinct g.genre) = 2


