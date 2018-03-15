INSERT INTO #Description VALUES('Implmenet get Report folder Statistics')
GO

IF OBJECT_ID('[dbo].[m136_spReportFolderOverview]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_spReportFolderOverview] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_spReportFolderOverview]
	@HandbookId AS INT,
	@SecurityId AS INT	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @resultTable TABLE(iHandbookId INT, strName NVARCHAR(200), iLevelType INT, 
	   Approved INT, Expired INT, NewCount INT, NewAndUpdatedCount INT, Revised INT, AwaitingApproval INT, Archived INT,
	   Internet INT, Folders INT)
   
	INSERT INTO @resultTable (iHandbookId ,strName, iLevelType ) 
	(SELECT ihandbookid , strName, iLevelType FROM m136_tblHandbook WHERE iHandbookId = @HandbookId)

	DECLARE @Approved INT
	DECLARE @Expired INT
	DECLARE @NewCount INT
	DECLARE @NewAndUpdatedCount INT
	DECLARE @Revised INT
	DECLARE @AwaitingApproval INT
	DECLARE @Archived INT
	DECLARE @Folders INT	
	DECLARE @Internet INT

	DECLARE @DateFrom DATETIME
	DECLARE @DateTo DATETIME

	SET @DateFrom = DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0)
	SET @DateTo = GETDATE()

	DECLARE curHandbookId CURSOR FOR
	SELECT iHandbookId FROM @resultTable

	OPEN curHandbookId
	FETCH NEXT FROM curHandbookId INTO @HandbookId
	WHILE @@FETCH_STATUS =0
	BEGIN

		DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	
		DELETE FROM @AvailableChildren
	
		INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1);
		
		SELECT @Folders = (SELECT COUNT(*) FROM @AvailableChildren)-1 
		
		SELECT @Approved = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					JOIN @AvailableChildren ac
						ON d.iHandbookId = ac.iHandbookId
					WHERE d.iLatestApproved = 1 and d.dtmPublish < @DateTo)
				
		SELECT @Expired = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					JOIN @AvailableChildren ac
						ON d.iHandbookId = ac.iHandbookId
					WHERE d.iLatestApproved = 1 and d.dtmPublishUntil < @DateTo)
				
		SELECT @AwaitingApproval = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					JOIN @AvailableChildren ac
						ON d.iHandbookId = ac.iHandbookId
					WHERE d.iLatestApproved = 0 and d.iLatestVersion = 1 and d.iDraft = 0 
					and d.iApproved = 0 and d.dtmCreated < @DateTo)
	
		SELECT @Archived = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					JOIN @AvailableChildren ac
						ON d.iHandbookId = ac.iHandbookId
					WHERE d.iLatestApproved = 0 and d.iLatestVersion = 1 and d.iDraft = 0 
					and d.iApproved = 4 and d.dtmApproved < @DateTo)
	
		SELECT @NewCount = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					JOIN @AvailableChildren ac
						ON d.iHandbookId = ac.iHandbookId
					WHERE d.iLatestApproved = 1 and d.iVersion = 0 and d.dtmPublish >= @DateFrom and 
					d.dtmPublish < @DateTo)
		
		SELECT @NewAndUpdatedCount = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					JOIN @AvailableChildren ac
						ON d.iHandbookId = ac.iHandbookId
					WHERE d.iLatestApproved = 1 and d.dtmPublish >= @DateFrom and 
					d.dtmPublish < @DateTo)			
	
	
		SELECT @Revised = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					JOIN @AvailableChildren ac
						ON d.iHandbookId = ac.iHandbookId
					WHERE d.iLatestApproved = 1 and d.iVersion > 0 and d.dtmPublish >= @DateFrom and 
					d.dtmPublish < @DateTo)	
	
		SELECT @Internet = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					JOIN @AvailableChildren ac
						ON d.iHandbookId = ac.iHandbookId
					WHERE d.iLatestApproved = 1 and d.iInternetDoc = 1 and d.dtmPublish < @DateFrom)
				
		UPDATE @resultTable 
		SET Approved = @Approved, Folders = @Folders , Expired = @Expired,
		AwaitingApproval = @AwaitingApproval, Revised = @Revised, Archived = @Archived,
		NewCount = @NewCount, NewAndUpdatedCount = @NewAndUpdatedCount, Internet = @Internet
		WHERE iHandbookId = @HandbookId;
	FETCH NEXT FROM curHandbookId INTO @HandbookId
	END
		CLOSE curHandbookId
		DEALLOCATE curHandbookId
    
	SELECT strName AS FolderName, iLevelType AS LevelType, Approved, 
	Expired, NewAndUpdatedCount, NewCount , Revised ,AwaitingApproval, 
	Archived, Internet , Folders 
	FROM @resultTable

