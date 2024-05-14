USE [FinanceF23]
GO

ALTER FUNCTION [dbo].[fnCorrelation]
(
    @tickerX varchar(10),
	@tickerY varchar(10),
    @startDate date,
	@endDate date
)
RETURNS float
AS
BEGIN
    DECLARE @pricesX AS TABLE
    (
        [date] smalldatetime,
        tprice float,
        yprice float
    )

    DECLARE @pricesY AS TABLE
    (
        [date] smalldatetime,
        tprice float,
        yprice float
    )
	DECLARE @returns AS TABLE 
	(
		[Date] smalldatetime, 
		drX float, 
		drY float
	);

    INSERT INTO @pricesX
    SELECT [date],
        [close],
        LAG([close], 1, 0) OVER (ORDER BY [date])
    FROM
        TS_DailyData
    WHERE
        ticker = @TickerX AND Date BETWEEN @StartDate AND @EndDate
    ORDER BY
        [date] DESC;

    INSERT INTO @pricesY
    SELECT [date],
        [close] ,
        LAG([close], 1, 0) OVER (ORDER BY [date]) 
    FROM
        TS_DailyData
    WHERE
         ticker = @tickerY AND Date BETWEEN @StartDate AND @EndDate
    ORDER BY
        [date] DESC;

	INSERT @returns
	SELECT X.date
	,X.tprice/X.yprice -1
	,Y.tprice/Y.yprice -1
	FROM @pricesX X
	JOIN @pricesY Y on X.date = Y.date
	WHERE X.date > (SELECT MIN(Date) from @pricesX)
	and Y.date > (SELECT MIN(Date) from @pricesY)

	DECLARE @SQ float, 
			@SQ2 float, 
			@SR float, 
			@SR2 float, 
			@SQR float, 
			@DQ float, 
			@DR float, 
			@NQR float
	
	DECLARE @N int 

	SELECT @SQ = SUM(drX)
	,@SQ2 = SUM(drX*drX)
	,@SR = SUM(drY)
	,@SR2 = SUM(drY*drY)
	,@SQR = SUM(drX*drY)
	,@N = count(date)
	FROM @returns
	SET @DQ = @N * @SQ2 - @SQ * @SQ
	SET @DR = @N * @SR2 - @SR * @SR
	SET @NQR = @N * @SQR - @SQ * @SR
	DECLARE @Correlation as float
	SET @Correlation = @NQR / SQRT(@DQ * @DR)
	RETURN @Correlation
END
 
