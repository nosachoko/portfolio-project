/* data analytics portfolio project 
*/
use covid19;
select * from coviddeaths;
-- looking at the toatl cases vs total deaths
-- show likelihood of dying if you contract covid in your countyr

select location, date,  total_cases, total_deaths, 
(total_deaths/total_cases)*100 as deathpercentage
from coviddeaths
where location like '%states%'
order by 1,2;


--  looking at total_case vs total_deaths
--  show what percentage of population have gotten covid
select location, date,  population, total_cases,
(total_cases/population)*100 as percentagepopulationaffected 
from coviddeaths
where location like '%states%'
order by 1,2;

-- looking at countries with highest infection rate compared to pulation
select location, population, max(total_cases) as highestinfection,
max(total_cases/population)*100 as percentperpopulationinfected
from coviddeaths
where location like '%states%'
group by location, population
order by percentperpopulationinfected desc;

-- showing countries with highest death count per population 
select location, max(cast(total_deaths as signed)) as highestdeathperpopulation
from coviddeaths
group by location
order by  highestdeathperpopulation desc;

-- let's break things down by continen
select continent, max(cast(total_deaths as signed)) as totaldeathcontinent
from coviddeaths
group by continent
order by  totaldeathcontinent desc;

-- showing the continent with the highest death count per population
select continent, max(cast(total_deaths as signed)) as totaldeathcount
from coviddeaths
group by continent
order by totaldeathcount desc;

-- new global total numbers of all total new, death cases and corresponding percentage  
select date,  sum(new_cases) as total_cases, sum(cast(new_deaths as signed)) as total_deaths, 
sum(cast(new_deaths as signed))/sum(new_cases)*100 as deathpercent
from coviddeaths
where continent is not null
group by date
order by 1,2;

/*
Using our other covid19 vaccination table and joining it together 
with our coviddeaths table
*/
select * 
from covidvaccination vac
inner join coviddeaths dea
	on vac.location = dea.location
    and vac.date = dea.date;
    
-- looking at total population vs population
/* 
i added trim to the not null because 'not null' only 
remove blank field in your continent column  but can't
remove space character ('  '). so i use trim to remove spaces
before filtering
*/
select dea.continent, dea.location, dea.date, dea.population,
vac.new_vaccinations
from covidvaccination vac
inner join coviddeaths dea
	on vac.location = dea.location
    and vac.date = dea.date
where dea.continent is not null
AND TRIM(dea.continent) <> ''
order by 1,2,3;

/*
i don't want any blank field in my data that why i added AND vac.new_vaccinations IS NOT NULL
  AND TRIM(vac.new_vaccinations) <> '' to remove blank and 
  extra spaces from your new_vaccinations column
  */
SELECT dea.continent, dea.location, dea.date, dea.population,
       vac.new_vaccinations
       FROM covidvaccination vac
JOIN coviddeaths dea
    ON vac.location = dea.location
    AND vac.date = dea.date
WHERE dea.continent IS NOT NULL
  AND TRIM(dea.continent) <> ''
  AND vac.new_vaccinations IS NOT NULL
  AND TRIM(vac.new_vaccinations) <> ''
ORDER BY 1,2,3;

-- -- using 'partition by' to treat each  'new_vaccination' and 'loaction' column as a separate group and start counting again inside each one
SELECT dea.continent, dea.location, dea.date, dea.population,
       vac.new_vaccinations, sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
FROM covidvaccination vac
JOIN coviddeaths dea
    ON vac.location = dea.location
    AND vac.date = dea.date
WHERE dea.continent IS NOT NULL
  AND TRIM(dea.continent) <> ''
ORDER BY 1,2,3;

-- i want to calculate for percentage of total new_vaccination and the given population of each region 
-- i want to use a cte table because i can't use an alise twice
-- - USE CTE
with popvsvac (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population,
       vac.new_vaccinations, sum(vac.new_vaccinations) over (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
FROM covidvaccination vac
JOIN coviddeaths dea
    ON vac.location = dea.location
    AND vac.date = dea.date
WHERE dea.continent IS NOT NULL
  AND TRIM(dea.continent) <> ''
ORDER BY 1,2,3
)
select *, (rollingpeoplevaccinated/population)*100
from popvsvac;
drop table percentpopulationvaccinated;

-- using Temp table to get similar result
-- drop table if exists  percentpopulationvaccinated;
create table percentpopulationvaccinated
(
continent varchar(255),
location varchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rollingpeoplevaccinated numeric
);
-- my date column is in string i have to convert it to the normal date format [STR_TO_DATE(dea.date, '%m/%d/%Y') AS date]
-- my new_vaccination and population column also have some empty blank space so am using 'nullif' to remove the empty space
-- some of our data have some characters between number that are not numeric values so we have to convert it using cast
insert into percentpopulationvaccinated
SELECT dea.continent, dea.location, STR_TO_DATE(dea.date, '%m/%d/%Y'),CAST(REPLACE(NULLIF(dea.population, ''), ',', '') AS DECIMAL(20,0)) AS population,     -- cleans commas & blanks
    CAST(REPLACE(NULLIF(vac.new_vaccinations, ''), ',', '') AS DECIMAL(20,0)) AS new_vaccinations, -- cleans commas & blanks
    SUM(CAST(REPLACE(NULLIF(vac.new_vaccinations, ''), ',', '') AS DECIMAL(20,0))) over (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
FROM covidvaccination vac
JOIN coviddeaths dea
    ON vac.location = dea.location
    AND vac.date = dea.date
WHERE dea.continent IS NOT NULL
  AND TRIM(dea.continent) <> ''
ORDER BY 2,3;

select *, (rollingpeoplevaccinated/population)*100
from percentpopulationvaccinated;


-- creating view to store data for later visualization

create view ppercentpopulationvaccinated as 
SELECT dea.continent, dea.location, STR_TO_DATE(dea.date, '%m/%d/%Y') as date, CAST(REPLACE(NULLIF(dea.population, ''), ',', '') AS DECIMAL(20,0)) AS population,     -- cleans commas & blanks
    CAST(REPLACE(NULLIF(vac.new_vaccinations, ''), ',', '') AS DECIMAL(20,0)) AS new_vaccinations, -- cleans commas & blanks
    SUM(CAST(REPLACE(NULLIF(vac.new_vaccinations, ''), ',', '') AS DECIMAL(20,0))) over (partition by dea.location order by dea.location, dea.date) as rollingpeoplevaccinated
FROM covidvaccination vac
JOIN coviddeaths dea
    ON vac.location = dea.location
    AND vac.date = dea.date
WHERE dea.continent IS NOT NULL
  AND TRIM(dea.continent) <> ''
ORDER BY 2,3;


/* 
you can see your view closely after table under 
the database you are working with and can open it by clicking onit
from the left side of your workbench
*/




