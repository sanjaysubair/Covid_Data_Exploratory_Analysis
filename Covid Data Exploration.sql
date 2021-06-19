select * 
from Portfolio_Project.dbo.CovidDeaths
order by 3,4

--select * 
--from Portfolio_Project..covidvaccinations
--order by 3,4

--Select Data that we are going to be using

select location, date, total_cases, new_cases, total_deaths,population
from Portfolio_Project.dbo.CovidDeaths
order by 1,2

--Looking at Total Cases vs Total Deaths
--Shows the likelyhood of dying if you contract Covid in a country

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as percentage_deaths
from Portfolio_Project.dbo.CovidDeaths
where location like ''
order by 1,2

--Running Total Cases per Coutry till date

select location, date, sum(total_cases) over (partition by location order by date) as cumulative_case
from Portfolio_Project.dbo.CovidDeaths
where location = ''

--Total Cases per Coutry till date

select location, sum(total_cases) as total
from Portfolio_Project.dbo.CovidDeaths
group by location
order by location

--Total cases per country per year

select location, date, DATEPART(YYYY, date) as 'Years', total_cases
from Portfolio_Project..CovidDeaths
where DATEPART(YYYY, date) = 2020 and location like 'India'
order by 1,2

--Total Cases vs Population
--Shows the infection rate of Covid over time

select location, date, total_cases, population, (total_cases/population)*100 as 'Infectio rate'
from Portfolio_Project.dbo.CovidDeaths
where location like 'India'
order by 1,2

-- Max infection rate recorded by a country
--Shows the highest infection rate recorde by a country

select location, population,MAX(total_cases) as highest_infected_count, MAX((total_cases/population)*100)as 'highest infection rate'
from Portfolio_Project.dbo.CovidDeaths
group by  location, population
having location like 'India'
order by 'highest infection rate' desc

--Death percentage per country

select location,sum(total_cases) as Cases, sum(cast(total_deaths as int)) as deaths ,sum(cast(total_deaths as int))/sum(total_cases)*100 as Death_percentage --MAX(total_deaths/total_cases*100) as Death_percentage
from Portfolio_Project.dbo.CovidDeaths
where location like 'India'
group by location
order by Death_percentage desc
--Countires with  highest deaths

select location, SUM(coalesce(new_deaths,0)) as TotalDeaths,MAX(cast(total_deaths as int)) as Highest_Death_Count
from Portfolio_Project..CovidDeaths
where continent is not NULL
group by location
order by Highest_Death_Count desc

--Deaths in various Conitinents

--Showing Continent with highest death counts

select continent, SUM(coalesce(new_deaths,0)) as TotalDeaths,MAX(cast(total_deaths as int)) as Highest_Death_Count
from Portfolio_Project..CovidDeaths
where continent is not NULL
group by continent
order by Highest_Death_Count desc

--Global Numbers
--Global cases , deaths over the time period

select date, sum(new_cases) as Total_cases, sum(cast(new_deaths as int)) as Total_deaths
from Portfolio_Project..CovidDeaths
--where location like ''
where continent is not null
group by date
order by 1 asc

--Global death percenetage over the time period

select date, sum(new_cases) as Total_cases, sum(cast(new_deaths as int)) as Total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as Death_percentage
from Portfolio_Project..CovidDeaths
--where location like ''
where continent is not null
group by date
order by 1 asc

-- Death percenatge for entire world

select sum(new_cases) as Total_cases, sum(cast(new_deaths as int)) as Total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as Death_percentage
from Portfolio_Project..CovidDeaths
--where location like ''
where continent is not null
--group by date
order by 1 asc

--Total people vaccinated

select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations
,sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as running_total
--(running_total/dea.population)*100 will not work. Need to use a CTE or temp table
from Portfolio_Project..CovidDeaths dea
inner join Portfolio_Project..CovidVaccinations vac	
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and dea.location like '%albania'
order by 2,3

--using CTE

with Running_total (continent, location, date,population,new_vaccinations,rolling_total)
as
(
select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations
,sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling_total
from Portfolio_Project..CovidDeaths dea
inner join Portfolio_Project..CovidVaccinations vac	
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null-- and dea.location like '%albania'
--order by 2,3 [We cannot use orderby in CTEs]
)

select *, (rolling_total/population)*100 as percenatge_vaccinated
from Running_total

--Using Temp Table

drop table if exists #percentpopulationvaccinated
create table #percentpopulationvaccinated
(
continent nvarchar (255),
location nvarchar (255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_total numeric
)

insert into #percentpopulationvaccinated
select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations
,sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling_total
from Portfolio_Project..CovidDeaths dea
inner join Portfolio_Project..CovidVaccinations vac	
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3

select * , (rolling_total/population)*100 as percentage_vaccinated
from #percentpopulationvaccinated

--creating views for storing data for later visualisation

create View percentpopulationvaccinated as
select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations
,sum(convert(int,vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as rolling_total
from Portfolio_Project..CovidDeaths dea
inner join Portfolio_Project..CovidVaccinations vac	
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
--order by 2,3

select * from percentpopulationvaccinated