END
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

	DECLARE @DateFrom DATETIME 
	SET @DateFrom = (SELECT dtmCreated FROM m136_tblHandbook WHERE iHandbookID = @HandbookId) 
	SET @DateFrom = (SELECT DATEADD(dd, DATEDIFF(dd, 0, @DateFrom), 0))
	SET @DateFrom = (SELECT DATEADD(MONTH, DATEDIFF(MONTH, 0, @DateFrom), 0))
		
	DECLARE @monthintervall INT
	set @monthintervall = (SELECT DATEDIFF(MONTH, @DateFrom,GETDATE()))

	DECLARE @I INT
	SET @I = 0
	
	WHILE @I <= @monthintervall
	BEGIN
		INSERT INTO @resultTable(period)
		VALUES(@DateFrom)

		SET @DateFrom = DATEADD(MONTH,1,@DateFrom)
		SET @I = @I + 1
	END

	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	
	DELETE FROM @AvailableChildren
	
	INSERT INTO @AvailableChildren(iHandbookId)
	SELECT 
		iHandbookId 
	FROM 
		[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1);

   	DECLARE @Approved INT	
   	DECLARE @Period DATETIME

	DECLARE curPeriod CURSOR FOR
	SELECT period FROM @resultTable

	OPEN curPeriod
	FETCH NEXT FROM curPeriod INTO @Period
	WHILE @@FETCH_STATUS =0
	BEGIN
	
		SELECT @Approved = (SELECT Count(DISTINCT iDocumentId) 
				FROM m136_tblDocument d
					JOIN @AvailableChildren ac
						ON d.iHandbookId = ac.iHandbookId
					WHERE d.iApproved = 1 and d.dtmPublish < @Period)
			
				
		UPDATE @resultTable 
		SET Approved = @Approved
		WHERE period = @Period;
	FETCH NEXT FROM curPeriod INTO @Period
	END

	CLOSE curPeriod
	DEALLOCATE curPeriod
    
	SELECT period AS Date, Approved
	FROM @resultTable

END
GO

