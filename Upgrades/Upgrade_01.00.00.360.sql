INSERT INTO #Description VALUES ('Update SP for report statistic folder')
GO

IF OBJECT_ID('[dbo].[m136_spReportFolderDocumentStatistics]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_spReportFolderDocumentStatistics] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_spReportFolderDocumentStatistics]
	@HandbookId AS INT,
	@SecurityId AS INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @resultTable TABLE(period DATETIME, Approved INT)
	DECLARE @resultTable1 TABLE(period DATETIME, Approved INT)
	
	DECLARE @DateFrom DATETIME 
	SET @DateFrom = (SELECT dtmCreated FROM m136_tblHandbook WHERE iHandbookID = @HandbookId) 
	SET @DateFrom = (SELECT DATEADD(dd, DATEDIFF(dd, 0, @DateFrom), 0))
	SET @DateFrom = (SELECT DATEADD(YEAR, DATEDIFF(YEAR, 0, @DateFrom), 0))
	DECLARE @monthintervall INT
	set @monthintervall = (SELECT DATEDIFF(YEAR, @DateFrom,GETDATE()))
	DECLARE @I INT
	SET @I = 0
	WHILE @I <= @monthintervall
	BEGIN
		INSERT INTO @resultTable(period)
		VALUES(@DateFrom)
		SET @DateFrom = DATEADD(YEAR,1,@DateFrom)
		SET @I = @I + 1
	END
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	
	INSERT INTO @resultTable1(period)
	SELECT TOP 4 period
	  FROM @resultTable
	  ORDER BY period DESC
	
	INSERT INTO @AvailableChildren(iHandbookId)
	SELECT 
		iHandbookId 
	FROM 
		[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1);
	
	UPDATE rt SET rt.Approved = 
			(SELECT Count(DISTINCT iDocumentId) AS Approved  
			  FROM m136_tblDocument d 
			  JOIN @AvailableChildren ac ON d.iHandbookId = ac.iHandbookId 
			  WHERE d.iApproved = 1 AND YEAR(d.dtmPublish) <= YEAR(rt.period) AND d.dtmPublish < GETDATE()) 
			  FROM @resultTable1 rt
			  
	SELECT period AS Date, Approved
	FROM @resultTable1
	ORDER BY period
END
GO

IF OBJECT_ID('[dbo].[m136_spReportHandbookDocumentStatistics]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_spReportHandbookDocumentStatistics] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_spReportHandbookDocumentStatistics]
	@SecurityId AS INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @resultTable TABLE(period DATETIME, Approved INT)
	DECLARE @resultTable1 TABLE(period DATETIME, Approved INT)

	DECLARE @DateFrom DATETIME
	SET @DateFrom = (SELECT TOP 1 dtmCreated FROM m136_tblHandbook WHERE ideleted = 0 ORDER BY dtmCreated) 
	SET @DateFrom = (SELECT DATEADD(dd, DATEDIFF(dd, 0, @DateFrom), 0))
	SET @DateFrom = (SELECT DATEADD(YEAR, DATEDIFF(YEAR, 0, @DateFrom), 0))
		
	DECLARE @monthintervall INT
	SET @monthintervall = (SELECT DATEDIFF(YEAR, @DateFrom,GETDATE()))

	DECLARE @I INT
	SET @I = 0
	
	WHILE @I <= @monthintervall
	BEGIN
		INSERT INTO @resultTable(period)
		VALUES(@DateFrom)

		SET @DateFrom = DATEADD(YEAR,1,@DateFrom)
		SET @I = @I + 1
	END
	
	INSERT INTO @resultTable1(period)
	SELECT TOP 4 period
	  FROM @resultTable
	  ORDER BY period DESC

   	DECLARE @Approved INT	
   	DECLARE @Period DATETIME

	DECLARE curPeriod CURSOR FOR
	SELECT period FROM @resultTable1
	OPEN curPeriod
	FETCH NEXT FROM curPeriod INTO @Period
	WHILE @@FETCH_STATUS =0
	BEGIN	
	
		SELECT @Approved = (SELECT COUNT(DISTINCT iDocumentId) 
				FROM m136_tblDocument d
					WHERE d.iApproved = 1 and YEAR(d.dtmPublish) <= YEAR(@Period) AND d.dtmPublish < GETDATE())
			
				
		UPDATE @resultTable1 
		SET Approved = @Approved
		WHERE period = @Period;
	FETCH NEXT FROM curPeriod INTO @Period
	END
	CLOSE curPeriod
	DEALLOCATE curPeriod
    
	SELECT period AS Date, Approved
	FROM @resultTable1
	ORDER BY period
	
END
GO


