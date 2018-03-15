INSERT INTO #Description VALUES ('Modify SP for report statistic')
GO

IF EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[DocumentNameAndDescriptionReversal]'))
	DROP TRIGGER [dbo].[DocumentNameAndDescriptionReversal]
GO

CREATE TRIGGER [dbo].[DocumentNameAndDescriptionReversal]
   ON  [dbo].[m136_tblDocument]
   AFTER UPDATE, INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for trigger here
	IF UPDATE (strName) 
    begin
        UPDATE [dbo].[m136_tblDocument] 
        SET strNameReversed = REVERSE(D.strName)
        FROM [dbo].[m136_tblDocument] D JOIN inserted I ON D.iEntityId = I.iEntityId
        
        UPDATE [dbo].[m136_tblDocument] 
        SET TitleAndKeyword = D.strName + CASE WHEN D.KeyWords IS NOT NULL THEN ' ' + REPLACE(D.KeyWords, ';', ' ') ELSE '' END
        FROM [dbo].[m136_tblDocument] D JOIN inserted I ON D.iEntityId = I.iEntityId
        
    end 
    IF UPDATE (strDescription) 
    begin
        UPDATE [dbo].[m136_tblDocument] 
        SET strDescriptionReversed = REVERSE(D.strDescription)
        FROM [dbo].[m136_tblDocument] D JOIN inserted I ON D.iEntityId = I.iEntityId
    end 
    
    IF UPDATE (TitleAndKeyword) 
    begin
        UPDATE [dbo].[m136_tblDocument] 
        SET TitleAndKeywordReversed = REVERSE(D.TitleAndKeyword)
        FROM [dbo].[m136_tblDocument] D JOIN inserted I ON D.iEntityId = I.iEntityId
    end 
END
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
					WHERE d.iLatestApproved = 1 and d.dtmPublish < @DateTo AND d.iDeleted = 0)
				
		SELECT @Expired = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					JOIN @AvailableChildren ac
						ON d.iHandbookId = ac.iHandbookId
					WHERE d.iLatestApproved = 1 and d.dtmPublishUntil < @DateTo  AND d.iDeleted = 0)
				
		SELECT @AwaitingApproval = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					JOIN @AvailableChildren ac
						ON d.iHandbookId = ac.iHandbookId
					WHERE d.iLatestApproved = 0 and d.iLatestVersion = 1 and d.iDraft = 0 
					and d.iApproved = 0 and d.dtmCreated < @DateTo  AND d.iDeleted = 0)
	
		SELECT @Archived = (SELECT COUNT(*) 
				FROM m136_tblDocument d
				JOIN dbo. m136_ArchivedDocuments a ON a.DocumentId = d.iDocumentId AND d.iLatestApproved = 0 and d.iLatestVersion = 1
				WHERE d.iLatestApproved = 0 and d.iLatestVersion = 1 and d.iDraft = 0 
					and d.iApproved = 4 and d.dtmApproved < @DateTo AND a.HandbookId IN (SELECT iHandbookId FROM @AvailableChildren))
	
		SELECT @NewCount = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					JOIN @AvailableChildren ac
						ON d.iHandbookId = ac.iHandbookId
					WHERE d.iLatestApproved = 1 and d.iVersion = 0 and d.dtmPublish >= @DateFrom and 
					d.dtmPublish < @DateTo AND d.iDeleted = 0)
		
		SELECT @NewAndUpdatedCount = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					JOIN @AvailableChildren ac
						ON d.iHandbookId = ac.iHandbookId
					WHERE d.iLatestApproved = 1 and d.dtmPublish >= @DateFrom and 
					d.dtmPublish < @DateTo AND d.iDeleted = 0)			
	
	
		SELECT @Revised = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					JOIN @AvailableChildren ac
						ON d.iHandbookId = ac.iHandbookId
					WHERE d.iLatestApproved = 1 and d.iVersion > 0 and d.dtmPublish >= @DateFrom and 
					d.dtmPublish < @DateTo AND d.iDeleted = 0)	
	
		SELECT @Internet = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					JOIN @AvailableChildren ac
						ON d.iHandbookId = ac.iHandbookId
					WHERE d.iLatestApproved = 1 and d.iInternetDoc = 1 and d.dtmPublish < @DateFrom AND d.iDeleted = 0)
				
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
					WHERE d.iLatestApproved = 1 and d.dtmPublish < @DateTo and d.iDeleted = 0)
				
		SELECT @Expired = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					WHERE d.iLatestApproved = 1 and d.dtmPublishUntil < @DateTo and d.iDeleted = 0)
				
		SELECT @AwaitingApproval = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					WHERE d.iLatestApproved = 0 and d.iLatestVersion = 1 and d.iDraft = 0 
					and d.iApproved = 0 and d.dtmCreated < @DateTo and d.iDeleted = 0)
	
		SELECT @Archived = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					WHERE d.iLatestApproved = 0 and d.iLatestVersion = 1 and d.iDraft = 0 
					and d.iApproved = 4 and d.dtmApproved < @DateTo and d.iDeleted = 0)
	
		SELECT @NewCount = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					WHERE d.iLatestApproved = 1 and d.iVersion = 0 and d.dtmPublish >= @DateFrom and 
					d.dtmPublish < @DateTo and d.iDeleted = 0)
		
		SELECT @NewAndUpdatedCount = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					WHERE d.iLatestApproved = 1 and d.dtmPublish >= @DateFrom and 
					d.dtmPublish < @DateTo and d.iDeleted = 0)			
	
	
		SELECT @Revised = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					WHERE d.iLatestApproved = 1 and d.iVersion > 0 and d.dtmPublish >= @DateFrom and 
					d.dtmPublish < @DateTo and d.iDeleted = 0)	
	
		select @Internet = (SELECT COUNT(*) 
				FROM m136_tblDocument d
					WHERE d.iLatestApproved = 1 and d.iInternetDoc = 1 and d.dtmPublish < @DateFrom and d.iDeleted = 0)
				
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
					WHERE d.iApproved = 1 and YEAR(d.dtmPublish) <= YEAR(@Period) AND d.dtmPublish < GETDATE()
					AND d.iDeleted = 0 AND d.iLatestApproved = 1)
			
				
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

