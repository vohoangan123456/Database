INSERT INTO #Description VALUES('update SP [dbo].[m136_spReportFolderDocumentStatistics]')
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
	
	INSERT INTO @AvailableChildren(iHandbookId)
	SELECT 
		iHandbookId 
	FROM 
		[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1);
	
	UPDATE rt SET rt.Approved = 
			(SELECT Count(DISTINCT iDocumentId) AS Approved  
			  FROM m136_tblDocument d 
			  JOIN @AvailableChildren ac ON d.iHandbookId = ac.iHandbookId 
			  WHERE d.iApproved = 1 AND d.dtmPublish < rt.period) 
			  FROM @resultTable rt
			  
	SELECT period AS Date, Approved
	FROM @resultTable
END
GO