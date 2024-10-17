--Import the csv file that has been preproceesed using Python to take care 
--of empty cells as null
select * from
PortfolioProject..CovidDeaths
where continent is not null
order by 3,4

--11/10/2024
select * from
PortfolioProject..CovidVaccinations
order by 3,4

--Select the data that we are going to be using
--Converting empty cell to contain null values
select Location, date, NULLIF(total_cases,'')as total_cases, NULLIF(new_cases, '') AS  new_cases, NULLIF(total_deaths, '') AS deathstotal, population
from PortfolioProject..CovidDeaths
where continent is not null
order by 1,2


--Correct one
SELECT location, date, NULLIF(total_cases, '') AS total_cases,  NULLIF(new_cases, '') AS new_cases, NULLIF(total_deaths, '') 
	AS deathstotal, population,
    (CAST(NULLIF(total_deaths, '') AS DECIMAL(18, 2)) * 100.0 / NULLIF(total_cases, '')) AS PercentgeDeath
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL
ORDER BY 
    location, date;

--lookinf at Total cases vs the population
--correct
Select 
	Location, date, Population ,NULLIF(total_cases, '') AS total_cases,
	(CAST(NULLIF(total_deaths, '') AS DECIMAL(18, 2)) * 100.0 / NULLIF(population, '')) AS PercentgeDeath
from
	PortfolioProject..CovidDeaths
WHERE 
	Location LIKE '%botswana%'
--WHERE continent is not null
order by 1,2

--looking at Counties with Hightest Infection Rate compared to Population
--CHECK IT AND WRITE A SIMPLE QUERY
SELECT Location, CAST(Population AS BIGINT) AS Population, 
    MAX(Total_Cases) AS HighestInfectedCount, 
    MAX(CASE 
            WHEN CAST(Population AS BIGINT) > 0 THEN CAST(Total_Cases AS FLOAT) / CAST(Population AS BIGINT)
            ELSE 0 
        END) * 100 AS PercentagePopulationInfected
FROM 
    PortfolioProject..CovidDeaths
where continent is not null
GROUP BY 
    Location, Population
ORDER BY 
    PercentagePopulationInfected DESC;

--SHOWING THE Countries with the Highest Death Count per Polpolation
-- THE query does not show the desire results with the WHERE CLAUse
--correction needed
SELECT 
	continent,  MAX(cast (Total_deaths as int)) AS TotalDeathCount
FROM 
	PortfolioProject..CovidDeaths
WHERE 
	continent is not null
GROUP BY 
	continent
order BY 
	TotalDeathCount DESC;


--Global Numbers
--correct
SELECT 
	date, SUM(CAST(new_cases AS INT)) AS TotalCases, SUM(CAST(new_deaths AS INT)) AS TotalDeaths,
    CASE 
        WHEN SUM(CAST(NULLIF(new_cases, '') AS INT)) > 0
        THEN (SUM(CAST(NULLIF(new_deaths, '') AS INT)) * 100.0 / SUM(CAST(NULLIF(new_cases, '') AS INT))) 
        ELSE NULL 
    END AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE 
    continent IS NOT NULL  -- Exclude records where continent is NULL
GROUP BY
	date
ORDER BY 
	1,2;
--
--- CORRECT
SELECT 
    SUM(CAST(NULLIF(new_cases, '') AS INT)) AS TotalCases,
    SUM(CAST(NULLIF(new_deaths, '') AS INT)) AS TotalDeaths,
    CASE 
        WHEN SUM(CAST(NULLIF(new_cases, '') AS INT)) > 0 
        THEN (SUM(CAST(NULLIF(new_deaths, '') AS INT)) * 100.0 / SUM(CAST(NULLIF(new_cases, '') AS INT)))
        ELSE NULL 
    END AS DeathPercentage
FROM 
    PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL  -- Exclude records where continent is NULL
--GROUP BY date
ORDER BY 1,2 --date ASC;
    
