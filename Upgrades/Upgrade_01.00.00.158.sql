INSERT INTO #Description VALUES('Modify m136_SetVersionFlags')
GO

IF OBJECT_ID('[dbo].[m136_SetVersionFlags]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_SetVersionFlags]  AS SELECT 1')
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
		WHERE iDocumentId = @iDocumentId
	--set iLatestVersion flag
	UPDATE  m136_tblDocument 
	SET  
		iLatestVersion = 1 
	WHERE 
		iDocumentId = @iDocumentId AND iVersion = @MaxVersion
END