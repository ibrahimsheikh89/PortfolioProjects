/*
Explore Covid 19 latest data

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

SELECT * FROM CovidProject..covidDeath
ORDER BY 3,4

SELECT * FROM CovidProject..CovidVaccination
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths,population
FROM CovidProject..covidDeath
ORDER BY 1,2

-- Show Cases vs Total deaths

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) as DeathPercentage
FROM CovidProject..covidDeath
ORDER BY 1,2

-- Show Total cases vs population

SELECT location, date, total_cases, population, (total_cases/population) as InfectionPercentage
FROM CovidProject..covidDeath
ORDER BY 1,2

-- Show Cases vs Total deaths in Canada

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) as DeathPercentage
FROM CovidProject..covidDeath
WHERE location like 'Canada'
ORDER BY 1,2

-- Create a veiw table for Canada total deaths vs population

CREATE VIEW CanadaTotalDeathvsPopulation as
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) as DeathPercentage
FROM CovidProject..covidDeath
WHERE location like 'Canada'

-- Show Total cases vs population in Canada 

SELECT location, date, total_cases, population, (total_cases/population) as InfectionPercentage
FROM CovidProject..covidDeath
WHERE location = 'Canada'
ORDER BY 1,2

-- Create a veiw table for Canada total cases vs population

CREATE VIEW CanadaTotalCasevsPopulation as
SELECT location, date, total_cases, population, (total_cases/population) as InfectionPercentage
FROM CovidProject..covidDeath
WHERE location = 'Canada'

-- Checking countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as 
HighestPercentageInfected
FROM CovidProject..covidDeath
GROUP BY location,population
ORDER BY HighestPercentageInfected desc

-- Checking countries wiht highest death count per population

SELECT location, Max(cast(total_deaths as int)) as TotalDeathCount
FROM CovidProject..covidDeath
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc


-- Checking continent wiht highest death count

SELECT location, Max(cast(total_deaths as int)) as TotalDeathCount
FROM CovidProject..covidDeath
WHERE continent is null AND location not in ('World', 'International')
GROUP BY location
ORDER BY TotalDeathCount desc



-- Checking Global numbers

SELECT date,SUM(new_cases) as new_total_cases,SUM(cast(new_deaths as int)) as new_total_death,SUM(cast(new_deaths as int))/
SUM(new_cases)*100 as DeathPercentage
FROM CovidProject..covidDeath
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- Total number worldwide 

SELECT SUM(new_cases) as new_total_cases,SUM(cast(new_deaths as int)) as new_total_death,SUM(cast(new_deaths as int))/
SUM(new_cases)*100 as DeathPercentage
FROM CovidProject..covidDeath
WHERE continent is not null
ORDER BY 1,2


-- Total vaccinations number vs poplulation

SELECT cde.continent, cde.location, cde.date, cde.population, cva.new_vaccinations,
SUM(cast(cva.new_vaccinations as int)) OVER (PARTITION BY cde.location ORDER BY cde.location,
cde.date) as VaccineRollout
FROM CovidProject..covidDeath cde
JOIN CovidProject..CovidVaccination cva
    ON cde.location = cva.location
	AND cde.date = cva.date
WHERE cde.continent is not null
ORDER BY 2,3

-- Perform calculation on the previous query using CTE  

WITH PopvsVac (continent, location, date, population,new_vaccinations, VaccineRollout)
as(
SELECT cde.continent, cde.location, cde.date, cde.population, cva.new_vaccinations,
SUM(CONVERT(int, cva.new_vaccinations)) OVER (PARTITION BY cde.location ORDER BY cde.location,
cde.date) as VaccineRollout
FROM CovidProject..covidDeath cde
JOIN CovidProject..CovidVaccination cva
    ON cde.location = cva.location
	AND cde.date = cva.date
WHERE cde.continent is not null
)
SELECT *, (VaccineRollout/population)*100
FROM PopvsVac


-- Perform calculation on the previous query using temp table

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Data datetime,
Population numeric,
New_vaccinations numeric,
VaccineRollout numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT cde.continent, cde.location, cde.date, cde.population, cva.new_vaccinations,
SUM(CONVERT(int, cva.new_vaccinations)) OVER (PARTITION BY cde.location ORDER BY cde.location,
cde.date) as VaccineRollout
FROM CovidProject..covidDeath cde
JOIN CovidProject..CovidVaccination cva
    ON cde.location = cva.location
	AND cde.date = cva.date
WHERE cde.continent is not null
SELECT *, (VaccineRollout/population)*100
FROM #PercentPopulationVaccinated

-- Create view for visualization

CREATE VIEW PercentPopulation as
SELECT cde.continent, cde.location, cde.date, cde.population, cva.new_vaccinations,
SUM(CONVERT(int, cva.new_vaccinations)) OVER (PARTITION BY cde.location ORDER BY cde.location,
cde.date) as VaccineRollout
FROM CovidProject..covidDeath cde
JOIN CovidProject..CovidVaccination cva
    ON cde.location = cva.location
	AND cde.date = cva.date
WHERE cde.continent is not null


-- Create view for visualization

CREATE VIEW  CanadaVacRollout as
SELECT cde.location, cde.date, cde.population, cva.new_vaccinations,
SUM(cast(cva.new_vaccinations as int)) OVER (PARTITION BY cde.location ORDER BY cde.location,
cde.date) as VaccineRollout
FROM CovidProject..covidDeath cde
JOIN CovidProject..CovidVaccination cva
    ON cde.location = cva.location
	AND cde.date = cva.date
WHERE cde.continent is not null AND cde.location = 'Canada'
