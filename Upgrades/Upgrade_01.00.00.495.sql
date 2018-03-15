INSERT INTO #Description VALUES ('Update SP [dbo].[m136_spReportFolderDocumentStatistics]')
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

	DECLARE @Archived TABLE(iDocumentid INT NOT NULL PRIMARY KEY, dtmYear int);
	INSERT INTO @Archived(iDocumentid, dtmYear)
	SELECT iDocumentId, YEAR(d.dtmApproved) 
				FROM m136_tblDocument d
				JOIN dbo. m136_ArchivedDocuments a ON a.DocumentId = d.iDocumentId AND d.iLatestApproved = 0 and d.iLatestVersion = 1
				WHERE d.iLatestApproved = 0 and d.iLatestVersion = 1 and d.iDraft = 0 
					and d.iApproved = 4 
					 AND a.HandbookId IN (SELECT iHandbookId FROM @AvailableChildren)
		
	--reopened archived
	DECLARE @ReopenedArchived TABLE(iDocumentid INT NOT NULL PRIMARY KEY);
	INSERT INTO @ReopenedArchived(iDocumentid)
	select iDocumentId from m136_tblDocument d
		where iLatestVersion = 1 and iLatestApproved = 0 and ideleted = 0 and iHandbookId != -1 and iDraft = 1 and
		idocumentid in (select idocumentid from m136_tblDocument where iHandbookId != -1 and iApproved = 4)
		and iDocumentId not in (select iDocumentId from m136_tblDocument where iLatestApproved = 1)


	UPDATE rt SET rt.Approved = 
			(SELECT Count(DISTINCT iDocumentId) AS Approved  
			  FROM m136_tblDocument d 
			  JOIN @AvailableChildren ac ON d.iHandbookId = ac.iHandbookId 
			  WHERE d.iDeleted = 0 and d.iApproved = 1 
			  AND YEAR(d.dtmPublish) <= YEAR(rt.period) AND d.dtmPublish < GETDATE()
			  AND d.iDocumentId not in (select iDocumentId from @Archived where dtmYear <= YEAR(rt.period))
			  AND d.iDocumentId not in (select iDocumentId from @ReopenedArchived)
			  ) 
			  FROM @resultTable1 rt
	SELECT period AS Date, Approved
	FROM @resultTable1
	ORDER BY period
END
GO
