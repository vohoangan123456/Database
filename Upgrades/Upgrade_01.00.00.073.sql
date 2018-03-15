INSERT INTO #Description VALUES('Create procedure [dbo].[m136_ProcessLatestApprovedDocuments] and [dbo].[m136_SetVersionFlags] for updating LatestApproved when dtmPublishDate in the future.')
GO

IF OBJECT_ID('[dbo].[m136_SetVersionFlags]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SetVersionFlags] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SetVersionFlags] 
	-- Add the parameters for the stored procedure here
	@iDocumentId INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @MaxVersion INT
	SET @MaxVersion = 0
	
	--Reset version flags
	UPDATE  m136_tblDocument set iLatestVersion = 0, iLatestApproved  = 0 
		WHERE iDocumentId = @iDocumentId 
	
	--Get entity that should be flagged as latest approved version
	SELECT @MaxVersion = MAX(iVersion)
		FROM m136_tblDocument d 
		WHERE iDeleted = 0 AND iApproved IN (1 ,4) AND iDocumentId = @iDocumentId AND dtmPublish <= GETDATE() 
	
	--set iLatestApproved flag
	UPDATE m136_tblDocument 
	SET
		iLatestApproved = 1 
	WHERE
		iDocumentId = @iDocumentId AND iApproved = 1 AND iVersion = @MaxVersion AND iDeleted = 0 AND dtmPublish <= GETDATE()          
	
	--Get entity that should be flagged as latest version
	SELECT @MaxVersion = MAX(iVersion)
		FROM m136_tblDocument d 
		WHERE iDeleted = 0 AND iDocumentId = @iDocumentId

	--set iLatestVersion flag
	UPDATE  m136_tblDocument 
	SET  
		iLatestVersion = 1 
	WHERE 
		iDocumentId = @iDocumentId AND iVersion = @MaxVersion AND iDeleted = 0	 
END
GO

IF OBJECT_ID('[dbo].[m136_ProcessLatestApprovedDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_ProcessLatestApprovedDocuments] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: March 04, 2015
-- Description:	Process approved documents that has publish date in the future.
-- =============================================
ALTER PROCEDURE [dbo].[m136_ProcessLatestApprovedDocuments]
	
AS
BEGIN
	DECLARE @iDocumentId INT;
	
	DECLARE Documents CURSOR FOR 
		SELECT d.iDocumentId FROM dbo.m136_tblDocument d 
			WHERE d.iDeleted = 0 AND d.dtmPublish >= GETDATE() AND d.iApproved = 1;

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