--Looking at Total Population vs Vaccinations
--correct
SELECT 
	NULLIF(dea.continent, '') AS continent,NULLIF(dea.location, '') AS location,dea.date,dea.population,
	NULLIF(vac.new_vaccinations,'') AS new_vaccinations
FROM  
	PortfolioProject..CovidDeaths dea
JOIN  PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND dea.continent != ''  -- Exclude records where continent is an empty string
ORDER BY 1, 2;

--correct
SELECT
	NULLIF(dea.continent, '') AS continent,NULLIF(dea.location, '') AS location,dea.date,dea.population,
	NULLIF(vac.new_vaccinations,'') AS new_vaccinations,SUM(CAST(NULLIF(vac.new_vaccinations, '') AS INT))
	OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeeopleVaccinated
FROM 
PortfolioProject..CovidDeaths dea
JOIN  PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND dea.continent != ''  -- Exclude records where continent is an empty string
ORDER BY 2,3;

--USE A CTE
WITH PopvsVac (continent, location, date,population,new_vaccinations, RollingPeopleVaccinated)
as( 
SELECT NULLIF(dea.continent, '') AS continent,NULLIF(dea.location, '') AS location,dea.date,dea.population,NULLIF(vac.new_vaccinations,'') AS new_vaccinations,
SUM(CAST(NULLIF(vac.new_vaccinations, '') AS INT)) OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeeopleVaccinated
FROM  PortfolioProject..CovidDeaths dea
JOIN  PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND dea.continent != ''  -- Exclude records where continent is an empty string
--ORDER BY 2,3
)
 select*,
    (CAST(RollingPeopleVaccinated AS FLOAT)) / (CAST(population AS FLOAT)) * 100.0 AS VaccinationPercentage
from PopvsVac

--TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),Location nvarchar(255),Date datetime,Population numeric,New_vaccinations float,RollingPeopleVaccinated int
)
insert into #PercentPopulationVaccinated

SELECT
NULLIF(dea.continent, '') AS continent,NULLIF(dea.location, '') AS location,TRY_CAST(dea.date AS DATETIME) AS date,NULLIF(dea.population,''),NULLIF(vac.new_vaccinations,'') AS new_vaccinations,
SUM(CAST(NULLIF(vac.new_vaccinations, '') AS INT)) OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeopleVaccinated
FROM  PortfolioProject..CovidDeaths dea
JOIN  PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND TRY_CAST(dea.date AS DATETIME) = TRY_CAST(vac.date AS DATETIME)
WHERE dea.continent IS NOT NULL
AND dea.continent != ''  -- Exclude records where continent is an empty string
--ORDER BY 2,3
select*,
   (CAST(RollingPeopleVaccinated AS FLOAT)) / (CAST(population AS FLOAT)) * 100.0 AS VaccinationPercentage
from #PercentPopulationVaccinated

--CREATE A VIEW	TO STORE DATA FOR LATER VISUALIZATION
DROP VIEW IF EXISTS PercentPopulationVaccinated;

create VIEW PercentPopulationVaccinated AS
SELECT
	NULLIF(dea.continent, '') AS continent,NULLIF(dea.location, '') AS location,dea.date,dea.population,
	NULLIF(vac.new_vaccinations,'') AS new_vaccinations,SUM(CAST(NULLIF(vac.new_vaccinations, '') AS INT))
	OVER (Partition by dea.location Order by dea.location,dea.date) as RollingPeeopleVaccinated
FROM 
PortfolioProject..CovidDeaths dea
JOIN  PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
AND dea.continent != ''  -- Exclude records where continent is an empty string
--ORDER BY 2,3; 

SELECT schema_name(schema_id) AS schema_name, name 
FROM sys.views 
WHERE name = ' PercentPopulationVaccinated';

SELECT * 
FROM PercentPopulationVaccinated 
SELECT DB_NAME() AS CurrentDatabase;
USE PortfolioProject;
--create another view

select * 
from PercentPopulationVaccinated