IF OBJECT_ID('[dbo].[m136_spReportHandbookOverview]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_spReportHandbookOverview] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_spReportHandbookOverview]
	@SecurityId AS INT	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @resultTable TABLE(iHandbookId INT, strName NVARCHAR(200), iLevelType INT, 
	   Approved INT, Expired INT, NewCount INT, NewAndUpdatedCount INT, Revised INT, AwaitingApproval INT, Archived INT,
	   Internet INT, Folders INT)
   
	INSERT INTO @resultTable (iHandbookId ,strName, iLevelType ) 
	VALUES (0,'eHåndbok',0)

	DECLARE @Approved INT
	DECLARE @Expired INT
	DECLARE @NewCount INT
	DECLARE @NewAndUpdatedCount INT
	DECLARE @Revised INT
	DECLARE @AwaitingApproval INT
	DECLARE @Archived INT
	DECLARE @Folders INT	
	DECLARE @Internet INT

	DECLARE @DateFrom DATETIME
	DECLARE @DateTo DATETIME

	SET @DateFrom = DATEADD(YEAR, DATEDIFF(YEAR, 0, GETDATE()), 0)
	SET @DateTo = GETDATE()
	
		
		SELECT @Folders = (SELECT COUNT(*) FROM m136_tblHandbook WHERE iDeleted = 0) 
		
		SELECT @Approved = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					WHERE d.iLatestApproved = 1 and d.dtmPublish < @DateTo)
				
		SELECT @Expired = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					WHERE d.iLatestApproved = 1 and d.dtmPublishUntil < @DateTo)
				
		SELECT @AwaitingApproval = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					WHERE d.iLatestApproved = 0 and d.iLatestVersion = 1 and d.iDraft = 0 
					and d.iApproved = 0 and d.dtmCreated < @DateTo)
	
		SELECT @Archived = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					WHERE d.iLatestApproved = 0 and d.iLatestVersion = 1 and d.iDraft = 0 
					and d.iApproved = 4 and d.dtmApproved < @DateTo)
	
		SELECT @NewCount = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					WHERE d.iLatestApproved = 1 and d.iVersion = 0 and d.dtmPublish >= @DateFrom and 
					d.dtmPublish < @DateTo)
		
		SELECT @NewAndUpdatedCount = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					WHERE d.iLatestApproved = 1 and d.dtmPublish >= @DateFrom and 
					d.dtmPublish < @DateTo)			
	
	
		SELECT @Revised = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					WHERE d.iLatestApproved = 1 and d.iVersion > 0 and d.dtmPublish >= @DateFrom and 
					d.dtmPublish < @DateTo)	
	
		select @Internet = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					WHERE d.iLatestApproved = 1 and d.iInternetDoc = 1 and d.dtmPublish < @DateFrom)
				
		UPDATE @resultTable 
		SET Approved = @Approved, Folders = @Folders , Expired = @Expired,
		AwaitingApproval = @AwaitingApproval, Revised = @Revised, Archived = @Archived,
		NewCount = @NewCount, NewAndUpdatedCount = @NewAndUpdatedCount, Internet = @Internet
		WHERE iHandbookId = 0;
	
    
	SELECT strName AS FolderName, iLevelType AS LevelType, Approved, 
	Expired, NewAndUpdatedCount, NewCount , Revised ,AwaitingApproval, 
	Archived, Internet , Folders 
	FROM @resultTable

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

	DECLARE @DateFrom DATETIME
	SET @DateFrom = (SELECT TOP 1 dtmCreated FROM m136_tblHandbook WHERE ideleted = 0 ORDER BY ihandbookid) 
	SET @DateFrom = (SELECT DATEADD(dd, DATEDIFF(dd, 0, @DateFrom), 0))
	SET @DateFrom = (SELECT DATEADD(MONTH, DATEDIFF(MONTH, 0, @DateFrom), 0))
		
	DECLARE @monthintervall INT
	SET @monthintervall = (SELECT DATEDIFF(MONTH, @DateFrom,GETDATE()))

	DECLARE @I INT
	SET @I = 0
	
	WHILE @I <= @monthintervall
	BEGIN
		INSERT INTO @resultTable(period)
		VALUES(@DateFrom)

		SET @DateFrom = DATEADD(MONTH,1,@DateFrom)
		SET @I = @I + 1
	END

   	DECLARE @Approved INT	
   	DECLARE @Period DATETIME

	DECLARE curPeriod CURSOR FOR
	SELECT period FROM @resultTable

	OPEN curPeriod
	FETCH NEXT FROM curPeriod INTO @Period
	WHILE @@FETCH_STATUS =0
	BEGIN	
	
		SELECT @Approved = (SELECT COUNT(DISTINCT iDocumentId) 
				FROM m136_tblDocument d
					WHERE d.iApproved = 1 and d.dtmPublish < @Period)
			
				
		UPDATE @resultTable 
		SET Approved = @Approved
		WHERE period = @Period;
	FETCH NEXT FROM curPeriod INTO @Period
	END

	CLOSE curPeriod
	DEALLOCATE curPeriod
    
	SELECT period AS Date, Approved
	FROM @resultTable

END
GO
