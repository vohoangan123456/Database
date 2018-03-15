INSERT INTO #Description VALUES ('Remove time part')
GO

IF OBJECT_ID('[dbo].[m136_ProcessLatestApprovedDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_ProcessLatestApprovedDocuments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_ProcessLatestApprovedDocuments]
AS
BEGIN
	DECLARE @iDocumentId INT;
	DECLARE Documents CURSOR FOR 
		SELECT d.iDocumentId FROM dbo.m136_tblDocument d 
			WHERE d.iDeleted = 0 AND d.dtmPublish >= CONVERT(date, GETDATE(), 101) AND d.iApproved = 1;
	OPEN Documents; 
	FETCH NEXT FROM Documents INTO @iDocumentId;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		EXEC [dbo].[m136_SetVersionFlags] @iDocumentId;
		FETCH NEXT FROM Documents INTO @iDocumentId;
	END
	CLOSE Documents;
	DEALLOCATE Documents;
END
GO