IF OBJECT_ID('[dbo].[m136_spReportFolderDocumentTypes]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_spReportFolderDocumentTypes] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_spReportFolderDocumentTypes]
	@HandbookId AS INT,
	@SecurityId AS INT	
AS
BEGIN
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	DELETE FROM @AvailableChildren
	
	INSERT INTO @AvailableChildren(iHandbookId)
	SELECT 
		iHandbookId 
	FROM 
		[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1);

	DECLARE @docTypeTable TABLE(DocTypeCount INT,  DocType VARCHAR(100),DocTypeId INT) 
	INSERT INTO @docTypeTable (DocTypeCount ,DocType,DocTypeId) 
		(SELECT COUNT(d.idocumenttypeid) AS Count,
				dt.strName AS DocType, dt.iDocumentTypeId AS DocTypeId
			FROM m136_tblDocument d
			JOIN @AvailableChildren ac ON d.iHandbookId = ac.iHandbookId
			INNER JOIN m136_tblDocumentType dt ON dt.idocumenttypeid = d.idocumenttypeid
				WHERE  d.iLatestApproved = 1 and d.dtmPublish < GETDATE() AND d.iDeleted = 0
		 GROUP BY d.idocumenttypeid, dt.strName, dt.iDocumentTypeId)

	SELECT DocTypeId, DocType, DocTypeCount FROM @docTypeTable		
END
GO

IF OBJECT_ID('[dbo].[m136_spReportHandbookDocumentTypes]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_spReportHandbookDocumentTypes] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_spReportHandbookDocumentTypes]
	@SecurityId AS INT	
AS
BEGIN

	DECLARE @docTypeTable TABLE(DocTypeCount INT,  DocType VARCHAR(100),DocTypeId INT) 
	INSERT INTO @docTypeTable (DocTypeCount ,DocType,DocTypeId) 
		(SELECT COUNT(d.idocumenttypeid) AS Count,
				 dt.strName AS DocType, dt.iDocumentTypeId AS DocTypeId
			FROM m136_tblDocument d
				INNER JOIN m136_tblDocumentType dt on dt.idocumenttypeid = d.idocumenttypeid
			WHERE  d.iLatestApproved = 1 and d.dtmPublish < GETDATE() and d.iDeleted = 0
		GROUP BY d.idocumenttypeid, dt.strName, dt.iDocumentTypeId)

	SELECT DocTypeId, DocType, DocTypeCount FROM @docTypeTable	
	
END
GO