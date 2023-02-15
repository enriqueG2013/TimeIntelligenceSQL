


/* Enrique Gonzalez - Time Intelligence in SQL */
/* Tables and certain attributes names were changed for work confidential */

WITH Cost AS (
	SELECT b.FiscalYearName
		, a.FiscalPeriod
		, b.FiscalQuarter
		, b.FiscalPeriodName
		, SUM(a.constantdollaramount) as Amount
	FROM GLLineItem a
		join FiscalMonth b on b.FiscalPeriod = a.FiscalPeriod
		join CostCenter c on a.CostCenterCode = c.CostCenterCode
	WHERE b.FiscalYearName = 'FY22'
		or b.FiscalYearName = 'FY21'
		and a.CostCenterCode = 10179129
	GROUP BY b.FiscalYearName, a.FiscalPeriod, b.FiscalQuarter, b.FiscalPeriodName
),

TimeIntel AS (
	SELECT FiscalYearName
		, FiscalPeriod
		, FiscalQuarter
		, FiscalPeriodName
		, sum(Amount) as Amount
		, sum(Amount) over (partition by FiscalQuarter order by FiscalPeriod) as QTD
		, sum(Amount) over (Partition by year(fiscalperiod) order by fiscalperiod) as YTD
		, LAG(Amount) over (order by Year(fiscalperiodName), Month(fiscalPeriodName)) as MoM
		, Lag(sum(Amount), 3) over (order by Year(fiscalperiodName), Month(fiscalperiodName)) as QoQ
		, Lag(sum(Amount), 11) over (order by Year(fiscalperiodName), Month(fiscalperiodName)) as YoY
		, sum(Amount) - Amount as RoY
	FROM Cost 
	GROUP BY FiscalYearName, FiscalPeriod, FiscalQuarter, FiscalPeriodName, Amount
),

TimeIntel_Var AS (
	SELECT FiscalYearName
		, FiscalPeriod
		, FiscalQuarter
		, FiscalPeriodName
		, Amount
		, QTD
		, (sum(Amount) over (partition by FiscalQuarter order by FiscalPeriod)) - coalesce(lag(QTD) over (partition by fiscalquarter 
		order by FiscalYearname), 0) as QTD_Var
		, YTD
		, YTD - coalesce(lag(YTD) over (partition by year(fiscalperiod) order by FiscalYearname), 0)  as YTDvar
		, MoM
		, Amount  - (LAG(Amount) over (order by Year(fiscalperiodName), Month(fiscalPeriodName))) as MoMvar
		, QoQ
		, Sum(amount) - Lag(sum(Amount), 3) over (order by Year(fiscalperiodName), Month(fiscalperiodName)) as QoQVar
		, YoY
		, sum(Amount) - Lag(sum(Amount), 11) over (order by Year(fiscalperiodName), Month(fiscalperiodName)) as YoYvar
		, LAG(QTD) over (Partition by FiscalYearName, FiscalQuarter order by Fiscalperiod) as QTDoQTD
		, LAG(YTD) over (Partition by FiscalYearName order by FiscalQuarter) as YTDoYTD
		, RoY
	FROM TimeIntel
	GROUP BY FiscalYearName, FiscalPeriod, FiscalQuarter, FiscalPeriodName, Amount, QTD, YTD, MoM, YoY, QoQ, RoY
)

SELECT FiscalYearName
	, FiscalPeriod
	, FiscalQuarter
	, FiscalPeriodName
	, Amount
	, QTD
	, QTD_Var
	, (QTD_Var / Nullif(coalesce(lag(QTD) over (partition by fiscalquarter, fiscalYearName order by FiscalYearname), 0), 0)) * 100 as QTD_Var_Percentage
	, YTD
	, YTDvar
	, (YTDvar / nullif(coalesce(lag(YTD) over (partition by year(fiscalperiod) order by FiscalYearname), 0), 0)) * 100 as YTD_Var_Percentage
	, MoM
	, MoMvar
	, (MoMvar / nullif((LAG(Amount) over (order by Year(fiscalperiodName), Month(fiscalPeriodName))), 0)) * 100 as MoM_Var_Percentage
	, QoQ
	, QoQVar
	, (QoQVar / nullif(Lag(sum(Amount), 3) over (order by Year(fiscalperiodName), Month(fiscalperiodName)), 0)) * 100 as QoQ_Var_Percentage
	, YoY
	, YoYvar
	, (YoYvar / nullif(Lag(sum(Amount), 11) over (order by Year(fiscalperiodName), Month(fiscalperiodName)), 0)) * 100 as YoY_Var_Percentage
	, QTDoQTD
	, YTDoYTD
	, RoY
FROM TimeIntel_Var
GROUP BY FiscalYearName, FiscalPeriod, FiscalQuarter, FiscalPeriodName, Amount, QTD, QTD_Var, YTD, YTDvar, MoM, MoMvar,
	YoY, YoYvar, QTDoQTD, YTDoYTD, QoQ, QoQVar, RoY
ORDER BY FiscalPeriod








