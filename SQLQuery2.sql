use Stock_Analysis
exec sp_help 'master_stock_data';

--1check the number of rows

select 
count(*) as Total_rows
from master_stock_data

--2top data
select top 10 *
from master_stock_data

--3find the date range
select
min(Date) as first_date,
max(Date) as last_date
from master_stock_data;

--4find how many stocks
select 
count(Distinct Ticker) as totat_stock
from master_stock_data

--5check missing values
select 
count(*) as TotalRows,
sum(
	case when 
			[Date] is null then 1 else 0
		end
) as Missing_Date,
sum(
	case when
			Ticker is null then 1 else 0
		end
) as Missing_Ticker,
sum(
	case when
			Adj_Close is null then 1 else 0
		end
) as Missing_Adj_Close,
sum(
	case when
			[Close] is null then 1 else 0
		end
) as Missing_close,
sum(
	case when
			Dividends is null then 1 else 0
		end
) as Missing_Dividents,
sum(
	case when
			[High] is null then 1 else 0
		end
) as Missing_High,
sum(
	case when 
			[Low] is null then 1 else 0
		end
) as Missing_Low,
sum(
	case when
			[Open] is null then 1 else 0
		end
) as Missing_Open,
sum(
	case when
			[Stock_Splits] is null then 1 else 0
		end
) as Missing_Stock_Splits,
sum(
	case when 
			'Volume' is null then 1 else 0
		end
) as Missing_Volume
from master_stock_data

--6check duplicates
select 
	Date,
	Ticker,
	count(*) as RecordCount
From master_stock_data
Group by Date, Ticker
Having count(*) > 1;

--7check for impossible values
select 
count(*) as Invalid_Rows
From master_stock_data
where 
	[high] < [low]
	or [High] < 0
	or [low] < 0
	or [Open] < 0
	or [Close] < 0
	or [Volume] < 0


/*
What we've completed

CSV
 ↓
SQL Server
 ↓
Table created
 ↓
Schema inspected
 ↓
Row count checked
 ↓
Date range checked
 ↓
Number of stocks checked
 ↓
Missing values checked
 ↓
Duplicates checked
 ↓
Invalid values checked ✅
*/

--SQL EDA

select
	Ticker,
	count(*) as total_record,
	Min(Date) as FirstTradingDate,
	Max(Date) as LastTradingDate
from master_stock_data
Group by Ticker
order by total_record Desc;

select
	Ticker,
	Avg([Adj_Close]) as AVJCLose,
	Avg([Open]) as AvgOpen,
	Avg([close]) as AverageClose,
	Max([close]) as MaxClose,
	Min([close]) as MinClose,
	Avg(CAST(Volume as float)) as AverageVolume
from master_stock_data
group by Ticker
order by AverageClose Desc

--sql EDA: Time-Series Analysis

-- Look at CVX's yearly statistics
Select
	YEAR([Date]) as TradingYear,
	count(*) as TradingDays,
	avg([close]) as avgClose,
	Min([close]) as MinClose,
	Max([close]) as MaxCLose,
	avg(cast([Volume] as Float)) as avgVolume
from master_stock_data
where Ticker = 'Cvx'
Group by Year(Date)
order by TradingYear

-- Monthly analysis
select 
	YEAR([Date]) as TrendingYear,
	MONTH([Date]) as TrendingMonth,
	AVG([close]) as AVGclose,
	Avg(cast(Volume as float)) as AVGvolume
from master_stock_data
Where Ticker = 'CVX'
Group by 
	YEAR([Date]),
	MONTH([Date])
Order By
	TrendingYear,
	TrendingMonth;

--calculate daily returns (find a fractional groath rate)
/*
		  close_t - close_t-1
return = ----------------------
              close_t-1

*/
--SQL Server has a function called LAG() 
--that allows us to access the previous day's closing price.

WITH Stock_Analysis AS(
	SELECT 
		[Date],
		Ticker,
		[Close],
		LAG([Close]) Over(
			Partition by Ticker
			Order BY [Date]
		) AS PreviousClose
	From master_stock_data
	where Ticker = 'CVX'
)
select top 20
	[Date],
	Ticker,
	[close],
	PreviousClose,
	([close] - PreviousClose) / nullif(PreviousClose, 0) AS DailyReturn
From Stock_Analysis
where PreviousClose is not null
order by [Date];


-- Calculate return statistics
WITH Stock_Analysis AS
(
	Select
		[Date],
		Ticker,
		[close],
		Lag([Close]) over(
			Partition by Ticker
			Order by [Date]
		)As previousClose
	From master_stock_data
	Where Ticker = 'CVX'
),
Returns AS
(
	Select
		[Date],
		Ticker,
		([close] - previousClose)
		/ NullIf(previousClose, 0) As DailyReturn
	From Stock_Analysis
	where previousClose is not null
)
Select
	Count(*) AS TradingDays,
	Avg(DailyReturn) AS AverageDailyReturn,
	Min(DailyReturn) As MinimumDailyReturn,
	Max(DailyReturn) As MaximumDailyReturn
From Returns;


--Identify the biggest daily (Positive) movements
With Stock_Analysis as(
	Select
		[Date],
		[Ticker],
		[Close],
		Lag([Close]) over(
			partition by Ticker
			Order By [Date]
		) As PreviousClose
	From master_stock_data
	Where Ticker = 'CVX'
),
Returns As(
	select
		[Date],
		[Ticker],
		[Close],
		PreviousClose,
		([Close] - previousClose)
		/ Nullif(previousClose, 0) as DailyReturn
	From Stock_Analysis
	where previousClose is not null
)
select top 10
	[Date],
	[close],
	PreviousClose,
	DailyReturn
from Returns
order by DailyReturn Desc;

--Negative
WITH Stock_Analysis AS
(
    SELECT
        Date,
        Ticker,
        [Close],
        LAG([Close]) OVER (
            PARTITION BY Ticker
            ORDER BY Date
        ) AS PreviousClose
    FROM master_stock_data
    WHERE Ticker = 'CVX'
),
Returns AS
(
    SELECT
        Date,
        Ticker,
        [Close],
        PreviousClose,
        ([Close] - PreviousClose)
        / NULLIF(PreviousClose, 0) AS DailyReturn
    FROM Stock_Analysis
    WHERE PreviousClose IS NOT NULL
)
SELECT TOP 10
    Date,
    [Close],
    PreviousClose,
    DailyReturn
FROM Returns
ORDER BY DailyReturn ASC;