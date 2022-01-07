----/*
----A data exploration on Covid 19 vaccine efficacy
----Data set source: https://ourworldindata.org/covid-deaths
----Skills used: Joins, common table expressions, temp tables, Windows functions,
----aggregate functions, creating views, converting data types
----*/

----[DATA SET TEST QUERY]
----[Selects table relating to Covid 19 deaths]
--SELECT *
--FROM SQL_Portfolioproject_Covid.dbo.Covid_deaths$
--WHERE continent is not null
--ORDER BY 3,4

--SELECT Location, date, total_cases, new_cases, total_deaths, population
--FROM SQL_Portfolioproject_Covid.dbo.Covid_deaths$
--WHERE continent is not null 
--ORDER BY 1,2

----[Total Cases vs Total Deaths]
----[Current Canadian mortality rate expressed as a percentage of cases]
--SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as percentage_deaths
--FROM SQL_Portfolioproject_Covid.dbo.Covid_deaths$
--WHERE location = 'Canada'
--ORDER BY total_cases DESC

----[Total Cases vs Population]
----[Currently Canadian infection rate expressed as a percentage of population]
--SELECT Location, date, total_cases, population, (total_cases/population)*100 as percentage_cases
--FROM SQL_Portfolioproject_Covid.dbo.Covid_deaths$
--WHERE location = 'Canada'
--ORDER BY total_cases DESC

----[Infection Rate as a percentage of population, by country]
--SELECT Location, MAX(total_cases) as PeakInfection, population, MAX((total_cases/population))*100 as percentage_infected
--FROM SQL_Portfolioproject_Covid.dbo.Covid_deaths$
--WHERE continent is not null
--GROUP BY Location, population
--ORDER BY percentage_infected DESC

----[Mortality Rate as a percentage of population, by country]
----[(converted total_deaths values from nvarchar(255) to int)]
--SELECT Location, MAX(cast(total_deaths as int)) as CurrentDeathCount, MAX((total_deaths/population))*100 as mortality_rate
--FROM SQL_Portfolioproject_Covid.dbo.Covid_deaths$
--WHERE continent is not null
--GROUP BY Location
--ORDER BY mortality_rate DESC

----[Mortality Rate as a percentage of population, by continent]
----[(converted total_deaths values from nvarchar(255) to int)]
----[(Filtered non continent rows from query results)]
--SELECT location, MAX(cast(total_deaths as int)) as Overall_deaths, MAX((total_deaths/population))*100 as mortality_rate
--FROM SQL_Portfolioproject_Covid.dbo.Covid_deaths$
--WHERE continent is null
--AND location NOT IN ('European Union', 'High income', 'International', 'Low income', 'Lower middle income', 'Upper middle income')
--GROUP BY location
--ORDER BY mortality_rate DESC

----[GLOBAL VALUES]
----[(Using aggregate functions and converting value types)]
--SELECT date, SUM(new_cases) as 'Global_newcases', SUM(cast(new_deaths as int)) as 'Global_newdeaths', SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Global_mortrate
--FROM SQL_Portfolioproject_Covid.dbo.Covid_deaths$
--WHERE continent is not null
--GROUP BY date
--ORDER BY 1,2

----[Joining two tables for comparison]
--SELECT *
--FROM SQL_Portfolioproject_Covid.dbo.Covid_deaths$ dea
--JOIN SQL_Portfolioproject_Covid.dbo.Covid_vaccines$ vac
--  ON dea.location = vac.location
--	AND dea.date = vac.date

--[Total population vs Vaccinations]
----[(Joins, aggregate functions)]
--SELECT dea.continent, dea.location, dea.date, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) 
--  OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as 'Vaccines_runningtotal'
--FROM SQL_Portfolioproject_Covid.dbo.Covid_deaths$ dea
--JOIN SQL_Portfolioproject_Covid.dbo.Covid_vaccines$ vac
--    ON dea.location = vac.location
--	AND dea.date = vac.date
--WHERE dea.continent is not null
--ORDER BY 2,3

----[Total population vs Vaccinations]
----[Using Common Table Expressions(CTEs)]
--WITH PopVac (continent, location, date, population, new_vaccinations, Vaccines_runningtotal)
--AS
--(
--SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) 
--  OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as 'Vaccines_runningtotal'
--FROM SQL_Portfolioproject_Covid.dbo.Covid_deaths$ dea
--JOIN SQL_Portfolioproject_Covid.dbo.Covid_vaccines$ vac
--    ON dea.location = vac.location
--	AND dea.date = vac.date
--WHERE dea.continent is not null
--)
--SELECT *, (Vaccines_runningtotal/population)*100 as 'Vaccines_runningpercentage'
--FROM PopVac

----[Using Temp Tables]
----[(Includes safeguard against creating multiple instances of the same table.)]
--DROP TABLE IF EXISTS #PercentPopVaccinated
--CREATE TABLE #PercentPopVaccinated
--(
--continent nvarchar(255),
--location nvarchar(255),
--date datetime,
--population numeric,
--new_vaccinations numeric,
--Vaccines_runningtotal numeric
--)
--INSERT INTO #PercentPopVaccinated
--SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) 
--  OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as 'Vaccines_runningtotal'
--FROM SQL_Portfolioproject_Covid.dbo.Covid_deaths$ dea
--JOIN SQL_Portfolioproject_Covid.dbo.Covid_vaccines$ vac
--    ON dea.location = vac.location
--	AND dea.date = vac.date
--WHERE dea.continent is not null

--SELECT *, (Vaccines_runningtotal/population)*100 as 'Vaccines_runningpercentage'
--FROM #PercentPopVaccinated

--[CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS]
CREATE VIEW PercentPopVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) 
  OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as 'Vaccines_runningtotal'
FROM SQL_Portfolioproject_Covid.dbo.Covid_deaths$ dea
JOIN SQL_Portfolioproject_Covid.dbo.Covid_vaccines$ vac
    ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null